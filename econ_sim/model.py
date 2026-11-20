from __future__ import annotations

from dataclasses import dataclass
import random
from typing import Any

from .agents import Firm, Household
from .export import build_snapshot, write_snapshot
from .metrics import compute_metrics


@dataclass
class SimulationConfig:
    steps: int = 50
    households: int = 40
    firms: int = 4
    seed: int | None = 42
    initial_household_money: float = 100.0
    initial_firm_money: float = 500.0
    initial_price: float = 10.0
    initial_wage: float = 20.0
    productivity: float = 5.0
    propensity_to_consume: float = 0.6
    export_dir: str | None = None


class EconomyModel:
    def __init__(self, config: SimulationConfig | None = None):
        self.config = config or SimulationConfig()
        self.rng = random.Random(self.config.seed)
        self.tick = 0
        self.history: list[dict[str, Any]] = []
        self._export_buffer: list[dict[str, Any]] = []

        self.households: dict[int, Household] = {
            i: Household(id=i, money=self.config.initial_household_money)
            for i in range(self.config.households)
        }
        self.firms: dict[int, Firm] = {
            i: Firm(
                id=i,
                money=self.config.initial_firm_money,
                price=self.config.initial_price * self.rng.uniform(0.9, 1.1),
                wage_offer=self.config.initial_wage * self.rng.uniform(0.9, 1.1),
                desired_workers=max(1, self.config.households // max(1, self.config.firms)),
            )
            for i in range(self.config.firms)
        }

        self._assign_labor()
        self._place_agents()

    def _assign_labor(self) -> None:
        for h in self.households.values():
            h.employed = False
            h.employer_id = None
            h.wage = 0.0
        for f in self.firms.values():
            f.employees.clear()

        household_ids = list(self.households.keys())
        self.rng.shuffle(household_ids)

        openings: list[int] = []
        for f in self.firms.values():
            openings.extend([f.id] * f.desired_workers)
        self.rng.shuffle(openings)

        for hid, fid in zip(household_ids, openings):
            firm = self.firms[fid]
            firm.employees.append(hid)
            hh = self.households[hid]
            hh.employed = True
            hh.employer_id = fid

    def _place_agents(self) -> None:
        spread = 40.0
        height = 0.0
        for h in self.households.values():
            h.x = self.rng.uniform(-spread, spread)
            h.y = height
            h.z = self.rng.uniform(-spread, spread)
        for f in self.firms.values():
            f.x = self.rng.uniform(-spread, spread)
            f.y = height
            f.z = self.rng.uniform(-spread, spread)

    def _goods_market(self) -> dict[int, float]:
        demands: dict[int, float] = {fid: 0.0 for fid in self.firms}
        firms = list(self.firms.values())
        if not firms:
            return demands

        # Price-competitive market shares: cheaper firms attract more customers,
        # but demand is spread across all firms instead of all going to the single
        # cheapest one (which previously starved the rest into shedding workers).
        weights = [1.0 / max(f.price, 1e-9) for f in firms]
        total_weight = sum(weights)
        cumulative: list[float] = []
        running = 0.0
        for w in weights:
            running += w / total_weight
            cumulative.append(running)

        for h in self.households.values():
            r = self.rng.random()
            idx = 0
            while idx < len(cumulative) - 1 and r > cumulative[idx]:
                idx += 1
            firm = firms[idx]
            desired = h.plan_consumption(self.config.propensity_to_consume, firm.price)
            demands[firm.id] += desired
            affordable = min(desired, h.money / firm.price if firm.price > 0 else 0.0)
            sold = firm.sell(affordable)
            spend = sold * firm.price
            h.spend(spend)
            h.consumption = sold
        return demands

    def step(self) -> dict[str, Any]:
        self.tick += 1
        self._assign_labor()

        for f in self.firms.values():
            f.reset_tick()
            f.produce(self.config.productivity)

        demands = self._goods_market()

        # pay wages after revenue so firms can use sales; allow temporary deficit handled by floor
        for f in self.firms.values():
            f.pay_wages(self.households)

        for f in self.firms.values():
            f.adjust(
                demands.get(f.id, 0.0),
                self.config.initial_wage,
                self.config.productivity,
            )

        metrics = compute_metrics(self.households, self.firms, self.tick)
        self.history.append(metrics)
        if self.config.export_dir:
            self._export_buffer.append(build_snapshot(self))
        return metrics

    def run(self, steps: int | None = None) -> list[dict[str, Any]]:
        n = steps if steps is not None else self.config.steps
        if self.config.export_dir:
            self._export_buffer.clear()
        for _ in range(n):
            self.step()
        if self.config.export_dir:
            write_snapshot(self._export_buffer, self.config.export_dir)
        return self.history
