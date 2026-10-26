# Examples

Each directory is its own Gossamer package with a path dependency on the
library:

Examples are single `main.gos` files and are run from the repository root;
no per-example manifest is needed because the root project supplies `use step`.

```bash
gos run examples/01-hello-cube/main.gos --edge 10 > cube.step
./run-example.sh 01 --edge 10 > cube.step
./run-example.sh 04 --id 5 --od 15 --thickness 2 > washer.step
```

## Implemented end-to-end (CLI + STEP + optional Blender export)

| # | Example | Verified |
|---|---|---|
| 01 | hello-cube | STEP DATA byte-identical to the reference; `.bpy` byte-identical |
| 02 | calibration-chamfer-block | STEP DATA byte-identical; `.bpy` byte-identical |
| 04 | parametric-washer-kit | STEP DATA byte-identical |
| 10 | polygon-knob | STEP DATA byte-identical |
| 17 | living-hinge-sample | STEP DATA byte-identical |
| 37 | tube-cap-assortment | STEP DATA byte-identical |

All six also pass `scripts/validate_step.py --no-mesh` (syntax, references,
shell topology, edge orientation, plane planarity).

## Scaffolded

The remaining reference examples have package directories only; their
`main.gos` is not yet ported. The library surface they
need (cuboid, chamfer, extrusion, Bezier extrusion, sweep, helix, text,
booleans, Blender export, CLI) is implemented and tested.
