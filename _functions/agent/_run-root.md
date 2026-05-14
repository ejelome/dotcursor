# /agent Run-Root Boundary

Shared run-root vocabulary for scaffold-mutating `/agent` routes.

## Trigger

**Slash:** (reference only — not an invocable route)
**Prose dispatch:** (reference only — not an invocable route)
**Search phrases:** agent run root, global runtime root, target repository root

## Steps

1. Read this document before changing `/agent install`, `/agent patch`, or `/agent upgrade` run-root checks.
2. Cite this document from any `/agent` route that distinguishes the installed Cursor command tree from a repository being scaffolded.
3. Do not mutate repository state from this documentation-only reference.

## Notes

- **Global runtime root:** The installed Cursor command tree at `~/.cursor`, containing runtime command, rule, template, role, and helper sources. In this repository, the source checkout itself is also located at that path; `/agent` scaffold commands still treat it as the runtime root, not as a target project to install into.
- **Target repository root:** The git repository root for the project receiving or maintaining scaffold files such as `CLAUDE.md`, `AGENTS.md`, and `REPOSITORY.md`.
- **Boundary:** `/agent install` and `/agent upgrade` must run from a target repository root. They must abort when invoked from the global runtime root because their scaffold writes are meant for consumer repositories, not the command source tree.
- **Placement rationale:** This reference lives under `_functions/agent/` because the boundary is currently scoped to `/agent` scaffold-mutating routes. Move it to `_core/` only if a non-`/agent` route needs the same vocabulary.
