# dotcursor

Configuration framework for `~/.cursor` command routes and agent harnesses.

## Entry points

Each adapter is a thin routing-only file that points to `commands/commands.md` as the shared command catalog.

| Adapter | For | Bootstrap chain |
|---|---|---|
| `CLAUDE.md` | Claude Code CLI | `CLAUDE.md` → `AGENTS.md` → `commands/commands.md` |
| `AGENTS.md` | Codex, GPT, and other agent harnesses | `AGENTS.md` → `commands/commands.md` |

## Directory layout

```
~/.cursor/
├── CLAUDE.md          — Claude Code adapter (routing only)
├── AGENTS.md          — other-harness adapter (routing only)
├── README.md          — this file
├── .collab.json       — checked-in collab repo marker
├── commands/          — command catalog, routers, route playbooks, and slices
│   └── collab/        — collab routes plus engine/, reference/, and data/
├── platform/          — shared cross-namespace infrastructure
│   ├── standards/     — cross-cutting invariants and contracts
│   ├── tooling/       — framework tooling and validators
│   ├── templates/     — scaffolding templates
│   └── data/          — shared advisory vocabulary and platform data
├── generated/         — framework-generated catalogs (do not edit by hand)
└── tests/             — agent-facing and shell QA harnesses
```

### `generated/` discovery

Files under `generated/` are produced by scripts in `platform/tooling/`. Edit the source files or templates, then re-run the relevant sync script — do not edit `generated/` directly.

## Setup

Run `platform/tooling/install-git-hooks.sh` to install pre-commit and pre-push hooks that run the full test suite before history moves. Pass `--no-verify` to `git commit` or `git push` to skip the hooks. Force-push blocking and deletion blocking on `main` are manual GitHub repository settings, not a source patch.

## Done signal

Run `platform/tooling/audit.sh` to verify the framework surface. The audit exits 0 when:

- Runtime paths (`$HOME/.collabs/<projectId>/`, `.claude/`, `projects/`) are excluded from git
- No accidental untracked payload
- Every tracked file is reachable from an adapter, core, or catalog
- Framework-generated output is distinguishable from generated output
- Reference graph has no broken links
