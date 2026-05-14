#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

cd "$TMPDIR"

"$ROOT/tools/collab/registry.py" init --agent-id codex "Execute Spawn Scope" >/dev/null
"$ROOT/tools/collab/registry.py" join-participants 2026-05-14-execute-spawn-scope pe --agent-id codex >/dev/null
"$ROOT/tools/collab/registry.py" set 2026-05-14-execute-spawn-scope active-phase Completion --force --caller-role mod >/dev/null

set +e
output="$("$ROOT/tools/collab/registry.py" execute-spawn 2026-05-14-execute-spawn-scope pe --scope tests --returned-path _tests/outside.md 2>&1)"
status=$?
set -e

if [[ "$status" -eq 0 ]]; then
  printf 'FAIL: execute-spawn accepted returned path outside scope\n' >&2
  exit 1
fi

if [[ "$output" != *"returned path outside assigned scope: _tests/outside.md"* ]]; then
  printf 'FAIL: execute-spawn abort message mismatch\n%s\n' "$output" >&2
  exit 1
fi

printf 'OK: execute-spawn rejects returned paths outside assigned scope\n'
