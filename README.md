# gos-step

A high-level 3D modelling DSL and a STEP (ISO 10303-21) parser/serializer in
[Gossamer](https://gossamer.dev), ported from the original project at
[github.com/gmlewis/moonbit-step](https://github.com/gmlewis/moonbit-step).

- Semi-lossless STEP parsing: unknown entities round-trip as `RawEntity`.
- Deterministic serialization: parse → serialize → parse is idempotent.
- An intent-based CAD DSL (cuboid, chamfer/fillet block, extrusion, Bezier
  extrusion, sweep, helix) that compiles to topologically-sound B-Rep STEP.
- Font/text support.
- Blender 5.0 Python export.
- A bespoke CLI library with the reference semantics.

## Quick start (modelling)

```gos
use step

fn main() -> Result<(), step::Error> {
    let design = step::design(name: "my-model")
        .add(
            step::cuboid(20.0, 20.0, 20.0)
                .named("base")
                .colored(step::ORANGE),
        )
        .add(
            step::chamfer_block(10.0, 10.0, 5.0, chamfer: 1.0)
                .named("top-part")
                .moved(z: 20.0),
        )

    design |> step::to_step_text |> println
    design |> |d| step::write_step(d, Some("model.step"))
}
```

## Quick start (parsing)

```gos
use step

fn main() -> Result<(), step::Error> {
    let repo = step::read_step("part.step")?
    println(f"entities: {repo.len()}")
    println(step::repository_to_text(repo))
    Ok(())
}
```

## Build and test

```bash
gos check .
gos test .
gos fmt --check .
gos lint .
```

`gos test .` is the reliable form: `gos test src` treats every source file as a
standalone test crate.

## Layout

- `src/entities/` — STEP entity structs, enums, and their `to_step` impls.
- `src/repository.gos` — `AnyEntity` and `Repository`.
- `src/parse/` — tokenizer, entity parsers, complex instances, headers,
  exact parse diagnostics.
- `src/cad/` — intent model, builders, context/dedup, compilers, `Design`,
  Blender export.
- `src/font/` — font loading, SVG paths, layout, flattening.
- `src/cli/` — argument parsing with the reference's semantics.
- `examples/` — one `main.gos` per example, run from the repository root (no
  per-example manifest is needed).
- `assets/fonts/` — vendored font data.
- `testdata/` — STEP fixtures and reference outputs used by the tests.
- `scripts/` — the independent Python validators (syntax/topology/OCCT gate),
  the example sweep, and the reference-capture tool.
- `run-example.sh` — runs one example from the repository root.

Run an example, or validate one canonical variant of every example with the
independent reference validator:

```bash
./run-example.sh 01 --edge 10 > cube.step
./run-example.sh 38 --numTeeth 12 > gearbox.step
./run-example.sh 01 -o cube.step -stl          # also write cube.stl via OCCT
./scripts/check-examples.sh          # one canonical variant per example
STEP_NATIVE=0 ./run-example.sh 01 --edge 10   # VM tier instead of native
```

Add `-stl` to tessellate the generated STEP file into an STL using
OpenCASCADE (needs `occt-draw` or `DRAWEXE` on `PATH`). Use `-stl=<path>` to
name the STL, and `STL_DEFLECTION=<mm>` to set the tessellation tolerance
(default `0.05`).

Examples run on the **native tier by default**. The first run compiles the
library with LLVM (minutes); later runs reuse the build. `STEP_NATIVE=0`
selects the VM, which starts instantly but is far slower on large designs.

## Verification

The port inventory is complete. The suite is green under:

```bash
gos check .
gos test .
gos fmt --check .
gos lint .
```

`gos test .` is the reliable form; `gos test src` treats every source file as a
standalone test crate.

**STEP parity.** Comparing the `DATA;`…`ENDSEC;` blocks byte for byte against the
reference (entity numbering and order included):

- the canonical variants of the examples are byte-identical;
- a large design and its stress variant retain a handful of last-bit coordinate
  differences, with identical topology;
- all fixtures round-trip idempotently;
- the real Baloo font decodes and text compiles to solids;
- Blender `.bpy` output matches the reference line for line, except the generated
  docstring’s producer line.

Every example output passes `scripts/validate_step.py --no-mesh` (envelope,
real-number grammar, reference integrity, shell topology, edge orientation,
plane planarity). OCCT `checkshape` and watertight tessellation require OCCT and
are skipped when it is absent.

**Exact numerics.** `fmt::fmt_num` / `fmt::ref_to_string` reproduce the
reference float formatting (including the 32-bit saturation quirk), and
`cad/refmath` provides fdlibm `tan`, `asin`, `acos`, `atan`, `atan2` verified
bit-for-bit. `sin`/`cos` use `std::math` because the reference
**native** tier calls the platform libm for them, which the host matches
exactly.

**Intentional deviations.** CLI help uses declaration order (the map-based
compatibility API sorts); parse columns count UTF-16 code units; CLI exit codes
are explicit and stable instead of aborting; generated headers name this repository
and the `gossamer` system token; `Args::double` returns `Result<Number,
CliError>` to avoid a native-backend miscompilation of `Result<f64,
aggregate-error>`; and `BooleanOperator`/`TextPath` expose module-local
`*_to_step` helpers because those payload-less variants cannot use cross-module
trait dispatch.

**Performance.** The VM costs more per emitted entity than the native tier.
Face/edge lookup is indexed (`EdgeTable`); a linear scan made large models
quadratic.

## License

Apache-2.0. The ported font code and the vendored font keep their original
licenses and attribution.
