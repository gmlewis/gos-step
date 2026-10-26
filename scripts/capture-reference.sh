#!/bin/bash
# Capture reference STEP output from the original project.
# Usage: scripts/capture-reference.sh 01 --edge 10
# Requires REF to point at the original repository.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
REF="${REF:?set REF to the reference repository}"
NN="$1"; shift
NN=$(printf '%02d' "$((10#$NN))")
DIR=$(ls -d "$REF"/examples/"$NN"-* | head -1)
TAG="ref-$NN$(for a in "$@"; do printf '-%s' "$a"; done | tr ' /.' '---' | sed 's/--*/-/g')"
mkdir -p "$ROOT/testdata"
( cd "$REF" && moon run --quiet --target native "$DIR" -- "$@" ) \
  | sed -E "s/(FILE_NAME\('[^']*',')[^']*(')/\1<TIMESTAMP>\2/" \
  > "$ROOT/testdata/${TAG}.step"
echo "wrote $ROOT/testdata/${TAG}.step"
