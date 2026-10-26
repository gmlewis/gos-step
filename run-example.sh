#!/bin/bash
# Run one of the ported examples from the repository root.
#
#   ./run-example.sh NN [args...]      # numeric, zero-padded
#   ./run-example.sh 03-engraved-name-tag [args...]
#
# The native tier is the default (STEP_NATIVE=0 selects the VM).
#
# Add -stl to tessellate the generated STEP file into an STL with OCCT:
#
#   ./run-example.sh 01 -o cube.step -stl     # writes cube.step and cube.stl
#   ./run-example.sh 01 -stl=my-cube.stl      # names the STL explicitly
#
# STL_DEFLECTION=<mm> sets the tessellation tolerance (default 0.05).
set -euo pipefail
ROOT=$(cd "$(dirname "$0")" && pwd)

if [ $# -lt 1 ]; then
  echo "usage: $0 NN|name [args...]" >&2
  exit 2
fi

ARG="$1"; shift

# Users sometimes include an extra "--" out of habit.
if [ $# -gt 0 ] && [ "${1:-}" = "--" ]; then
  shift
fi

EXAMPLE=""
case "$ARG" in
  */*) EXAMPLE=$(basename "$ARG") ;;
  *)
    if [[ "$ARG" =~ ^[0-9]+$ ]]; then
      NN=$(printf '%02d' "$((10#$ARG))")
      for d in "$ROOT"/examples/"$NN"-*; do
        [ -d "$d" ] && EXAMPLE=$(basename "$d") && break
      done
    else
      for d in "$ROOT"/examples/*"$ARG"*; do
        [ -d "$d" ] && EXAMPLE=$(basename "$d") && break
      done
    fi
    ;;
esac

if [ -z "$EXAMPLE" ] || [ ! -f "$ROOT/examples/$EXAMPLE/main.gos" ]; then
  echo "error: unknown example '$ARG'" >&2
  exit 1
fi

# Run from the repository root so examples find their assets. Relative output
# paths (via -o or -stl) resolve against this directory.
cd "$ROOT"

# --- Forwarded arguments ----------------------------------------------------
# `-stl` is handled by this wrapper; every other argument is forwarded to the
# example. `-o`/`--out` is picked out only to locate the generated STEP file.
STL_REQUESTED=0
STL_OUT_ARG=""
STL_OUT=""
STEP_OUT=""
NO_STEP_OUTPUT=0
FORWARD_ARGS=()
ARGS=("$@")
i=0
while (( i < ${#ARGS[@]} )); do
  arg="${ARGS[$i]}"
  case "$arg" in
    -stl | --stl)
      STL_REQUESTED=1
      ;;
    -stl=* | --stl=*)
      STL_REQUESTED=1
      STL_OUT_ARG="${arg#*=}"
      ;;
    -o | --out)
      FORWARD_ARGS+=("$arg")
      if (( i + 1 < ${#ARGS[@]} )); then
        STEP_OUT="${ARGS[$((i + 1))]}"
        FORWARD_ARGS+=("$STEP_OUT")
        i=$((i + 1))
      fi
      ;;
    -o=* | --out=*)
      STEP_OUT="${arg#*=}"
      FORWARD_ARGS+=("$arg")
      ;;
    --blend | --blend=* | --bpy | --bpy=* | --nostep)
      # These options make the example skip STEP output entirely.
      NO_STEP_OUTPUT=1
      FORWARD_ARGS+=("$arg")
      ;;
    *)
      FORWARD_ARGS+=("$arg")
      ;;
  esac
  i=$((i + 1))
done

if (( STL_REQUESTED )); then
  if (( NO_STEP_OUTPUT )); then
    echo "error: -stl cannot be combined with --blend, --bpy, or --nostep" >&2
    echo "       because those options suppress the STEP output." >&2
    exit 1
  fi

  if [ -n "$STL_OUT_ARG" ]; then
    STL_OUT="$STL_OUT_ARG"
  elif [ -n "$STEP_OUT" ]; then
    step_dir=$(dirname "$STEP_OUT")
    step_base=$(basename "$STEP_OUT")
    case "$step_base" in
      *.*) step_base="${step_base%.*}" ;;
    esac
    STL_OUT="$step_dir/$step_base.stl"
  else
    STL_OUT="$EXAMPLE.stl"
  fi

  if [ ! -d "$(dirname "$STL_OUT")" ]; then
    echo "error: STL output directory does not exist: $(dirname "$STL_OUT")" >&2
    exit 1
  fi

  # Without -o the example writes STEP to stdout. Capture it in a temporary
  # file so it does not end up in the terminal or mixed with STL output.
  if [ -z "$STEP_OUT" ]; then
    STEP_TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/step-stl.XXXXXX")
    trap 'rm -rf "$STEP_TMP_DIR"' EXIT
    STEP_OUT="$STEP_TMP_DIR/$EXAMPLE.step"
    FORWARD_ARGS+=(-o "$STEP_OUT")
  fi
fi

# --- STEP -> STL ------------------------------------------------------------
# Draw the script on stdin: on macOS OCCT's DRAWEXE initializes its event loop
# from stdin, and `-c` or a script file can fail before that setup completes.
find_occt() {
  local tool
  tool=$(command -v occt-draw 2>/dev/null || true)
  if [ -z "$tool" ]; then
    tool=$(command -v DRAWEXE 2>/dev/null || true)
  fi
  printf '%s' "$tool"
}

# Quote a string for a TCL command.
tcl_quote() {
  local s="${1//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '"%s"' "$s"
}

step_to_stl() {
  local step_path="$1"
  local stl_path="$2"
  local deflection="${STL_DEFLECTION:-0.05}"
  local occt log

  occt=$(find_occt)
  if [ -z "$occt" ]; then
    echo "error: neither occt-draw nor DRAWEXE is on PATH." >&2
    echo "       Install OpenCASCADE to use -stl." >&2
    return 1
  fi

  if ! log=$(
    printf 'pload ALL\ntestreadstep %s a\nincmesh a %s\nwritestl a %s\nexit\n' \
      "$(tcl_quote "$step_path")" "$deflection" "$(tcl_quote "$stl_path")" \
      | "$occt" 2>&1
  ); then
    echo "error: OCCT failed while converting $step_path to STL." >&2
    printf '%s\n' "$log" | tail -n 5 >&2
    return 1
  fi
  if [ ! -s "$stl_path" ]; then
    echo "error: OCCT produced no STL for $step_path." >&2
    printf '%s\n' "$log" | tail -n 5 >&2
    return 1
  fi
}

# Native is the default tier. Set STEP_NATIVE=0 to run on the VM instead.
if (( ${#FORWARD_ARGS[@]} )); then
  if [ "${STEP_NATIVE:-1}" = "0" ]; then
    STEP_ROOT="$ROOT" gos run "examples/$EXAMPLE/main.gos" "${FORWARD_ARGS[@]}"
  else
    STEP_ROOT="$ROOT" gos run --native "examples/$EXAMPLE/main.gos" "${FORWARD_ARGS[@]}"
  fi
else
  if [ "${STEP_NATIVE:-1}" = "0" ]; then
    STEP_ROOT="$ROOT" gos run "examples/$EXAMPLE/main.gos"
  else
    STEP_ROOT="$ROOT" gos run --native "examples/$EXAMPLE/main.gos"
  fi
fi

if (( STL_REQUESTED )); then
  step_to_stl "$STEP_OUT" "$STL_OUT"
  triangles=$(od -An -tu4 -j80 -N4 "$STL_OUT" 2>/dev/null | tr -d ' ') || triangles=""
  if [[ "$triangles" =~ ^[0-9]+$ ]]; then
    echo "Wrote $STL_OUT ($triangles triangles)" >&2
  else
    echo "Wrote $STL_OUT" >&2
  fi
fi
