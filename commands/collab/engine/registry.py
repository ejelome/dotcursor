#!/usr/bin/env python3
"""Thin CLI facade for the collab registry helper.

Domain implementation lives in ``registry_core``.  This file stays limited to
the executable entrypoint and compatibility exports for tests/importers.
"""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from commands.collab.engine import registry_core as _registry_core
from commands.collab.engine.registry_core import *  # noqa: F401,F403
from commands.collab.engine.registry_core import main

if __name__ != "__main__":
    sys.modules[__name__] = _registry_core


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
