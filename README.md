# ABM Economic Simulator

A simplified agent-based economic simulator in Python (standard library only).

## Model

- **Households**: supply labor, earn wages, hold cash, and consume goods each tick.
- **Firms**: hire workers, produce goods, set prices via a simple markup/adjustment rule, pay wages, and track profits/inventory.
- **Market**: labor and goods exchange happen each tick with simple demand/supply matching and price adjustment.

## Project layout

- `econ_sim/agents.py` – household and firm agents
- `econ_sim/model.py` – simulation model and step logic
- `econ_sim/metrics.py` – aggregate metrics helpers
- `run.py` – example simulation run
- `tests/` – basic tests

## Requirements

- Python 3.10+
- No third-party runtime dependencies

## Run

```bash
python run.py
```

Optional arguments:

```bash
python run.py --steps 100 --households 50 --firms 5 --seed 42 --export-dir .
```

## 3D Visualization (Godot)

A Godot 4.7 project lives under `godot/`. It reads a single accumulated `snapshot.json` (written by the Python simulation) and animates households as green/gray spheres and firms as colored cubes positioned by their simulated coordinates.

1. Run the sim with export enabled (appends each tick to `snapshot.json` in the export directory):
   ```bash
   python run.py --steps 500 --households 40 --firms 4 --seed 42 --export-dir ./viz
   ```
2. Open `godot/` in Godot 4.x and press Play. The visualizer loads `../snapshot.json`, then plays through the ticks automatically at ~20 fps, looping when it reaches the end.

The visualizer reads from `../snapshot.json`, so run the sim from the project root with `--export-dir .` to write the file next to the `godot/` folder.

**Controls:**
- **Pause/Play** button (top-left) toggles tick playback.
- **Click** any sphere (household) or cube (firm) to inspect its individual parameters in the panel at the top-right.
- **Graphs** (bottom) plot total employment, average wage, and total wealth across the run, with a vertical marker showing the current tick.

## Test

```bash
python -m pytest -q
```

(If `pytest` is not installed, install dev deps first: `pip install -e .[dev]`.)
