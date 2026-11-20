from econ_sim import EconomyModel, SimulationConfig


def test_model_runs_and_records_history():
    model = EconomyModel(SimulationConfig(steps=10, households=20, firms=3, seed=1))
    history = model.run()
    assert len(history) == 10
    assert history[-1]["tick"] == 10


def test_metrics_have_expected_keys():
    model = EconomyModel(SimulationConfig(steps=1, households=10, firms=2, seed=2))
    row = model.step()
    expected = {
        "tick",
        "employment_rate",
        "avg_price",
        "avg_wage",
        "total_output",
        "total_sales",
        "total_consumption",
        "household_money",
        "firm_money",
        "gdp_proxy",
    }
    assert expected.issubset(row.keys())


def test_employment_bounds():
    model = EconomyModel(SimulationConfig(steps=5, households=30, firms=4, seed=3))
    history = model.run()
    for row in history:
        assert 0.0 <= row["employment_rate"] <= 1.0
        assert row["avg_price"] >= 0.0
