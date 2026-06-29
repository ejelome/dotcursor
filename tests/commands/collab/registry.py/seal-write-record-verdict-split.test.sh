#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

cd "$TMPDIR"
export COLLAB_STATE_HOME="$TMPDIR/state-home"

# shellcheck source=tests/commands/collab/registry.py/verification-test-lib.sh
source "$ROOT/tests/commands/collab/registry.py/verification-test-lib.sh"

enter_seal_state() {
  local target="$1"
  python3 - "$target" "$(registry_path)" <<'PY'
import json
import sys
from pathlib import Path

target, registry = sys.argv[1:3]
path = Path(registry)
data = json.loads(path.read_text())
entry = next(item for item in data['collabs'] if item['id'] == target)
entry['activePhase'] = 'Completion'
entry.setdefault('completion', {})['subState'] = 'verification'
entry.setdefault('verification', {})['subState'] = 'seal'
path.write_text(json.dumps(data, indent=2) + '\n')
PY
}

TARGET="$RUN_DATE-seal-write-record-verdict-split"

init_reviewer_target "Seal Write Record Verdict Split" "seal-write-record-verdict-split"
complete_execution "$TARGET"
seed_paired_verification_round "$TARGET"
enter_seal_state "$TARGET"

seal_state="$("$ROOT/commands/collab/engine/registry.py" seal-state "$TARGET" pa)"
seal_revision="$(read_json_field registryRevision <<<"$seal_state")"

"$ROOT/commands/collab/engine/registry.py" seal-write "$TARGET" pa \
  --observed-revision "$seal_revision" \
  --caller-role pa >/dev/null

python3 - "$TARGET" "$(registry_path)" <<'PY'
import json
import sys
from pathlib import Path

target, registry = sys.argv[1:3]
entry = next(item for item in json.loads(Path(registry).read_text())['collabs'] if item['id'] == target)
assert entry['status'] == 'open', entry
assert isinstance(entry.get('verificationSeal'), dict), entry
assert entry['verification']['subState'] == 'assessment', entry['verification']
assert 'verdict' not in entry, entry
PY

absent_output="$("$ROOT/commands/collab/engine/registry.py" record-verdict "$TARGET" pa \
  --observed-revision "$seal_revision" \
  --outcome success \
  --caller-role pa 2>&1 || true)"
if [[ "$absent_output" != *"stale registry revision"* ]]; then
  printf 'FAIL: record-verdict did not reject stale observed revision\n%s\n' "$absent_output" >&2
  exit 1
fi

verdict_state="$("$ROOT/commands/collab/engine/registry.py" seal-state "$TARGET" pa)"
verdict_revision="$(read_json_field registryRevision <<<"$verdict_state")"
"$ROOT/commands/collab/engine/registry.py" record-verdict "$TARGET" pa \
  --observed-revision "$verdict_revision" \
  --outcome success \
  --evidence '{"committedPaths":["platform/tooling/audit.sh"],"executionEntryIds":["pe-2026-05-15t21-00-00-02-00"]}' \
  --caller-role pa >/dev/null

python3 - "$TARGET" "$(registry_path)" <<'PY'
import json
import sys
from pathlib import Path

target, registry = sys.argv[1:3]
data = json.loads(Path(registry).read_text())
entry = next(item for item in data['collabs'] if item['id'] == target)
assert entry['status'] == 'closed', entry
assert entry['verdict']['outcome'] == 'success', entry
assert data.get('activeCollabId') is None, data.get('activeCollabId')
PY

NO_SEAL_TARGET="$RUN_DATE-record-verdict-no-seal"
init_reviewer_target "Record Verdict No Seal" "record-verdict-no-seal"
complete_execution "$NO_SEAL_TARGET"
seed_paired_verification_round "$NO_SEAL_TARGET"
enter_seal_state "$NO_SEAL_TARGET"
no_seal_state="$("$ROOT/commands/collab/engine/registry.py" seal-state "$NO_SEAL_TARGET" pa)"
no_seal_revision="$(read_json_field registryRevision <<<"$no_seal_state")"
no_seal_output="$("$ROOT/commands/collab/engine/registry.py" record-verdict "$NO_SEAL_TARGET" pa \
  --observed-revision "$no_seal_revision" \
  --outcome success \
  --caller-role pa 2>&1 || true)"
if [[ "$no_seal_output" != *"verification assessment is not active"* ]]; then
  printf 'FAIL: record-verdict accepted a missing seal\n%s\n' "$no_seal_output" >&2
  exit 1
fi

STALE_TARGET="$RUN_DATE-record-verdict-stale-seal"
init_reviewer_target "Record Verdict Stale Seal" "record-verdict-stale-seal"
complete_execution "$STALE_TARGET"
seed_paired_verification_round "$STALE_TARGET"
enter_seal_state "$STALE_TARGET"
stale_state="$("$ROOT/commands/collab/engine/registry.py" seal-state "$STALE_TARGET" pa)"
stale_revision="$(read_json_field registryRevision <<<"$stale_state")"
"$ROOT/commands/collab/engine/registry.py" seal-write "$STALE_TARGET" pa \
  --observed-revision "$stale_revision" \
  --caller-role pa >/dev/null
python3 - "$STALE_TARGET" "$(registry_path)" <<'PY'
import json
import sys
from pathlib import Path

target, registry = sys.argv[1:3]
path = Path(registry)
data = json.loads(path.read_text())
entry = next(item for item in data['collabs'] if item['id'] == target)
entry['verificationSeal']['stale'] = True
entry['verificationSeal']['staleReason'] = 'test-stale'
path.write_text(json.dumps(data, indent=2) + '\n')
PY
stale_verdict_state="$("$ROOT/commands/collab/engine/registry.py" seal-state "$STALE_TARGET" pa)"
stale_verdict_revision="$(read_json_field registryRevision <<<"$stale_verdict_state")"
stale_output="$("$ROOT/commands/collab/engine/registry.py" record-verdict "$STALE_TARGET" pa \
  --observed-revision "$stale_verdict_revision" \
  --outcome success \
  --caller-role pa 2>&1 || true)"
if [[ "$stale_output" != *"success verdict requires current non-stale verificationSeal"* ]]; then
  printf 'FAIL: record-verdict accepted a stale seal\n%s\n' "$stale_output" >&2
  exit 1
fi

printf 'OK: seal-write and record-verdict own separate seal and verdict effects\n'
