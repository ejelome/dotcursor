#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"

TARGET_SPEC_RUNTIME_EXEMPTIONS=(
  "commands/collab/reference/transcript-template.md"
  "commands/collab/reference/transcript-template-raw.md"
)

is_target_spec_runtime_exempt() {
  local path="$1"
  local exempt
  for exempt in "${TARGET_SPEC_RUNTIME_EXEMPTIONS[@]}"; do
    if [[ "$path" == "$exempt" ]]; then
      return 0
    fi
  done
  return 1
}

require_exemption() {
  local path="$1"
  if ! is_target_spec_runtime_exempt "$path"; then
    printf 'FAIL: target-format template missing explicit runtime exemption: %s\n' "$path" >&2
    exit 1
  fi
  if ! grep -Fq 'Target-format spec' "$ROOT/$path"; then
    printf 'FAIL: target-format template missing provenance token: %s\n' "$path" >&2
    exit 1
  fi
}

require_exemption "commands/collab/reference/transcript-template.md"
require_exemption "commands/collab/reference/transcript-template-raw.md"

if ! grep -Fq 'commands/collab/engine/transcript_render.py' "$ROOT/commands/collab/reference/anchor-convention.md"; then
  printf 'FAIL: anchor convention missing transcript renderer emitter citation\n' >&2
  exit 1
fi

for template in \
  "commands/collab/reference/transcript-template.md" \
  "commands/collab/reference/transcript-template-raw.md"; do
  if ! grep -Fq 'Supersedes ~/Downloads/' "$ROOT/$template"; then
    printf 'FAIL: target-format template missing supersedes line: %s\n' "$template" >&2
    exit 1
  fi
done

# Marker-only filtering is not acceptable: a file must be in the explicit exemption set.
marker_only_fixture="commands/collab/reference/not-a-runtime-exempt-template.md"
if is_target_spec_runtime_exempt "$marker_only_fixture"; then
  printf 'FAIL: runtime exemption is broader than the explicit target-template set\n' >&2
  exit 1
fi

while IFS= read -r source_path; do
  rel_source="${source_path#"$ROOT"/}"
  if [[ "$rel_source" == "tests/commands/collab/registry.py/target-spec-template-runtime-exemption.test.sh" ]]; then
    continue
  fi
  for template in "${TARGET_SPEC_RUNTIME_EXEMPTIONS[@]}"; do
    if grep -Fq "$template" "$source_path"; then
      printf 'FAIL: target-format template entered helper-output/runtime-example validation input: %s via %s\n' "$template" "$rel_source" >&2
      exit 1
    fi
  done
done < <(
  rg -l \
    -e 'runtime-example' \
    -e 'runtime example' \
    -e 'helper output' \
    -e 'helper-output' \
    "$ROOT/commands" "$ROOT/tests" "$ROOT/platform"
)

printf 'OK: target-format transcript templates are explicit runtime-example exemptions\n'
