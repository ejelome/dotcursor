#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

make_repo() {
  local dir="$1"
  mkdir -p "$dir/platform/standards"
  cat >"$dir/platform/standards/context-gate.md" <<'MD'
# Context gate

Never proceed while any dependency is not fully visible.
Never proceed while any dependency is not directly readable.
Do not generate code.
MD
}

clean="$TMPDIR/clean"
make_repo "$clean"
"$ROOT/platform/tooling/sync-context-gate.sh" --check --root "$clean" >"$TMPDIR/clean.out"

if ! grep -Fq "OK: context-gate canonical source" "$TMPDIR/clean.out"; then
  printf 'FAIL: expected clean context fixture to pass\n' >&2
  cat "$TMPDIR/clean.out" >&2
  exit 1
fi

dirty="$TMPDIR/dirty"
make_repo "$dirty"
perl -0pi -e 's/^# Context gate/---\nstate: invalid\n---\n# Context gate/' "$dirty/platform/standards/context-gate.md"

set +e
"$ROOT/platform/tooling/sync-context-gate.sh" --check --root "$dirty" >"$TMPDIR/dirty.out" 2>&1
status=$?
set -e

if [[ "$status" -eq 0 ]]; then
  printf 'FAIL: expected drift fixture to fail\n' >&2
  exit 1
fi
if ! grep -Fq "context-gate.md must not carry frontmatter" "$TMPDIR/dirty.out"; then
  printf 'FAIL: drift output mismatch\n' >&2
  cat "$TMPDIR/dirty.out" >&2
  exit 1
fi

printf 'OK: context-gate parity check detects invalid canonical source shape\n'
