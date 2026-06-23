#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

SUMMARIZE_ROUTE="$ROOT/commands/collab/summarize/index.md"
REWRITE_EXECUTION_ROUTE="$ROOT/commands/collab/rewrite-execution/index.md"
RUN_PLAN_ROUTE="$ROOT/commands/collab/run-plan/index.md"

for anchor in \
  '<!-- abort: summarize-active-phase-missing -->' \
  '<!-- abort: summarize-no-contributions -->' \
  '<!-- abort: summarize-record-unreadable -->' \
  '<!-- abort: summarize-registry-target-unavailable -->'
do
  if ! grep -Fq "$anchor" "$SUMMARIZE_ROUTE"; then
    printf 'FAIL: summarize abort anchor missing: %s\n' "$anchor" >&2
    exit 1
  fi
done

if ! grep -Fq '<!-- abort: rewrite-execution-registry-target -->' "$REWRITE_EXECUTION_ROUTE"; then
  printf 'FAIL: rewrite-execution registry-target abort anchor missing\n' >&2
  exit 1
fi
if ! grep -Fq '**ABORT**: registry target unavailable' "$REWRITE_EXECUTION_ROUTE"; then
  printf 'FAIL: rewrite-execution registry-target abort text missing\n' >&2
  exit 1
fi

if ! grep -Fq 'If Step 7 found no unchecked assigned items' "$RUN_PLAN_ROUTE"; then
  printf 'FAIL: run-plan Step 8 does not condition prior completed execution on Step 7 having no unchecked items\n' >&2
  exit 1
fi
if ! grep -Fq 'a later successful `execution` helper write replaces the role' "$RUN_PLAN_ROUTE"; then
  printf 'FAIL: run-plan Step 8 does not document replacement execution semantics\n' >&2
  exit 1
fi

printf 'OK: collab route doc contracts remain anchored\n'
