#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

python3 - "$ROOT" <<'PY'
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
patterns = [
    re.compile(r"`commands/[^`]+/index\.md`[^.\n]*(?:source of truth|authority|authoritative|full playbook rules|follow .*rule)", re.I),
    re.compile(r"(?:source of truth|authority|authoritative|full playbook rules|follow .*rule)[^.\n]*`commands/[^`]+/index\.md`", re.I),
]

def line_violates(line: str) -> bool:
    return any(pattern.search(line) for pattern in patterns)

def violations_in_tree(path: Path) -> list[str]:
    violations: list[str] = []
    for source in sorted(path.glob("*.md")):
        for number, line in enumerate(source.read_text().splitlines(), 1):
            if line_violates(line):
                violations.append(f"{source.relative_to(root)}:{number}: {line}")
    return violations

fixture_line = "Full playbook rules live in `commands/example/index.md`."
if not line_violates(fixture_line):
    print("FAIL: authority-direction pattern did not catch fixture line", file=sys.stderr)
    raise SystemExit(1)

real = violations_in_tree(root / "platform/standards")
if real:
    print("FAIL: platform standards cite command routes as rule authority", file=sys.stderr)
    print("\n".join(real), file=sys.stderr)
    raise SystemExit(1)
PY

printf 'OK: platform standards do not make command routes rule authority\n'
