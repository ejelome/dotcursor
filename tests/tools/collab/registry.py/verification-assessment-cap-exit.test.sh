#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/_verification_test_lib.sh"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT
cd "$TMPDIR"
export CURSOR_COLLAB_STATE_HOME="$TMPDIR/state-home"

init_reviewer_target "Verification Assessment Cap Exit" "verification-assessment-cap-exit"
TARGET="$RUN_DATE-verification-assessment-cap-exit"
REGISTRY="$(registry_path)"
"$ROOT/tools/collab/registry.py" set "$TARGET" active-phase Completion --force --caller-role mod >/dev/null
complete_execution "$TARGET"

python3 - "$REGISTRY" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
data = json.loads(path.read_text())
entry = next(item for item in data['collabs'] if item['slug'] == 'verification-assessment-cap-exit')
entry['verification']['cap'] = 1
path.write_text(json.dumps(data, indent=2) + '\n')
PY

state="$("$ROOT/tools/collab/registry.py" seal-state "$TARGET" pa)"
revision="$(read_json_field registryRevision <<<"$state")"
set +e
output="$("$ROOT/tools/collab/registry.py" seal-render "$TARGET" pa --observed-revision "$revision" --caller-role pa 2>&1)"
status=$?
set -e
if [[ "$status" -eq 0 || "$output" != *"round cap reached; reissue with --cap-exit reopen-action-plan, --cap-exit reopen-handoff, or --cap-exit archive"* ]]; then
  printf 'FAIL: seal-render did not require cap exit\n%s\n' "$output" >&2
  exit 1
fi

"$ROOT/tools/collab/registry.py" seal-render "$TARGET" pa \
  --observed-revision "$revision" \
  --cap-exit reopen-action-plan \
  --caller-role pa >/dev/null

python3 - "$REGISTRY" <<'PY'
import json
import sys
from pathlib import Path

entry = next(item for item in json.loads(Path(sys.argv[1]).read_text())['collabs'] if item['slug'] == 'verification-assessment-cap-exit')
assert entry['status'] == 'open'
assert entry['activePhase'] == 'Action Plan'
assert entry['completion']['subState'] == 'execution'
assert entry['verification']['subState'] == 'assessment'
assert entry['verificationSeal']['capExit'] == 'reopen-action-plan'
assert 'verdict' not in entry
PY

printf 'OK: verification cap exits enter assessment state without applying verdict work\n'
