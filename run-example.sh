#!/bin/bash
# Run one of the ported examples from the repository root.
#
#   ./run-example.sh NN [args...]      # numeric, zero-padded
#   ./run-example.sh 03-engraved-name-tag [args...]
set -euo pipefail
ROOT=$(cd "$(dirname "$0")" && pwd)

if [ $# -lt 1 ]; then
  echo "usage: $0 NN|name [args...]" >&2
  exit 2
fi

ARG="$1"; shift
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

cd "$ROOT"
# The VM tier is fast to start; huge designs run much faster natively.
if [ "${STEP_NATIVE:-0}" = "1" ]; then
  STEP_ROOT="$ROOT" gos run --native "examples/$EXAMPLE/main.gos" "$@"
else
  STEP_ROOT="$ROOT" gos run "examples/$EXAMPLE/main.gos" "$@"
fi
