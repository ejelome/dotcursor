#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/verification-test-lib.sh"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT
cd "$TMPDIR"
export COLLAB_STATE_HOME="$TMPDIR/state-home"

init_reviewer_target "Seal Verdict Companion Close" "seal-verdict-companion-close"
TARGET="$RUN_DATE-seal-verdict-companion-close"
"$ROOT/commands/collab/engine/registry.py" set "$TARGET" active-phase Completion --force --caller-role mod >/dev/null
start_assessment "$TARGET"
revision="$(assessment_revision "$TARGET")"
"$ROOT/commands/collab/engine/registry.py" seal-render "$TARGET" pa \
  --observed-revision "$revision" \
  --outcome success \
  --evidence '{"registryRevision":2,"committedPaths":["platform/tooling/audit.sh"],"executionEntryIds":["pe-2026-05-15t21-00-00-02-00"]}' \
  --caller-role pa >/dev/null

REGISTRY="$(registry_path)"
python3 - "$REGISTRY" "$TARGET" <<'PY'
import json
import sys
from pathlib import Path

registry = Path(sys.argv[1])
target = sys.argv[2]
data = json.loads(registry.read_text())
entry = next(item for item in data['collabs'] if item['id'] == target)
companion = registry.parent / Path(entry['transcriptPath']).with_name(
    f"{Path(entry['transcriptPath']).stem}-seal-verdict.json"
)
assert companion.exists(), companion
companion.unlink()
entry['status'] = 'open'
data['activeCollabId'] = target
registry.write_text(json.dumps(data, indent=2) + '\n')
PY

"$ROOT/commands/collab/engine/registry.py" close "$TARGET" --caller-role mod >/dev/null

python3 - "$REGISTRY" "$TARGET" <<'PY'
import json
import sys
from pathlib import Path

registry = Path(sys.argv[1])
target = sys.argv[2]
data = json.loads(registry.read_text())
entry = next(item for item in data['collabs'] if item['id'] == target)
companion = registry.parent / Path(entry['transcriptPath']).with_name(
    f"{Path(entry['transcriptPath']).stem}-seal-verdict.json"
)
entry['status'] = 'open'
data['activeCollabId'] = target
companion.write_text('{"authoritative": true, "closeGate": "seal-verdict.json"}\n')
registry.write_text(json.dumps(data, indent=2) + '\n')
PY

"$ROOT/commands/collab/engine/registry.py" close "$TARGET" --caller-role mod >/dev/null

init_reviewer_target "Seal Verdict Companion No Seal" "seal-verdict-companion-no-seal"
NO_SEAL_TARGET="$RUN_DATE-seal-verdict-companion-no-seal"
"$ROOT/commands/collab/engine/registry.py" set "$NO_SEAL_TARGET" active-phase Completion --force --caller-role mod >/dev/null
python3 - "$REGISTRY" "$NO_SEAL_TARGET" <<'PY'
import json
import sys
from pathlib import Path

registry = Path(sys.argv[1])
target = sys.argv[2]
data = json.loads(registry.read_text())
entry = next(item for item in data['collabs'] if item['id'] == target)
entry['verdict'] = {'outcome': 'success'}
entry['completion'] = {'subState': 'verification'}
entry['verification']['subState'] = 'assessment'
companion = registry.parent / Path(entry['transcriptPath']).with_name(
    f"{Path(entry['transcriptPath']).stem}-seal-verdict.json"
)
companion.write_text('{"authoritative": false, "closeGate": "verificationSeal"}\n')
registry.write_text(json.dumps(data, indent=2) + '\n')
PY

set +e
missing_seal_output="$("$ROOT/commands/collab/engine/registry.py" close "$NO_SEAL_TARGET" --caller-role mod 2>&1)"
missing_seal_status=$?
set -e
if [[ "$missing_seal_status" -eq 0 || "$missing_seal_output" != *"requires verificationSeal"* ]]; then
  printf 'FAIL: close treated seal-verdict companion as authoritative\n%s\n' "$missing_seal_output" >&2
  exit 1
fi

printf 'OK: close ignores missing or edited seal-verdict companion and requires verificationSeal\n'
