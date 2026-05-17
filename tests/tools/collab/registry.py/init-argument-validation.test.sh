#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

cd "$TMPDIR"
export CURSOR_COLLAB_STATE_HOME="$TMPDIR/state-home"

set +e
missing_name_output="$("$ROOT/tools/collab/registry.py" init --agent-id codex 2>&1)"
missing_name_status=$?
set -e
if [[ "$missing_name_status" -eq 0 || "$missing_name_output" != *'<name> is required'* ]]; then
  printf 'FAIL: init accepted a missing name\n%s\n' "$missing_name_output" >&2
  exit 1
fi

set +e
bad_reviewer_output="$("$ROOT/tools/collab/registry.py" init --agent-id codex --reviewer bad-role "Argument Validation" 2>&1)"
bad_reviewer_status=$?
set -e
if [[ "$bad_reviewer_status" -eq 0 || "$bad_reviewer_output" != *'--reviewer requires a role key'* ]]; then
  printf 'FAIL: init accepted an invalid reviewer value\n%s\n' "$bad_reviewer_output" >&2
  exit 1
fi

set +e
cap_without_gate_output="$("$ROOT/tools/collab/registry.py" init --agent-id codex --verification-cap 2 "Argument Validation" 2>&1)"
cap_without_gate_status=$?
set -e
if [[ "$cap_without_gate_status" -eq 0 || "$cap_without_gate_output" != *'--verification-cap requires --participant-verification'* ]]; then
  printf 'FAIL: init accepted --verification-cap without --participant-verification\n%s\n' "$cap_without_gate_output" >&2
  exit 1
fi

set +e
slug_empty_output="$("$ROOT/tools/collab/registry.py" init --agent-id codex "!!!" 2>&1)"
slug_empty_status=$?
set -e
if [[ "$slug_empty_status" -eq 0 || "$slug_empty_output" != *'slug is empty'* ]]; then
  printf 'FAIL: init accepted an empty slug\n%s\n' "$slug_empty_output" >&2
  exit 1
fi

printf 'OK: init argument validation rejects missing names, invalid reviewer values, unbound verification caps, and empty slugs\n'
