#!/bin/bash
# Run one canonical variant of every example and validate the STEP output.
#
#   ./scripts/check-examples.sh            # native tier (default)
#   STEP_NATIVE=0 ./scripts/check-examples.sh   # VM tier
#
# The native tier is far faster for large designs (12, 38), but the first run
# of each example compiles.
set -uo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

# NN|arguments for the first canonical variant (plan §9.6).
CASES=(
  "01|--edge 10"
  "02|--length 20 --width 20 --height 5"
  "03|--name gmlewis --emboss"
  "04|--id 5 --od 15 --thickness 2"
  "05|--rows 1 --cols 1 --height 20"
  "06|--count 1"
  "07|--diameter 5 --text USB"
  "08|--stepCount 3"
  "09|--baseWidth 60 --baseLength 80"
  "10|--sides 6 --holeSides 6"
  "11|--rows 2 --cols 4"
  "12|--nocage --numPairs 2 --wireGap 0.5 --vertTurns 1"
  "13|--length 60 --width 70"
  "14|--length 100"
  "15|--boltDiameter 8 --clearance 0.1"
  "16|--pinDiameter 5 --clearance 0.05"
  "17|--thickness 2 --hingeWidth 15"
  "18|--width 60 --length 80 --height 30"
  "19|--width 85 --length 75"
  "20|--standoffHeight 6"
  "21|--width 54.5 --height 8"
  "22|--rows 2 --cols 2"
  "23|--innerDiameter 8 --panelThickness 2"
  "24|--angle 15 --seatDepth 10"
  "25|--angles 15,22.5,30,45"
  "26|--armLength 250"
  "27|--length 60"
  "28|--phoneThickness 10"
  "29|--width 40 --armLength 80"
  "30|--length 150 --width 50 --height 40"
  "31|--rows 1 --cols 5 --labelPrefix P"
  "32|--baseLength 100 --armHeight 150"
  "33|--bodyLength 45 --bodyWidth 35"
  "34|--length 50 --width 25"
  "35|--railWidth 12 --railHeight 8"
  "36|--petals 12"
  "37|--diameter 25.4 --type cap"
  "38|--numTeeth 12"
)

pass=0
fail=0
for entry in "${CASES[@]}"; do
  nn=${entry%%|*}
  args=${entry#*|}
  read -r -a argv <<< "$args"
  out="/tmp/gos-step-example-${nn}.step"
  if ! ./run-example.sh "$nn" "${argv[@]}" > "$out" 2>"/tmp/gos-step-example-${nn}.err"; then
    echo "FAIL $nn (run)"
    fail=$((fail + 1))
    continue
  fi
  if python3 -I scripts/validate_step.py --no-mesh "$out" > /tmp/gos-step-validate-${nn}.log 2>&1; then
    echo "PASS $nn"
    pass=$((pass + 1))
  else
    echo "FAIL $nn (validation: /tmp/gos-step-validate-${nn}.log)"
    fail=$((fail + 1))
  fi
done

echo "examples: ${pass} passed, ${fail} failed"
[ "$fail" -eq 0 ]
