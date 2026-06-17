#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"

if [[ -e "$ROOT/commands/collab/aggregate/index.md" ]]; then
  printf 'FAIL: retired aggregate route file still exists\n' >&2
  exit 1
fi

if "$ROOT/commands/collab/engine/registry.py" --help | grep -Eq '(^|[,{[:space:]])aggregate([,[:space:]}]|$)'; then
  printf 'FAIL: registry.py help still exposes aggregate subcommand\n' >&2
  exit 1
fi

set +e
aggregate_output="$("$ROOT/commands/collab/engine/registry.py" aggregate 2>&1)"
aggregate_status=$?
set -e
if [[ "$aggregate_status" -eq 0 || "$aggregate_output" != *'invalid choice'* ]]; then
  printf 'FAIL: registry.py aggregate remains invocable\n%s\n' "$aggregate_output" >&2
  exit 1
fi

if grep -Fq '(collab aggregate)' "$ROOT/commands/collab/index.md" "$ROOT/commands/commands.md" "$ROOT/generated/command-reference.md"; then
  printf 'FAIL: aggregate dispatch remains in router or generated command reference\n' >&2
  exit 1
fi

if grep -Fq 'aggregate/index.md' "$ROOT/commands/collab/index.md" "$ROOT/commands/commands.md" "$ROOT/generated/command-reference.md"; then
  printf 'FAIL: aggregate route path remains in router or generated command reference\n' >&2
  exit 1
fi

printf 'OK: aggregate route and registry helper are absent\n'
