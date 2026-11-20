from __future__ import annotations

import argparse

from econ_sim import EconomyModel, SimulationConfig


def main() -> None:
    parser = argparse.ArgumentParser(description="Run simplified ABM economic simulator")
    parser.add_argument("--steps", type=int, default=50)
    parser.add_argument("--households", type=int, default=40)
    parser.add_argument("--firms", type=int, default=4)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--export-dir", type=str, default=None, help="directory to write per-tick state_XXXX.json files for Godot visualization")
    args = parser.parse_args()

    model = EconomyModel(
        SimulationConfig(
            steps=args.steps,
            households=args.households,
            firms=args.firms,
            seed=args.seed,
            export_dir=args.export_dir,
        )
    )
    history = model.run()

    print("tick  employ  avg_price  avg_wage  output  sales  gdp")
    for row in history[-10:]:
        print(
            f"{row['tick']:>4}  "
            f"{row['employment_rate']:>6.2%}  "
            f"{row['avg_price']:>9.2f}  "
            f"{row['avg_wage']:>8.2f}  "
            f"{row['total_output']:>6.1f}  "
            f"{row['total_sales']:>5.1f}  "
            f"{row['gdp_proxy']:>7.1f}"
        )

    final = history[-1] if history else {}
    print("\nFinal metrics:")
    for k in [
        "employment_rate",
        "avg_price",
        "avg_wage",
        "total_output",
        "total_sales",
        "gdp_proxy",
        "household_money",
        "firm_money",
    ]:
        if k in final:
            print(f"  {k}: {final[k]}")


if __name__ == "__main__":
    main()
