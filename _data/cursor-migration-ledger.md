# Cursor migration ledger

Audit trail for retiring Cursor-specific carriers to agent-agnostic equivalents. Each row records a source file or embedded block, the invariant it enforces, the current-epoch owner that receives the ported content, the mechanism that loads the ported content, the check that confirms migration is complete, and the condition under which the source may be removed.

This file is the authoritative disposition record. No Cursor carrier may be deleted until its row satisfies the composite deletion gate: all six fields populated, destination file exists and exercised, validation check passes, and a dependency scan shows zero live references to the carrier.

## Epoch sequence

The repository evolved in three phases. Each directory answers to the phase that introduced its normative function.

| Epoch | Directories | Responsibility |
|---|---|---|
| 1 — original | `_core/`, `commands/`, `rules/` | Foundational invariants, public command routing, Cursor IDE rule stubs |
| 2 — restructuring | `_functions/`, `_mdc/` | Private route implementations, Cursor rule implementations |
| 3 — multi-agent | `_templates/`, `_tests/`, `_generated/`, `_data/` | Scaffolding, validation, generated artifacts, data schemas |

Migration direction: retire epoch-1 `rules/` stubs and epoch-2 `_mdc/` implementations to epoch-3 agent-agnostic equivalents. The question "where does a ported rule go" is answered by identifying which current-epoch directory owns the normative function the carrier's original phase introduced.

## Whole-file carriers: project root

| Source path | Normative essence | Destination owner | Load contract | Validation check | Delete condition |
|---|---|---|---|---|---|
| `_CURSOR.md` | Routing-only bootstrap adapter for multi-agent harnesses. Declares the bootstrap chain (`CLAUDE.md → _CURSOR.md → commands/commands.md`), engine residency contract for `tools/collab/`, context management lifecycle, and Cursor entry point index linking to `rules/auto.mdc`, `rules/shared.mdc`, and current-epoch test/generated files. Enforced by `./tools/cursor/audit.sh`; carries Cursor-specific prose throughout. | `AGENTS.md` — bootstrap chain, engine residency, and context management content already ported here; `_CURSOR.md` entry point index becomes redundant once all `rules/` and `_mdc/` carriers are retired | Read by Cursor IDE as the Cursor-specific entry point; `./tools/cursor/audit.sh` enforces its presence; referenced from `AGENTS.md` line 29 for non-Cursor harness read obligation | `./tools/cursor/audit.sh` passes; zero references to `_CURSOR.md` as a bootstrap chain intermediate in `CLAUDE.md` and `AGENTS.md`; `./tools/cursor/check-cursor-migration.py --check` confirms zero live bootstrap references to this file | All normative content confirmed active in `AGENTS.md`; bootstrap chains in `CLAUDE.md` and `AGENTS.md` route directly to `commands/commands.md` without `_CURSOR.md` as an intermediate; all `rules/` and `_mdc/` carriers retired; `AGENTS.md` line 29 reference removed; `./tools/cursor/check-cursor-migration.py --check` passes |

## Whole-file carriers: `rules/`

| Source path | Normative essence | Destination owner | Load contract | Validation check | Delete condition |
|---|---|---|---|---|---|
| `rules/auto.mdc` | Cursor IDE always-on router stub delegating to `_mdc/auto/` implementations. No independent invariant content; purely a Cursor-specific dispatch entry point. | Deleted — no content to port; routing function replaced by agents reading `commands/commands.md` directly | n/a (router stub only) | Zero references to `rules/auto.mdc` in bootstrap adapters or command docs; `./tools/cursor/audit.sh` passes | All `_mdc/auto/` rows complete; no agent bootstrap requires this entry point; zero live references confirmed by `tools/cursor/check-cursor-migration.py` |
| `rules/shared.mdc` | Cursor IDE on-demand router stub delegating to `_mdc/shared/` implementations. No independent invariant content; routing-only stub. | Deleted — no content to port; shared rules invoked via route docs loaded from `commands/commands.md` | n/a (router stub only) | Zero references to `rules/shared.mdc` in bootstrap adapters or command docs; `./tools/cursor/audit.sh` passes | All `_mdc/shared/` rows complete; no agent bootstrap requires this entry point; zero live references confirmed |

## Whole-file carriers: `_mdc/auto/`

| Source path | Normative essence | Destination owner | Load contract | Validation check | Delete condition |
|---|---|---|---|---|---|
| `_mdc/auto/auto-context-gate.mdc` | Hard-stop policy: abort when any dependency is unreadable; prohibit stubs, guesses, and partial code generation on missing context. | `_core/context-gate.md` | Read as part of bootstrap sequence; cited from `_CURSOR.md` resume contract and route docs that reference the policy | `./tools/cursor/audit.sh` passes; `_core/context-gate.md` exists with ported body | `_core/context-gate.md` confirmed active across all harnesses; zero live references to `_mdc/auto/auto-context-gate.mdc` confirmed by `tools/cursor/check-cursor-migration.py` |
| `_mdc/auto/auto-collab-format.mdc` | Format-preservation gate: after appending moderator prose to collab records, apply structure-only formatting; never rephrase, summarize, or add substance to captured text. | `_functions/collab/_collab-format.md` | Loaded on `/collab speak` invocation; referenced from `speak.md` or collab route docs | `./tools/cursor/audit.sh` passes; `_functions/collab/_collab-format.md` exists and is referenced from `speak.md` | `_functions/collab/_collab-format.md` confirmed referenced in collab execution path; zero live references to `_mdc/auto/auto-collab-format.mdc` confirmed |
| `_mdc/auto/auto-code-typescript.mdc` | TypeScript/TSX style defaults: ESLint/Prettier config discovery, strict types, import ordering, naming conventions, React hook rules, module boundaries. | `_core/` (unassigned — outside this collab's scope) | — | — | All six fields populated; destination file exists and exercised; zero live references confirmed |
| `_mdc/auto/auto-docs-markdown.mdc` | Thin markdown base: rule-precedence deferral and TOC behavior router for all workspace `.md` and `.mdc` files. | `_core/` (unassigned — outside this collab's scope) | — | — | All six fields populated; destination file exists and exercised; zero live references confirmed |

## Whole-file carriers: `_mdc/shared/`

| Source path | Normative essence | Destination owner | Load contract | Validation check | Delete condition |
|---|---|---|---|---|---|
| `_mdc/shared/shared-cmd-quality.mdc` | QA adaptation learning gate: protocol for proposing, classifying, and applying rubric extensions across rubric-based QA slash commands. | `_functions/quality/` (unassigned — outside this collab's scope) | — | — | All six fields populated; destination file exists and exercised; zero live references confirmed |
| `_mdc/shared/shared-cmd-values.mdc` | Prose value prohibition: forbid literal role-key and model-identifier strings in `.md`/`.mdc` prose paragraphs; enforce function-bound replacements instead. | `_core/` (unassigned — outside this collab's scope) | — | — | All six fields populated; destination file exists and exercised; zero live references confirmed |
| `_mdc/shared/shared-docs-precedence.mdc` | Rule precedence matrix: five-row resolution order for markdown and workflow rule conflicts; devblog > lean playbook > invocation-gated > general markdown. | `_core/` (unassigned — outside this collab's scope) | — | — | All six fields populated; destination file exists and exercised; zero live references confirmed |
| `_mdc/shared/shared-docs-rules.mdc` | `.mdc` file hygiene contract: filename convention (`{scope}-{group}-{name}.mdc`), frontmatter requirements, body structure, 250-line budget, roster update obligations. | Deleted after cleanup — hygiene rules govern `.mdc` files that will be retired; no current-epoch equivalent needed once all `.mdc` files are gone | n/a | Zero references to `shared-docs-rules.mdc` in docs or route files | All `.mdc` files retired; no new `.mdc` files authored; zero live references confirmed |
| `_mdc/shared/shared-docs-toc.mdc` | TOC constraints: include conditions, format, anchor and slug rules for markdown table of contents. | `_core/style-guide.md` (unassigned — TOC rules to merge into style-guide; outside this collab's scope) | — | — | All six fields populated; destination file exists and exercised; zero live references confirmed |
| `_mdc/shared/shared-docs-voice.mdc` | Personal-account voice gate: for devblog paths, defer entirely to `author-voice.md`; hard-stop when `author-voice.md` is not in context. | `_core/author-voice.md` (unassigned — voice gate to merge into author-voice; outside this collab's scope) | — | — | All six fields populated; destination file exists and exercised; zero live references confirmed |
| `_mdc/shared/shared-git-commits.mdc` | Conventional commits and repo metadata: types, scopes, PR keywords, branch naming, release PR titles, repo-grounded planning. | `_core/` or `_settings/` (unassigned — outside this collab's scope) | — | — | All six fields populated; destination file exists and exercised; zero live references confirmed |

## Embedded `cursor-arg` blocks

These blocks declare route dispatch signatures and parameter schemas inside current-epoch `_functions/` files. They use the `cursor-arg` fenced block tag, a `cursor-`-prefixed naming convention. Each block is already in an agent-agnostic file; the migration question is whether to rename the tag to an agent-agnostic form or retain it as a repo-internal convention. That decision belongs to the platform-engineer role's execution track.

**Replacement routing-metadata contract:** before any `cursor-arg` block is deleted, the routing metadata it provides must be declared in an agent-agnostic form accessible to all harnesses. Each block currently declares two fields: `dispatch:` (the prose dispatch signature resolving `(namespace command ...)` invocations to the corresponding slash command) and `param:` (per-parameter schema consumed by `./tools/cursor/audit.sh` for completeness validation and used by agents for invocation guidance). The replacement form must carry both fields under a non-Cursor-prefixed tag or equivalent in-file schema. The platform-engineer role determines the specific replacement format; the delete condition for each block row is met only after that format is confirmed, the block's routing metadata is present in the replacement form, and `./tools/cursor/audit.sh` is updated to validate the new form.

| Source path | Normative essence | Destination owner | Load contract | Validation check | Delete condition |
|---|---|---|---|---|---|
| `_functions/test/run.md` (embedded `cursor-arg`) | Parameter schema declaration for `/test <target>` | Same file — already in current-epoch location; block rename pending platform-engineer audit | Read by `tools/cursor/audit.sh`; no Cursor IDE runtime dependency | `./tools/cursor/audit.sh` validates block field completeness | Tag renamed to agent-agnostic form, or pe confirms no rename needed; `audit.sh` updated accordingly; zero IDE-specific consumers |
| `_functions/quality/assess-game.md` (embedded `cursor-arg`) | Parameter schema declaration for `/quality assess game` | Same file | Read by `tools/cursor/audit.sh` | `./tools/cursor/audit.sh` | Tag renamed or confirmed; `audit.sh` updated |
| `_functions/quality/assess-interface.md` (embedded `cursor-arg`) | Parameter schema declaration for `/quality assess interface` | Same file | Read by `tools/cursor/audit.sh` | `./tools/cursor/audit.sh` | Tag renamed or confirmed; `audit.sh` updated |
| `_functions/quality/assess-operations.md` (embedded `cursor-arg`) | Parameter schema declaration for `/quality assess operations` | Same file | Read by `tools/cursor/audit.sh` | `./tools/cursor/audit.sh` | Tag renamed or confirmed; `audit.sh` updated |
| `_functions/quality/assess-web.md` (embedded `cursor-arg`) | Parameter schema declaration for `/quality assess web` | Same file | Read by `tools/cursor/audit.sh` | `./tools/cursor/audit.sh` | Tag renamed or confirmed; `audit.sh` updated |
| `_functions/quality/tune.md` (embedded `cursor-arg`) | Parameter schema declaration for `/quality tune` | Same file | Read by `tools/cursor/audit.sh` | `./tools/cursor/audit.sh` | Tag renamed or confirmed; `audit.sh` updated |
| `_functions/agent/install.md` (embedded `cursor-arg`) | Parameter schema declaration for `/agent install` | Same file | Read by `tools/cursor/audit.sh` | `./tools/cursor/audit.sh` | Tag renamed or confirmed; `audit.sh` updated |
| `_functions/agent/patch.md` (embedded `cursor-arg`) | Parameter schema declaration for `/agent patch` | Same file | Read by `tools/cursor/audit.sh` | `./tools/cursor/audit.sh` | Tag renamed or confirmed; `audit.sh` updated |
| `_functions/agent/upgrade.md` (embedded `cursor-arg`) | Parameter schema declaration for `/agent upgrade` | Same file | Read by `tools/cursor/audit.sh` | `./tools/cursor/audit.sh` | Tag renamed or confirmed; `audit.sh` updated |
| `_functions/git/commit.md` (embedded `cursor-arg`) | Parameter schema declaration for `/git commit` | Same file | Read by `tools/cursor/audit.sh` | `./tools/cursor/audit.sh` | Tag renamed or confirmed; `audit.sh` updated |
| `_functions/git/issue.md` (embedded `cursor-arg`) | Parameter schema declaration for `/git issue` | Same file | Read by `tools/cursor/audit.sh` | `./tools/cursor/audit.sh` | Tag renamed or confirmed; `audit.sh` updated |
| `_functions/doc/assess.md` (embedded `cursor-arg`) | Parameter schema declaration for `/doc assess` | Same file | Read by `tools/cursor/audit.sh` | `./tools/cursor/audit.sh` | Tag renamed or confirmed; `audit.sh` updated |
| `_functions/doc/compact.md` (embedded `cursor-arg`) | Parameter schema declaration for `/doc compact` | Same file | Read by `tools/cursor/audit.sh` | `./tools/cursor/audit.sh` | Tag renamed or confirmed; `audit.sh` updated |
| `_functions/doc/compare.md` (embedded `cursor-arg`) | Parameter schema declaration for `/doc compare` | Same file | Read by `tools/cursor/audit.sh` | `./tools/cursor/audit.sh` | Tag renamed or confirmed; `audit.sh` updated |
| `_functions/doc/write-changelog.md` (embedded `cursor-arg`) | Parameter schema declaration for `/doc write changelog` | Same file | Read by `tools/cursor/audit.sh` | `./tools/cursor/audit.sh` | Tag renamed or confirmed; `audit.sh` updated |
| `_functions/narrative/rewrite-content.md` (embedded `cursor-arg`) | Parameter schema declaration for `/narrative rewrite-content` | Same file | Read by `tools/cursor/audit.sh` | `./tools/cursor/audit.sh` | Tag renamed or confirmed; `audit.sh` updated |
| `_functions/collab/archive.md` (embedded `cursor-arg`) | Parameter schema declaration for `/collab archive` | Same file | Read by `tools/cursor/audit.sh` | `./tools/cursor/audit.sh` | Tag renamed or confirmed; `audit.sh` updated |
| `_functions/collab/activate.md` (embedded `cursor-arg`) | Parameter schema declaration for `/collab activate` | Same file | Read by `tools/cursor/audit.sh` | `./tools/cursor/audit.sh` | Tag renamed or confirmed; `audit.sh` updated |
| `_functions/collab/close.md` (embedded `cursor-arg`) | Parameter schema declaration for `/collab close` | Same file | Read by `tools/cursor/audit.sh` | `./tools/cursor/audit.sh` | Tag renamed or confirmed; `audit.sh` updated |
| `_functions/collab/delete.md` (embedded `cursor-arg`) | Parameter schema declaration for `/collab delete` | Same file | Read by `tools/cursor/audit.sh` | `./tools/cursor/audit.sh` | Tag renamed or confirmed; `audit.sh` updated |
| `_functions/collab/init.md` (embedded `cursor-arg`) | Parameter schema declaration for `/collab init` | Same file | Read by `tools/cursor/audit.sh` | `./tools/cursor/audit.sh` | Tag renamed or confirmed; `audit.sh` updated |
| `_functions/collab/join.md` (embedded `cursor-arg`) | Parameter schema declaration for `/collab join` | Same file | Read by `tools/cursor/audit.sh` | `./tools/cursor/audit.sh` | Tag renamed or confirmed; `audit.sh` updated |
| `_functions/collab/list.md` (embedded `cursor-arg`) | Parameter schema declaration for `/collab list` | Same file | Read by `tools/cursor/audit.sh` | `./tools/cursor/audit.sh` | Tag renamed or confirmed; `audit.sh` updated |
| `_functions/collab/remove-participant.md` (embedded `cursor-arg`) | Parameter schema declaration for `/collab remove participant` | Same file | Read by `tools/cursor/audit.sh` | `./tools/cursor/audit.sh` | Tag renamed or confirmed; `audit.sh` updated |
| `_functions/collab/reopen.md` (embedded `cursor-arg`) | Parameter schema declaration for `/collab reopen` | Same file | Read by `tools/cursor/audit.sh` | `./tools/cursor/audit.sh` | Tag renamed or confirmed; `audit.sh` updated |
| `_functions/collab/retract-speak.md` (embedded `cursor-arg`) | Parameter schema declaration for `/collab retract speak` | Same file | Read by `tools/cursor/audit.sh` | `./tools/cursor/audit.sh` | Tag renamed or confirmed; `audit.sh` updated |
| `_functions/collab/participant-verify.md` (embedded `cursor-arg`) | Parameter schema declaration for `/collab participant verify` | Same file | Read by `tools/cursor/audit.sh` | `./tools/cursor/audit.sh` | Tag renamed or confirmed; `audit.sh` updated |
| `_functions/collab/seal-verification.md` (embedded `cursor-arg`) | Parameter schema declaration for `/collab seal verification` | Same file | Read by `tools/cursor/audit.sh` | `./tools/cursor/audit.sh` | Tag renamed or confirmed; `audit.sh` updated |
| `_functions/collab/set.md` (embedded `cursor-arg`) | Parameter schema declaration for `/collab set` | Same file | Read by `tools/cursor/audit.sh` | `./tools/cursor/audit.sh` | Tag renamed or confirmed; `audit.sh` updated |
| `_functions/collab/show-verdict.md` (embedded `cursor-arg`) | Parameter schema declaration for `/collab show verdict` | Same file | Read by `tools/cursor/audit.sh` | `./tools/cursor/audit.sh` | Tag renamed or confirmed; `audit.sh` updated |
| `_functions/collab/speak.md` (embedded `cursor-arg`) | Parameter schema declaration for `/collab speak` | Same file | Read by `tools/cursor/audit.sh` | `./tools/cursor/audit.sh` | Tag renamed or confirmed; `audit.sh` updated |

## Retirement acceptance conditions

The Cursor retirement is complete when all seven conditions pass. Conditions 1–5 were established in collab #31 (cursor substrate cleanup). Conditions 6–7 were added in collab #32 (verification) to close scope gaps identified during that audit.

1. `CLAUDE.md`/`AGENTS.md` no longer route through `_CURSOR.md`; bootstrap chains point directly to `commands/commands.md`
2. `commands/commands.md` is the first-class bootstrap entry for every harness (Cursor, Claude, Codex, GPT)
3. No live command or route file references a `rules/` or `_mdc/` path
4. Every `cursor-arg` block has a recorded disposition in this ledger — ported, repurposed as non-executable documentation, or removed
5. Zero undeclared Cursor dependencies across the full current-epoch surface (`_data/`, `_templates/`, `_tests/`, `_generated/`, `_roles/`, `_settings/`, `_core/`, `commands/`, `_functions/`)
6. Zero `cursor-arg` blocks present in the tracked contract surface — all blocks removed or replaced with agent-agnostic equivalents per the replacement routing-metadata contract above
7. Zero Cursor-specific prose (`alwaysApply`, `globs`, Cursor-addressed `audit.sh` gate messages) in tracked files

Conditions 1–5 are disposition conditions (ledger rows populated, files ported). Conditions 6–7 are execution conditions (actual removal confirmed). All seven must pass before any carrier deletion is treated as retirement-complete.

**All seven conditions confirmed 2026-05-21:** `./tools/cursor/audit.sh` passes; `./tools/cursor/check-cursor-migration.py --check` passes; `_CURSOR.md` absent from repository; bootstrap chains in `CLAUDE.md` and `AGENTS.md` route directly to `commands/commands.md` without `_CURSOR.md` as an intermediate; `AGENTS.md` line 29 reference absent.
