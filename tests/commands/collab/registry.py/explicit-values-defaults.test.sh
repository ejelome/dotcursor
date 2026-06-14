#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

cd "$TMPDIR"
export COLLAB_STATE_HOME="$TMPDIR/state-home"

RUN_DATE="$(date +%Y-%m-%d)"
TARGET="$RUN_DATE-explicit-values-defaults"

"$ROOT/commands/collab/engine/registry.py" init --agent-id codex --reviewer pa "Explicit Values Defaults" >/dev/null
"$ROOT/commands/collab/engine/registry.py" init --agent-id codex --reviewer pa --no-participant-verification "Explicit Values Defaults No Participant" >/dev/null
"$ROOT/commands/collab/engine/registry.py" join-participants "$TARGET" pe --agent-id codex >/dev/null
"$ROOT/commands/collab/engine/registry.py" join-participants "$TARGET" pa --agent-id opus >/dev/null
REGISTRY="$("$ROOT/commands/collab/engine/registry.py" registry-path)"

python3 - "$REGISTRY" <<'PY'
import json
import sys
from pathlib import Path

entry = next(
    item
    for item in json.loads(Path(sys.argv[1]).read_text())['collabs']
    if item['slug'] == 'explicit-values-defaults'
)
assert entry['createdAt'], entry
assert entry['terminal'] == 'seal', entry
assert entry['reviewerMode'] == 'last-in-convergent-phases', entry
assert entry['reviewerOptionalPhases'] == ['Discussion'], entry
assert entry['verification']['rounds'] == 0, entry['verification']
assert entry['verification']['cap'] == 3, entry['verification']
assert entry['verification']['subState'] == 'participant', entry['verification']
assert entry['verification']['participantVerification'] is True, entry['verification']
assert entry['verification']['participants'] == {}, entry['verification']
no_participant = next(
    item
    for item in json.loads(Path(sys.argv[1]).read_text())['collabs']
    if item['slug'] == 'explicit-values-defaults-no-participant'
)
assert no_participant['verification']['rounds'] == 0, no_participant['verification']
assert no_participant['verification']['cap'] == 3, no_participant['verification']
assert no_participant['verification']['subState'] == 'seal', no_participant['verification']
assert no_participant['verification']['participantVerification'] is False, no_participant['verification']
assert no_participant['verification']['participants'] == {}, no_participant['verification']
PY

assert_rejects_missing_field() {
  local label="$1"
  local field_path="$2"
  local expected="$3"
  cp "$REGISTRY" "$TMPDIR/$label.json"
  python3 - "$TMPDIR/$label.json" "$field_path" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
field_path = sys.argv[2].split('.')
data = json.loads(path.read_text())
entry = next(item for item in data['collabs'] if item['slug'] == 'explicit-values-defaults')
target = entry
for segment in field_path[:-1]:
    target = target[segment]
target.pop(field_path[-1], None)
path.write_text(json.dumps(data, indent=2) + '\n')
PY
  set +e
  output="$("$ROOT/commands/collab/engine/registry.py" --registry "$TMPDIR/$label.json" validate 2>&1)"
  status=$?
  set -e
  if [[ "$status" -eq 0 || "$output" != *"$expected"* ]]; then
    printf 'FAIL: %s did not reject missing explicit field\n%s\n' "$label" "$output" >&2
    exit 1
  fi
}

assert_rejects_missing_field terminal terminal 'collab.terminal is required when createdAt is present'
assert_rejects_missing_field reviewer-mode reviewerMode 'collab.reviewerMode is required when createdAt is present'
assert_rejects_missing_field reviewer-optional-phases reviewerOptionalPhases 'collab.reviewerOptionalPhases is required when createdAt is present'
assert_rejects_missing_field verification-cap verification.cap 'verification.cap is required when createdAt is present'
assert_rejects_missing_field verification-participant verification.participantVerification 'verification.participantVerification is required when createdAt is present'

cp "$REGISTRY" "$TMPDIR/grandfather.json"
python3 - "$TMPDIR/grandfather.json" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
data = json.loads(path.read_text())
entry = next(item for item in data['collabs'] if item['slug'] == 'explicit-values-defaults')
entry.pop('createdAt', None)
entry.pop('terminal', None)
entry.pop('reviewerMode', None)
entry.pop('reviewerOptionalPhases', None)
verification = entry['verification']
for field in ('cap', 'subState', 'participantVerification', 'participants'):
    verification.pop(field, None)
path.write_text(json.dumps(data, indent=2) + '\n')
PY
"$ROOT/commands/collab/engine/registry.py" --registry "$TMPDIR/grandfather.json" validate >/dev/null

python3 - "$ROOT" <<'PY'
import ast
import sys
from pathlib import Path

root = Path(sys.argv[1])
sources = [
    root / 'commands/collab/engine/registry.py',
    root / 'commands/collab/engine/seal_verification.py',
    root / 'commands/collab/engine/participants.py',
]
EXPLICIT_DEFAULTS = {
    'DEFAULT_TERMINAL',
    'DEFAULT_VERIFICATION_CAP',
    'DEFAULT_REVIEWER_MODE',
    'DEFAULT_REVIEWER_OPTIONAL_PHASES',
    'DEFAULT_OPEN_ROSTER_EFFORT',
}

def line_window(lines, lineno, radius=4):
    start = max(0, lineno - radius - 1)
    end = min(len(lines), lineno + radius)
    return '\n'.join(lines[start:end])

def contains_default(node):
    return any(
        isinstance(item, ast.Name) and item.id in EXPLICIT_DEFAULTS
        for item in ast.walk(node)
    )

def direct_fallback_stmt_contains_default(stmt):
    if isinstance(stmt, (ast.If, ast.For, ast.While, ast.Try, ast.With, ast.FunctionDef, ast.ClassDef)):
        return False
    return contains_default(stmt)

def membership_test(node):
    return any(
        isinstance(item, ast.Compare)
        and any(isinstance(op, (ast.In, ast.NotIn)) for op in item.ops)
        for item in ast.walk(node)
    )

def get_default_call(node):
    if not isinstance(node, ast.Call):
        return False
    if not isinstance(node.func, ast.Attribute) or node.func.attr != 'get':
        return False
    return any(contains_default(arg) for arg in node.args[1:]) or any(
        contains_default(keyword.value)
        for keyword in node.keywords
        if keyword.value is not None
    )

def allowed_grandfather_or_exemption(lines, lineno):
    window = line_window(lines, lineno)
    return (
        "entry.get('createdAt') is None" in window
        or 'created_at is None' in window
        or 'Explicit-values exemption: open-roster effort' in window
    )

def implicit_default_violations(path_label, text):
    tree = ast.parse(text)
    lines = text.splitlines()
    violations = []
    for node in ast.walk(tree):
        if isinstance(node, ast.Call) and get_default_call(node):
            if not allowed_grandfather_or_exemption(lines, node.lineno):
                violations.append((path_label, node.lineno, '.get default fallback'))
        elif isinstance(node, ast.IfExp):
            if membership_test(node.test) and (
                contains_default(node.body) or contains_default(node.orelse)
            ):
                if not allowed_grandfather_or_exemption(lines, node.lineno):
                    violations.append((path_label, node.lineno, 'in/else default fallback'))
        elif isinstance(node, ast.If):
            if membership_test(node.test):
                default_body = any(direct_fallback_stmt_contains_default(item) for item in node.body)
                default_else = any(direct_fallback_stmt_contains_default(item) for item in node.orelse)
                if (default_body or default_else) and not allowed_grandfather_or_exemption(lines, node.lineno):
                    violations.append((path_label, node.lineno, 'membership default fallback'))
    return violations

bad_in_else = """
def read_created_record(entry):
    if entry.get('createdAt') is not None:
        return entry['cap'] if 'cap' in entry else DEFAULT_VERIFICATION_CAP
"""
bad_get = """
def read_created_record(entry):
    if entry.get('createdAt') is not None:
        return entry.get('cap', DEFAULT_VERIFICATION_CAP)
"""
good_grandfather = """
def read_legacy_record(entry):
    if entry.get('createdAt') is None:
        return entry['cap'] if 'cap' in entry else DEFAULT_VERIFICATION_CAP
"""

assert implicit_default_violations('bad-in-else.py', bad_in_else), (
    'lint failed to reject in/else DEFAULT_* fallback for a createdAt record'
)
assert implicit_default_violations('bad-get.py', bad_get), (
    'lint failed to reject .get DEFAULT_* fallback for a createdAt record'
)
assert not implicit_default_violations('good-grandfather.py', good_grandfather), (
    'lint rejected the allowed no-createdAt grandfather branch'
)

all_violations = []
for path in sources:
    all_violations.extend(implicit_default_violations(str(path), path.read_text()))
assert not all_violations, '\n'.join(
    f'{path}:{line}: forbidden implicit default pattern: {kind}'
    for path, line, kind in all_violations
)
PY

printf 'OK: explicit registry defaults are stamped, required under createdAt, and not re-derived from missing fields\n'
