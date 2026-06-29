#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

cd "$TMPDIR"
export COLLAB_STATE_HOME="$TMPDIR/state-home"

RUN_DATE="$(date +%Y-%m-%d)"
TARGET="$RUN_DATE-restore-guards"

"$ROOT/commands/collab/engine/registry.py" init --agent-id codex "Restore Guards" >/dev/null
REGISTRY="$("$ROOT/commands/collab/engine/registry.py" registry-path)"

expect_reject_unchanged() {
  local label="$1"
  shift
  local before="$TMPDIR/before-$label.json"
  cp "$REGISTRY" "$before"
  set +e
  output="$("$@" 2>&1)"
  status=$?
  set -e
  if [[ "$status" -eq 0 || "$output" != *"invalid event index"* ]]; then
    printf 'FAIL: %s did not reject invalid event index\n%s\n' "$label" "$output" >&2
    exit 1
  fi
  if ! cmp -s "$REGISTRY" "$before"; then
    printf 'FAIL: %s mutated registry on invalid event index\n' "$label" >&2
    exit 1
  fi
}

expect_reject_unchanged missing "$ROOT/commands/collab/engine/registry.py" restore "$TARGET" --to 999 --caller-role mod
expect_reject_unchanged noninteger "$ROOT/commands/collab/engine/registry.py" restore "$TARGET" --to revision --caller-role mod
expect_reject_unchanged future "$ROOT/commands/collab/engine/registry.py" restore "$TARGET" --to 999999 --caller-role mod

rm -rf "$(dirname "$REGISTRY")/revisions/$TARGET"
"$ROOT/commands/collab/engine/registry.py" set "$TARGET" description "after-baseline" --caller-role mod >/dev/null
expect_reject_unchanged legacy "$ROOT/commands/collab/engine/registry.py" restore "$TARGET" --to legacy-baseline --caller-role mod

printf 'OK: restore --to rejects missing, non-integer, future, and legacy-baseline selectors before write\n'
