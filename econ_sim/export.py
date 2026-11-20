from __future__ import annotations

import json
import os
from typing import Any, TYPE_CHECKING

if TYPE_CHECKING:
    from .model import EconomyModel


def build_snapshot(model: "EconomyModel") -> dict[str, Any]:
    """Build an in-memory snapshot of the current state (no disk I/O)."""
    employed = sum(1 for h in model.households.values() if h.employed)
    total_household_money = sum(h.money for h in model.households.values())
    total_firm_money = sum(f.money for f in model.firms.values())
    avg_wage = (
        sum(f.wage_offer for f in model.firms.values()) / len(model.firms)
        if model.firms
        else 0.0
    )

    return {
        "tick": model.tick,
        "metrics": {
            "employment": employed,
            "avg_wage": round(avg_wage, 4),
            "total_wealth": round(total_household_money + total_firm_money, 4),
        },
        "households": [
            {
                "id": h.id,
                "money": h.money,
                "wage": h.wage,
                "employed": h.employed,
                "employer_id": h.employer_id,
                "consumption": h.consumption,
                "x": h.x,
                "y": h.y,
                "z": h.z,
            }
            for h in model.households.values()
        ],
        "firms": [
            {
                "id": f.id,
                "money": f.money,
                "price": f.price,
                "wage_offer": f.wage_offer,
                "inventory": f.inventory,
                "production": f.production,
                "sales": f.sales,
                "revenue": f.revenue,
                "employees": list(f.employees),
                "x": f.x,
                "y": f.y,
                "z": f.z,
            }
            for f in model.firms.values()
        ],
    }


def write_snapshot(ticks: list[dict[str, Any]], directory: str) -> None:
    """Write all buffered per-tick snapshots to disk in a single operation."""
    os.makedirs(directory, exist_ok=True)
    path = os.path.join(directory, "snapshot.json")
    with open(path, "w") as handle:
        json.dump({"ticks": ticks}, handle, indent=2)
