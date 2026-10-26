# gos-step

A high-level 3D modelling DSL and a STEP (ISO 10303-21) parser/serializer in
[Gossamer](https://gossamer.dev), ported from the original project at
`gmlewis/step`.

- Lossless-ish STEP parsing: unknown entities round-trip as `RawEntity`.
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

- `src/entities/` — 142 entity structs, 5 enums, 145 `to_step` impls.
- `src/repository.gos` — `AnyEntity` (131 variants) and `Repository`.
- `src/parse/` — tokenizer, 126 entity parsers, complex instances, headers,
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

Run an example, or validate one canonical variant of every example with the independent reference validator:

```bash
./scripts/check-examples.sh          # one canonical variant per example
STEP_NATIVE=1 ./scripts/check-examples.sh

./run-example.sh 01 --edge 10 > cube.step

# Very large designs (12, 38) are much faster on the native tier:
STEP_NATIVE=1 ./run-example.sh 38 --numTeeth 12 > gearbox.step
```

## License

Apache-2.0. The ported font code and the vendored font keep their original
licenses and attribution.
