#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT
GATE="$ROOT/platform/tooling/audit-retired-systems.py"

init_repo() {
  local dir="$1"
  git -C "$dir" init -q
  git -C "$dir" config user.email test@example.com
  git -C "$dir" config user.name Test
}

expect_fail() {
  local dir="$1" needle="$2" label="$3"
  set +e
  python3 "$GATE" --root "$dir" >"$TMPDIR/out" 2>&1
  local status=$?
  set -e
  if [[ "$status" -eq 0 ]]; then
    printf 'FAIL: expected %s to fail\n' "$label" >&2
    exit 1
  fi
  if ! grep -Fq "$needle" "$TMPDIR/out"; then
    printf 'FAIL: %s output mismatch\n' "$label" >&2
    cat "$TMPDIR/out" >&2
    exit 1
  fi
}

# clean repo passes
clean="$TMPDIR/clean"
mkdir -p "$clean/docs"
init_repo "$clean"
printf '# Current\n' >"$clean/docs/current.md"
git -C "$clean" add .
git -C "$clean" commit -qm init
python3 "$GATE" --root "$clean" >/dev/null

# retired dormant tooling extension (.mdc) fails
mdc="$TMPDIR/mdc"
cp -R "$clean" "$mdc"
printf 'rule\n' >"$mdc/docs/legacy.mdc"
git -C "$mdc" add .
git -C "$mdc" commit -qm add-mdc
expect_fail "$mdc" "docs/legacy.mdc: retired-system artifact returned" "mdc artifact"

# retired adapter (gemini) fails, case-insensitive on path. Fixture paths are
# chosen to exercise the predicate without colliding with historically-deleted
# real paths (which the deleted-path audit independently forbids naming).
gem="$TMPDIR/gemini"
cp -R "$clean" "$gem"
mkdir -p "$gem/tools"
printf 'adapter\n' >"$gem/tools/Gemini-adapter.txt"
git -C "$gem" add .
git -C "$gem" commit -qm add-gemini
expect_fail "$gem" "tools/Gemini-adapter.txt: retired-system artifact returned" "gemini artifact"

# retired role key (dp) fails
dp="$TMPDIR/dp"
cp -R "$clean" "$dp"
mkdir -p "$dp/fixtures"
printf '{"key":"dp"}\n' >"$dp/fixtures/dp.json"
git -C "$dp" add .
git -C "$dp" commit -qm add-dp
expect_fail "$dp" "fixtures/dp.json: retired-system artifact returned" "dp role key"

printf 'OK: retired-systems audit rejects returned artifacts\n'
