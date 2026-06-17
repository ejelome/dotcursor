#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"

python3 - "$ROOT" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

root = Path(sys.argv[1])
sy_path = root / 'commands/collab/reference/synthesizers/sy.json'
dp_path = root / 'commands/collab/reference/projectors/dp.json'

assert sy_path.exists(), sy_path
assert not (root / 'commands/collab/reference/roles/sy.json').exists()
assert not (root / 'commands/collab/reference/projectors/sy.json').exists()

sy = json.loads(sy_path.read_text())
dp = json.loads(dp_path.read_text())
assert list(sy) == list(dp), sy
assert sy['key'] == 'sy', sy
assert 'Generative' in sy['displayName'], sy
assert any('participant role' in item for item in sy['prohibitions']), sy
assert any('deterministic projector' in item for item in sy['prohibitions']), sy
assert any('projectors metadata directory' in item for item in sy['prohibitions']), sy

roles_output = subprocess.run(
    [
        sys.executable,
        str(root / 'platform/tooling/roles.py'),
        '--roles-dir',
        str(root / 'commands/collab/reference/roles'),
        'roles',
    ],
    check=True,
    text=True,
    stdout=subprocess.PIPE,
).stdout
assert ' sy ' not in roles_output, roles_output
assert 'Generative Synthesis Author' not in roles_output, roles_output

print('OK: sy synthesizer metadata is nonjoinable and outside projectors')
PY
