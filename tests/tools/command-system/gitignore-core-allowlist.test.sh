#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$ROOT"

assert_not_ignored() {
  local path="$1"
  if git check-ignore -q --no-index "$path"; then
    printf 'FAIL: source path is ignored by .gitignore: %s\n' "$path" >&2
    exit 1
  fi
}

assert_ignored() {
  local path="$1"
  if ! git check-ignore -q --no-index "$path"; then
    printf 'FAIL: runtime path is not ignored by .gitignore: %s\n' "$path" >&2
    exit 1
  fi
}

assert_not_ignored core/collab/example-new-source.md
assert_not_ignored core/framework/example-new-source.md
assert_not_ignored core/new-shared-surface/example.md
assert_ignored projects/example-runtime-state.json

printf 'OK: .gitignore allowlist keeps representative core/** source paths trackable\n'
