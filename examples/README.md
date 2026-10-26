# Examples

All 38 reference examples are ported to single-file
`examples/NN-name/main.gos` programs. Examples share one manifest
(`examples/project.toml`) with a path dependency on the library, so no
per-example manifest is needed. Run them from the repository root:

```bash
./run-example.sh 01 --edge 10 > cube.step
./run-example.sh 04 --id 5 --od 15 --thickness 2 > washer.step
./run-example.sh 38 --numTeeth 12 > gearbox.step

STEP_NATIVE=0 ./run-example.sh 01 --edge 10   # VM tier (native is default)
```

The native tier is the default; the first run compiles the library with LLVM
and later runs reuse the build. The VM starts instantly but is much slower on
large designs.

## Verification

Every example is exercised with its canonical arguments and checked against
the reference:

- 37 examples produce **byte-identical STEP `DATA`** for every canonical
  variant tested, including example 12’s 991,184-line default.
- Example 38’s first variant is byte-identical; its second variant and small
  stress variant retain a handful of last-bit coordinate differences with
  identical topology.
- Every output passes `scripts/validate_step.py --no-mesh` (syntax, references,
  shell topology, edge orientation, plane planarity).
- Examples 01 and 02 also produce `.bpy` output matching the reference line for
  line (except the generated docstring’s producer line).

```bash
./scripts/check-examples.sh          # canonical variant of every example
```
