#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="${1:-$ROOT_DIR/Tests/Fixtures/Scenarios}"

mkdir -p "$OUTPUT_DIR"

cd "$ROOT_DIR"
swift run BullpenScenarioCompiler --output-dir "$OUTPUT_DIR"
