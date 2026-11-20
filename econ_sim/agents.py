from __future__ import annotations

from dataclasses import dataclass, field


@dataclass
class Household:
    id: int
    money: float
    wage: float = 0.0
    employer_id: int | None = None
    employed: bool = False
    consumption: float = 0.0
    x: float = 0.0
    y: float = 0.0
    z: float = 0.0

    def receive_wage(self) -> None:
        if self.employed:
            self.money += self.wage

    def plan_consumption(self, propensity: float, price: float) -> float:
        """Desired goods quantity given propensity to consume and current price."""
        if price <= 0:
            return 0.0
        budget = max(0.0, self.money * propensity)
        return budget / price

    def spend(self, amount: float) -> None:
        self.money = max(0.0, self.money - amount)


@dataclass
class Firm:
    id: int
    money: float
    price: float
    wage_offer: float
    inventory: float = 0.0
    production: float = 0.0
    employees: list[int] = field(default_factory=list)
    desired_workers: int = 1
    sales: float = 0.0
    revenue: float = 0.0
    x: float = 0.0
    y: float = 0.0
    z: float = 0.0

    @property
    def labor_cost(self) -> float:
        return self.wage_offer * len(self.employees)

    def produce(self, productivity: float) -> None:
        self.production = productivity * len(self.employees)
        self.inventory += self.production

    def sell(self, quantity: float) -> float:
        sold = min(self.inventory, max(0.0, quantity))
        self.inventory -= sold
        self.sales += sold
        revenue = sold * self.price
        self.revenue += revenue
        self.money += revenue
        return sold

    def pay_wages(self, households: dict[int, Household]) -> None:
        total_owed = self.labor_cost
        if total_owed <= 0.0:
            return
        available = max(0.0, self.money)
        paid_ratio = min(1.0, available / total_owed)
        for hid in self.employees:
            hh = households[hid]
            hh.wage = self.wage_offer
            hh.money += self.wage_offer * paid_ratio
        self.money = max(0.0, available - total_owed)

    def adjust(
        self,
        demand: float,
        base_wage: float,
        productivity: float,
        min_price: float = 0.5,
        markup: float = 1.0,
    ) -> None:
        """Adaptive hiring, wage, and pricing rules.

        Price is anchored to unit labor cost (wage / productivity) times a markup,
        then nudged by demand pressure, so it neither runs away nor deflates.
        Hiring uses a demand-vs-capacity rule with hysteresis to avoid churn.
        """
        capacity = self.production

        if demand > capacity + 1e-9:
            self.desired_workers = min(self.desired_workers + 1, 20)
            self.wage_offer = min(self.wage_offer * 1.01, base_wage * 3)
        elif demand < 0.8 * capacity:
            self.desired_workers = max(1, self.desired_workers - 1)
            self.wage_offer = max(base_wage * 0.8, self.wage_offer * 0.99)

        unit_cost = self.wage_offer / max(productivity, 1e-9)
        target = unit_cost * markup
        if demand > capacity + 1e-9:
            target *= 1.05
        elif demand < 0.8 * capacity:
            target *= 0.95

        self.price = max(min_price, self.price + 0.15 * (target - self.price))

    def reset_tick(self) -> None:
        self.sales = 0.0
        self.revenue = 0.0
        self.production = 0.0
