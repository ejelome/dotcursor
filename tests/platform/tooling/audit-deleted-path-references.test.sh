#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT
GATE="$ROOT/platform/tooling/audit-deleted-path-references.py"

clean="$TMPDIR/clean"
mkdir -p "$clean/docs" "$clean/old"
git -C "$clean" init -q
git -C "$clean" config user.email test@example.com
git -C "$clean" config user.name Test
printf '# Current\n' >"$clean/docs/current.md"
printf 'old content\n' >"$clean/old/path.txt"
git -C "$clean" add .
git -C "$clean" commit -qm init
rm "$clean/old/path.txt"
git -C "$clean" add -A
git -C "$clean" commit -qm remove-old-path
python3 "$GATE" --root "$clean" >/dev/null

bad_reference="$TMPDIR/bad-reference"
cp -R "$clean" "$bad_reference"
printf '\nSee old/path.txt.\n' >>"$bad_reference/docs/current.md"
git -C "$bad_reference" add .
git -C "$bad_reference" commit -qm reference-old-path
set +e
python3 "$GATE" --root "$bad_reference" >"$TMPDIR/bad-reference.out" 2>&1
status=$?
set -e
if [[ "$status" -eq 0 ]]; then
  printf 'FAIL: expected deleted path reference to fail\n' >&2
  exit 1
fi
if ! grep -Fq 'references deleted path old/path.txt' "$TMPDIR/bad-reference.out"; then
  printf 'FAIL: deleted path reference output mismatch\n' >&2
  cat "$TMPDIR/bad-reference.out" >&2
  exit 1
fi

bad_reintro="$TMPDIR/bad-reintro"
cp -R "$clean" "$bad_reintro"
printf 'new content\n' >"$bad_reintro/old/path.txt"
git -C "$bad_reintro" add .
git -C "$bad_reintro" commit -qm reintroduce-old-path
set +e
python3 "$GATE" --root "$bad_reintro" >"$TMPDIR/bad-reintro.out" 2>&1
status=$?
set -e
if [[ "$status" -eq 0 ]]; then
  printf 'FAIL: expected deleted path reintroduction to fail\n' >&2
  exit 1
fi
if ! grep -Fq 'deleted path exists at HEAD without allowlist: old/path.txt' "$TMPDIR/bad-reintro.out"; then
  printf 'FAIL: deleted path reintroduction output mismatch\n' >&2
  cat "$TMPDIR/bad-reintro.out" >&2
  exit 1
fi

printf 'OK: deleted-path audit rejects references and reintroduced deleted paths\n'
