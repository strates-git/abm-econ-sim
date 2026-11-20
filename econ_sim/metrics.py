from __future__ import annotations

from collections.abc import Mapping
from typing import Any

from .agents import Firm, Household


def compute_metrics(
    households: Mapping[int, Household],
    firms: Mapping[int, Firm],
    tick: int,
) -> dict[str, Any]:
    total_household_money = sum(h.money for h in households.values())
    total_firm_money = sum(f.money for f in firms.values())
    employed = sum(1 for h in households.values() if h.employed)
    employment_rate = employed / len(households) if households else 0.0
    avg_price = sum(f.price for f in firms.values()) / len(firms) if firms else 0.0
    avg_wage = (
        sum(f.wage_offer for f in firms.values()) / len(firms) if firms else 0.0
    )
    total_output = sum(f.production for f in firms.values())
    total_sales = sum(f.sales for f in firms.values())
    total_consumption = sum(h.consumption for h in households.values())
    return {
        "tick": tick,
        "employment_rate": round(employment_rate, 4),
        "avg_price": round(avg_price, 4),
        "avg_wage": round(avg_wage, 4),
        "total_output": round(total_output, 4),
        "total_sales": round(total_sales, 4),
        "total_consumption": round(total_consumption, 4),
        "household_money": round(total_household_money, 4),
        "firm_money": round(total_firm_money, 4),
        "gdp_proxy": round(sum(f.revenue for f in firms.values()), 4),
    }
