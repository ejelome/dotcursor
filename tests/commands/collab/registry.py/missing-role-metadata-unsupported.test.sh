#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

python3 - "$ROOT" "$TMPDIR" <<'PY'
import importlib.util
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
tmp = Path(sys.argv[2])
roles = tmp / 'roles'
records = tmp / 'records'
roles.mkdir()
records.mkdir()

(roles / 'mod.json').write_text(json.dumps({
    'key': 'mod',
    'displayName': 'Moderator',
    'concerns': ['coordination'],
}) + '\n')
registry_path = tmp / 'registry.json'
target = '2026-06-11-missing-role-boundary'
missing_role = 'xx'
registry = {
    'revision': 1,
    'activeCollabId': target,
    'collabs': [{
        'id': target,
        'slug': 'missing-role-boundary',
        'title': 'Missing Role Boundary',
        'description': 'Missing role boundary',
        'status': 'open',
        'activePhase': 'Audit',
        'moderatorRole': 'mod',
        'participants': [
            {'role': 'mod', 'agentId': 'codex'},
            {'role': missing_role, 'agentId': 'fixture-cli'},
        ],
        'turnOrder': [missing_role],
        'transcriptPath': f'records/{target}.md',
        'archived': False,
    }],
}
registry_path.write_text(json.dumps(registry, indent=2) + '\n')
(records / f'{target}-raw.md').write_text('# Missing Role Boundary\n')

sys.path.insert(0, str(root))
spec = importlib.util.spec_from_file_location('registry_under_test', root / 'commands/collab/engine/registry.py')
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)
module.DEFAULT_ROLES_DIR = roles

try:
    module.validate_registry(registry, registry_path)
except SystemExit as exc:
    assert 'participants role file unreadable for xx' in str(exc), str(exc)
else:
    raise AssertionError('stored missing-role participant validated')

try:
    module.join_participants(registry_path, target, missing_role, 'fixture-cli', roles)
except SystemExit as exc:
    assert 'role missing:' in str(exc), str(exc)
else:
    raise AssertionError('missing role metadata was accepted as joinable')

from commands.collab.engine.transcript_render import rendered_participants_table

try:
    rendered_participants_table(registry['collabs'][0], roles)
except SystemExit as exc:
    assert 'role missing:' in str(exc), str(exc)
else:
    raise AssertionError('stored missing-role participant rendered')
PY

printf 'OK: missing role metadata makes stored participants unsupported\n'
