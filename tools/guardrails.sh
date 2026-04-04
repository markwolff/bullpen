#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

MODE="${1:-full}"
ARTIFACT_DIR=".omx/artifacts/visual-regression"
BASELINE_DIR="Tests/Fixtures/VisualBaselines"

mkdir -p "$ARTIFACT_DIR"
chmod +x "$ROOT/tools/compile-scenarios.sh" "$ROOT/tools/guardrails.sh" "$ROOT/tools/smoke-app.sh"

render_case() {
  local scenario="$1"
  local world="$2"
  local seed="$3"
  local output_prefix="$ARTIFACT_DIR/${scenario}--${world}--seed-${seed}"

  swift run BullpenScreenshot "${output_prefix}.png" \
    --scenario "$scenario" \
    --world "$world" \
    --seed "$seed" \
    --manifest "${output_prefix}.json"
}

assert_artifacts_exist() {
  local scenario="$1"
  local world="$2"
  local seed="$3"
  local artifact_prefix="$ARTIFACT_DIR/${scenario}--${world}--seed-${seed}"

  [[ -s "${artifact_prefix}.json" ]] || {
    printf 'Missing manifest for scenario=%s world=%s seed=%s\n' "$scenario" "$world" "$seed" >&2
    exit 1
  }
  [[ -s "${artifact_prefix}.png" ]] || {
    printf 'Missing render for scenario=%s world=%s seed=%s\n' "$scenario" "$world" "$seed" >&2
    exit 1
  }
}

compare_to_baseline() {
  local scenario="$1"
  local world="$2"
  local seed="$3"
  local artifact_prefix="$ARTIFACT_DIR/${scenario}--${world}--seed-${seed}"
  local baseline_prefix="$BASELINE_DIR/${scenario}--${world}--seed-${seed}"

  cmp -s "${artifact_prefix}.json" "${baseline_prefix}.json"
  cmp -s "${artifact_prefix}.png" "${baseline_prefix}.png"
}

"$ROOT/tools/compile-scenarios.sh"

case "$MODE" in
  fast)
    swift build
    swift test --filter ScenarioSnapshotTests
    swift test --filter ScreenshotBootstrapTests
    render_case "baseline-empty-v1" "classicBullpen" "7"
    assert_artifacts_exist "baseline-empty-v1" "classicBullpen" "7"
    compare_to_baseline "baseline-empty-v1" "classicBullpen" "7"
    ;;
  full)
    swift build
    swift test
    swift test --enable-code-coverage

    render_case "baseline-empty-v1" "classicBullpen" "7"
    assert_artifacts_exist "baseline-empty-v1" "classicBullpen" "7"
    compare_to_baseline "baseline-empty-v1" "classicBullpen" "7"

    render_case "busy-mixed-office-v1" "classicBullpen" "42"
    assert_artifacts_exist "busy-mixed-office-v1" "classicBullpen" "42"
    compare_to_baseline "busy-mixed-office-v1" "classicBullpen" "42"

    render_case "busy-mixed-office-v1" "zenStudio" "42"
    assert_artifacts_exist "busy-mixed-office-v1" "zenStudio" "42"
    compare_to_baseline "busy-mixed-office-v1" "zenStudio" "42"

    for seed in 7 19 42 314 1337; do
      render_case "dense-office-stress-v1" "classicBullpen" "$seed" >/dev/null
      assert_artifacts_exist "dense-office-stress-v1" "classicBullpen" "$seed"
    done

    "$ROOT/tools/smoke-app.sh"
    ;;
  *)
    printf 'Usage: %s [fast|full]\n' "$0" >&2
    exit 1
    ;;
esac
