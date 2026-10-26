#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
gos fmt
gos check .
gos test .
gos fmt --check
gos lint .
