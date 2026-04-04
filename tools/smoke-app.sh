#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

BUNDLE_PATH="$ROOT/.build/Bullpen.app"
APP_EXECUTABLE="BullpenApp"
APP_PATTERN="$BUNDLE_PATH/Contents/MacOS/$APP_EXECUTABLE"

existing_pids="$(pgrep -x "$APP_EXECUTABLE" || true)"

"$ROOT/run.sh" --build-only

launched_fresh=1
if ! open -n -g "$BUNDLE_PATH" >/dev/null 2>&1; then
  launched_fresh=0
  open -g "$BUNDLE_PATH"
fi

launched_pid=""
for _ in {1..30}; do
  current_pids="$(pgrep -x "$APP_EXECUTABLE" || true)"
  while IFS= read -r pid; do
    [[ -z "$pid" ]] && continue
    if ! grep -qx "$pid" <<<"$existing_pids"; then
      launched_pid="$pid"
      break
    fi
  done <<<"$current_pids"

  if [[ -n "$launched_pid" ]]; then
    break
  fi

  if [[ "$launched_fresh" -eq 0 && -n "$current_pids" ]]; then
    echo "BullpenApp launch reused an existing process"
    exit 0
  fi

  sleep 1
done

if [[ -z "$launched_pid" ]]; then
  current_pids="$(pgrep -x "$APP_EXECUTABLE" || true)"
  if [[ -n "$current_pids" ]]; then
    echo "BullpenApp launch reused an existing process"
    exit 0
  fi
  echo "BullpenApp did not launch from $BUNDLE_PATH" >&2
  exit 1
fi

echo "BullpenApp launched with pid $launched_pid"

kill "$launched_pid"
for _ in {1..10}; do
  if ! ps -p "$launched_pid" >/dev/null 2>&1; then
    echo "BullpenApp exited cleanly"
    exit 0
  fi
  sleep 1
done

kill -9 "$launched_pid" >/dev/null 2>&1 || true
echo "BullpenApp required force termination during smoke cleanup" >&2
exit 1
