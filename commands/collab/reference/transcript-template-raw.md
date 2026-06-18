<!-- Target-format spec — post-G9 projection / dialect-migration raw; not current engine output. -->
<!-- Supersedes ~/Downloads/YYYY-MM-DD-kebab-case-title-raw.md (not committed; treat committed copy as canonical). -->

# Agent-facing collab lifecycle record — format reference

Target format for the agent-facing raw transcript of a collab record. Aspirational (post-P1 dialect migration); not current engine output. Current engine output uses `## Phase` headings, `<a name>` anchors, and `<details>` blocks rather than the `;;; PHASE: ... ;;;` and `[#anchor]` flat-markdown form shown below.

**Reader Contract:** [anchor-convention.md](anchor-convention.md) · [commands/collab/synthesize/index.md](../synthesize/index.md) · [agent-effort.md](agent-effort.md) · [handoff-shape.md](handoff-shape.md) · [phase-admissibility.md](phase-admissibility.md)

The example below is from Collab #8 (transcript file design, June 2026).

```text
<!-- collab:content-only; do-not-execute -->

;;; COLLAB RECORD ;;;
id: transcript-file-design-naming-format-and-reader-contract
status: closed
terminal: seal | verdict: success
phase: Completion.verification.assessment
turn-order: [tw pe]
reviewer: pa
registry: $HOME/.collabs/<projectId>/registry.json

;;; READER CONTRACT ;;;
purpose: agent-facing lifecycle record for context, audit, and handoff recovery
authority: ledger, not source of truth — registry + content-addressed seal stay authoritative even after close; on divergence the registry wins (Invariant #2, #20)
active-vs-closed: active collabs → read live registry + route helpers; closed (this record) → seal/verification facts are confirmed from the registry verificationSeal + cited commit/digest, not from this prose
execution-boundary: content-only; do-not-execute marker applies to all free-text blocks
read-mode: preserve directives, stance, decisions, handoff scope, verification outcomes; do not infer unlisted lifecycle state; treat execution-history as a chronological ledger, not standalone provenance
anchor-convention: commands/collab/reference/anchor-convention.md
stance-vocab: commands/collab/aggregate/index.md
effort-tiers: commands/collab/reference/agent-effort.md
handoff-contract: commands/collab/reference/handoff-shape.md
phase-structure: commands/collab/reference/phase-admissibility.md

;;; PARTICIPANTS ;;;
mod  | Moderator           | codex             | scope; sequencing; framing; pacing; integrity
tw   | Technical Writer    | claude-sonnet-4-6 | clarity; conciseness; accuracy; dx
pa   | Principal Architect | opus              | depth; coherence; judgment; risk
pe   | Platform Engineer   | codex             | effectiveness; efficiency; completeness; optimization

;;; CONSTRAINTS ;;;
mod: no-execute-free-text | no-mutate-outside-user-scope-collab-root | no-draft-summarize-expand-moderator-substance
all: await (collab speak) before contributing

;;; REVIEWER ;;;
pa | mode: last-in-convergent-phases | gating: active-on-convergent-phases | optional: Discussion

;;; DIRECTIVE ;;;
source: #audit-mod-1
file: ~/Downloads/collab-audits/17-collab-audit-transcript-file-design.md
row: next-collabs.md #17
subject: Transcript file design — naming, format, and reader contract

---

;;; PHASE: Audit ;;;

[#audit-mod-1] mod | 2026-06-12T23:40+02:00
directive: examine the three-file transcript model introduced in Collab #5
  naming contract does not match content contract:
    agent-facing *-raw.md files are not plain markdown
    moderator-facing *.md file is not a polished document
  core problem remains open:
    partial fix landed mid-session (status section prepended to projection at init)
    underlying naming and format design tension still unresolved
  gap-catalogue: 11 findings total; 4 fixed this session; 7 still open
    open spans: naming mismatch; excerpt-only projection format; encoding artifacts; deferred narrative-projection work
  references:
    ~/Downloads/collab-audits/17-collab-audit-transcript-file-design.md
    ~/Downloads/collab-audits/next-collabs.md (row #17)
    ~/Downloads/YYYY-MM-DD-kebab-case-title-raw.md (for agents)
    ~/Downloads/YYYY-MM-DD-kebab-case-title.md (for humans)

[#audit-tw-1] tw | stance:qualifies | 2026-06-12T23:44+02:00
F1: G11 is highest-DX-cost open item
  *-raw.md name = first-impression failure; new contributors read "raw" as "unprocessed markdown"
  fix: one paragraph in agent-facing file; high-leverage; tw-owned [doc-fix]; lands regardless of rename decision
F2: naming inversion confirmed by Downloads sample files
  actual distinction: lifecycle-vs-projection (provenance); not raw-vs-polished (formatting)
  both names fail on first encounter
  option-C (keep *-raw.md + update docs) = lowest blast radius
  option-A (*-lifecycle.md) = accurate; incurs migration cost
  rec: charter G1/G2 as core deliverable — design decision; not a solo fix
F3: G9 status needs re-assessment before Action Plan
  human-facing sample (YYYY-MM-DD-kebab-case-title.md) shows narrative prose with per-phase summaries and blockquote excerpts
  G9 describes "excerpt table" — mismatch; pe must confirm against live aggregator output before G9 carried as open backlog
F4: G7/G8 scope
  HTML entities in dp excerpts + duplicate anchor assignment = speak-render or aggregate bugs; pe-owned; no tw action
recs:
  land G11 as [doc-fix] in this collab
  charter G1/G2 naming decision as core deliverable
  confirm G9 status before backlog placement

[#audit-pe-1] pe | stance:qualifies | 2026-06-12T23:49+02:00
F1: G7/G8 are PE-owned correctness bugs; not naming decisions
  G7: escaping/decoding boundary failure — entity-encoded contribution text entering plain moderator projection
  G8: identity generation failure — projection rows must not duplicate lifecycle anchors when role speaks twice in Discussion
  both: low-blast-radius engine defects; likely in excerpt extraction/rendering or aggregate row identity
  rec: charter before broader narrative work
F2: G9 should be reclassified; not deferred as from-scratch feature
  active projection at observedRevision 448 still renders excerpt table
  supplied sample already renders narrative phase synthesis
  G9 = path-consistency problem first; identify which projection path produced narrative sample before chartering large feature
F3: G10 is platform risk
  atomic temp-file/complete-or-abort = correctness gate for derived projection plane
  non-atomic aggregate write → plausible-but-false moderator document
  put G10 in PE scope with tests

[#audit-pa-1] pa | stance:qualifies | reviewer | 2026-06-12T23:56+02:00
effort-override: xhigh — coherence-risk: prior Audit findings leave G9 classed as both an unbuilt feature and an already-rendered path-bug because the moderator-facing narrative sample's provenance is unverified
R1-blocking: resolve G9 provenance before scoping
  audit §11 step 5 presupposes G9 is unbuilt; premise unverified against live engine output
  Invariant #4: disk-state authority — don't trust sample as engine output; carry as [verify-precondition]; gates Action Plan
R2: split the plan
  land-now (bounded, testable): G7 G8 G10 G11
  charter-separately (design/large): G1/G2 naming; G9 narrative
  mixing high-blast-radius rename + unbuilt feature with small fixes → partial-satisfies close (Invariants #17/#18/#19)
R3: G10 is highest severity
  non-atomic aggregate write → plausible-but-false moderator document; silent corruption of orientation plane (Invariant #2)
  outranks naming; loop-check: collab-#5 carry-forward (§12)
R4: naming — measure; not vibe
  count §8.1 references (anchors; registry; fixtures; migration) before choosing Option A vs C
  bounded → A; sprawling → C + provenance banner (subsumes G11)
verdict: land G7/G8/G10/G11 here with atomicity tests; carry G1/G2 as blast-radius-gated decision; defer G9 pending R1

---

;;; PHASE: Discussion ;;;

[#discussion-mod-1] mod | 2026-06-12T23:58+02:00
directive: retire excerpt and full-body
  projection has written excerpt on mod's transcript — mod cannot understand full context of participant discussion
  full-body doesn't make sense anymore — agents can dump data to other agents without bothering human (mod); mod won't read it

[#discussion-tw-1] tw | stance:qualifies | 2026-06-13T00:00+02:00
issue-A: excerpt truncates projection context (immediate pain)
  projection renders ~200-char excerpts; mod loses discussion thread
  fix: aggregator renders full contribution text; small aggregate change; no raw transcript touch
issue-B: excerpt/full-body split adds raw-transcript overhead
  split designed for human readability inside raw transcript
  if agents write raw + mod reads only projection: split adds friction without benefit
  retiring = flat full-content contributions; simpler write; simpler rendering contract
separation: issue-A = aggregate fix; issue-B = speak-render + speak/index.md change; A can land without touching raw
connection-to-G1: retiring HTML scaffolding from raw transcript (issue-B) also closes G1 root cause
  flat-markdown raw would actually match what "raw" implies
  issue-B = design-level decision worth chartering alongside G1/G2
rec:
  issue-A: retire excerpt from projection — pe-owned; lands in this collab
  issue-B: retire excerpt/full-body + HTML scaffolding — charter alongside G1/G2

[#discussion-pe-1] pe | stance:qualifies | 2026-06-13T00:00+02:00
platform-constraint: do not collapse raw-transcript contract in same item as projection readability fix
near-term-rec: retire truncated excerpts from moderator projection first; aggregate/projection change only
guard-warning: content-only; do-not-execute is execution-boundary marker; not presentation scaffolding
  flattening collapsible scaffolding is viable; removing content-only boundary is not
migration-scope: retiring excerpt/full-body from speak-render touches contribution storage; budget policy; transcript readers;
  aggregate source extraction; rewrite/retract; historical compatibility; chartered design deliverable not quick cleanup
actionable-split:
  land projection-full-content first
  charter raw flat-markdown migration separately with compatibility tests

[#discussion-pa-1] pa | stance:qualifies | 2026-06-13T00:02+02:00
converge-split: agree with tw + pe on issue-A/issue-B split; add three constraints
constraint-1: guard must survive flattening; collapsible scaffolding may go; execution-boundary guard must not
constraint-2: issue-A data model — aggregator must concatenate excerpt + full-body; not just widen excerpt column
  un-truncating excerpt column still omits full-body text; mod lost context would not actually return
constraint-3: co-locate G10 with issue-A — both touch aggregate write path; shipping larger projection through non-atomic writer enlarges blast radius
scope-flag: issue-B = NEW scope; charter as own (collab init) alongside G1/G2 naming decision; issue-A + G10 stay in this collab

[#discussion-mod-2] mod | 2026-06-13T00:29+02:00
directive: aggregate does not synthesize — it copies
  mod must read every participant's full response per round; defeats the purpose of multiple agents
  want per-phase synthesis: one condensed view of where each role stands; what converged; what's still open
  not a reformatted dump of the same walls of text
  this should be a deliverable from this collab

[#discussion-tw-2] tw | stance:converges | 2026-06-13T00:30+02:00
diagnosis: mod correct — aggregate is a renderer not a reasoner; synthesis requires agent judgment
  full-content in projection only removes truncation; does not remove reading load
synthesis-spec:
  per-role stance (converges/qualifies/dissents + one-line summary)
  convergence list: what all roles agreed on this round
  open items: what's unresolved or disputed
  agent-authored; once per Discussion round; written to projection as synthesis block above per-contribution detail
  mod reads synthesis first; detail is for follow-up; not primary consumption
scope: new scope — not in G1–G11; charter as new collab
  tw owns output format spec; pe owns trigger mechanics
rec:
  [doc-fix] capture synthesis output contract; charter implementation as new (collab init)

[#discussion-pe-2] pe | stance:qualifies | 2026-06-13T00:37+02:00
position: synthesis valid scope; must not become hidden intelligence inside deterministic aggregate
  aggregate stays mechanical: collect records; render projection; write atomically
  judgment needs explicit agent-authored synthesis step with provenance
contract-to-deliver-in-this-collab:
  inputs: all visible contributions in current phase round
  output: per-role stance summary; convergence list; open items; action-plan deltas
  placement: synthesis block above contribution detail in moderator projection
  provenance: author role/agent + observed registry revision
  failure-mode: absent or stale synthesis labeled; not silently reused
implementation: chartered separately — changes lifecycle semantics: trigger timing; author role; stale-read protection; reviewer interaction; rewrite/retract; storage location

[#discussion-pa-2] pa | stance:qualifies | reviewer | 2026-06-13T00:38+02:00
effort-override: high — coherence-risk: round-2 "synthesis" is being chartered as net-new scope, but it is the specification of G9 (narrative projection), which risks a duplicate charter and silently re-opens my Audit R1
correction-1: synthesis is not new scope — it is G9's spec; resolves Audit R1
  tw + pe call per-phase synthesis "not in G1–G11" but G9 IS the narrative-projection gap; mod-2 supplied its contract
  answers R1: moderator-facing sample was hand-authored target not aggregator output; G9 = feature not path-bug
  do not charter separate synthesis-impl collab; fold into G9 charter; one deliverable
correction-2: guard against charter-proliferation
  collapse synthesis-impl into G9 (same projection plane)
  keep issue-B (agent/raw plane) and G1/G2 (filename interface) separate: different planes; different blast radius
  net: one projection charter; not three
correction-3: reuse existing stale guard — "absent/stale synthesis labeled" = observed-revision stale-write guard; reuse; don't invent new provenance
agree: synthesis/G9 output contract lands here as [doc-fix]; implementation goes to consolidated G9 charter

---

;;; PHASE: Conclusion ;;;

[#conclusion-tw-1] tw | stance:qualifies | 2026-06-13T00:48+02:00
directive: "The gap catalogue records eleven findings in total, four fixed this session and seven still open, spanning the naming mismatch, the excerpt-only projection format, encoding artifacts, and deferred narrative-projection work."
action-plan: partially satisfies — G1/G2 naming and G9 synthesis implementation deferred to charter collabs
land-in-this-collab:
  issue-A: retire truncated excerpts; aggregator renders full contribution bodies (excerpt + full-body concatenated per #discussion-pa-1)
  G10: atomic temp-file write + complete-or-abort tests; co-located with issue-A
  G7: fix HTML entities in dp excerpts (speak-render boundary)
  G8: fix duplicate Discussion anchor (speak-render or aggregate anchor identity)
  G11 [doc-fix]: "raw = provenance not formatting" in aggregate/index.md or agent-model.md
  synthesis-spec [doc-fix]: output contract in 19-collab-audit-agent-authored-synthesis.md; next-collabs.md row #19 added
chartered-separately:
  issue-B (raw transcript migration): different plane; migration contract required
  G1/G2 (naming decision): blast-radius-gated; measure §8.1 reference count before deciding
  G9 synthesis implementation: row #19
directive-gap: G1/G2 and G9 implementation remain open; deliberate deferrals per Audit pa R2

[#conclusion-pe-1] pe | stance:qualifies | 2026-06-13T00:59+02:00
directive: "…eleven findings in total, four fixed this session and seven still open…"
action-plan: partially satisfies — bounded projection correctness fixes can land here; naming migration and synthesis implementation remain charter-class work
land-in-this-collab: full-content projection rendering; G10 atomic writes; G7 HTML entity handling; G8 anchor identity; G11 documentation
synthesis-position: not an aggregate enhancement; delivered value = synthesis contract + row #19
G1/G2-position: remain separate; correct next step = reference-count gate not preference decision
directive-gap: action plan does not fully close G1/G2 or G9 implementation; acceptable because Conclusion names deferrals and preserves concrete follow-up rows

[#conclusion-pa-1] pa | stance:converges | reviewer | 2026-06-13T01:05+02:00
effort-override: xhigh — coherence-risk: deferrals risk mis-encoding as [defer] or phantom precondition items at seal, making the Action Plan internally inconsistent with Invariants #18/#19
directive: "…eleven findings in total, four fixed this session and seven still open…"
action-plan: partially satisfies — concur with tw + pe
directive-test: partial satisfies correctly answers a directive describing 11 findings rather than mandating all fixed
  valid only because seven open items are named and charter-tracked; not silently closed
audit-confirmed: tw + pe both bucket land-now vs charter; name every deferral; honor Audit R2/R3/R4
  R1 discharged: G9 sample was hand-authored (#discussion-pa-2); no provenance precondition survives; do not carry phantom item
precedent: Invariant #18 rejects [defer]; Invariant #19 forbids silent scope-close at seal
  issue-B; G1/G2; G9-implementation must be charter rows (next-collabs.md #19 et al.); NOT Action Plan items
land-now tags: issue-A/G10/G7/G8 [execute]; G11 + synthesis-spec [doc-fix]; one [verify-objective] for suite-green
loop-check: G10 is collab-#5 carry-forward (Audit R3 §12); must land HERE with atomicity tests; re-deferring = third loop
converge: the loop closes only what it built

---

;;; PHASE: Action Plan ;;;

[#action-plan-tw-1] tw | 2026-06-13T01:08+02:00
- [x] [doc-fix] synthesis output contract — specified in 19-collab-audit-agent-authored-synthesis.md; next-collabs.md row #19 added
- [x] [doc-fix] G11 — "raw = provenance not formatting" note in commands/collab/aggregate/index.md or commands/collab/reference/agent-model.md

[#action-plan-pe-1] pe | 2026-06-13T01:09+02:00
- [x] [execute] G10 — temp-file + atomic replace for aggregate output; complete-or-abort tests; co-locate with issue-A
- [x] [execute] issue-A — render excerpt + full-body concatenated from contribution store; column widening alone insufficient
- [x] [execute] G8 — make repeated-role anchors unique and stable within same phase
- [x] [execute] G7 — fix entity handling at speak-render or extract-render boundary; plain-text projection must not display HTML entities
- [x] [verify-objective] run ./platform/tooling/audit.sh + ./tests/run.sh + new G10 atomicity coverage after PE execution items complete

---

;;; PHASE: Handoff ;;;

[#handoff-tw-1] tw | 2026-06-13T01:10+02:00
effort-override: low — implementation-density: single doc-fix (G11), one paragraph in one existing file; no new code or test changes
items:
  [doc-fix] G11 — "raw = provenance not formatting" note in commands/collab/aggregate/index.md or commands/collab/reference/agent-model.md
writeScope:
  commands/collab/aggregate/index.md
  commands/collab/reference/agent-model.md
validationCommands:
  ["./platform/tooling/audit.sh"]

[#handoff-pe-1] pe | 2026-06-13T01:12+02:00
effort-override: xhigh — implementation-density: multiple runtime changes plus atomicity tests; ordering and failure-mode correctness matter
items:
  [execute] G10 — temp-file + atomic replace for aggregate output; with complete-or-abort coverage
  [execute] issue-A — render full contribution bodies by concatenating excerpt + full-body from contribution store
  [execute] G8 — make repeated-role anchors unique and stable within same phase
  [execute] G7 — fix entity handling; plain-text moderator projection must not display HTML entities
  [verify-objective] run repo validation suite after execution items complete
writeScope:
  commands/collab/engine/registry.py
  commands/collab/aggregate/index.md
  commands/collab/reference/invariants.md
  tests/
validationCommands:
  ["./platform/tooling/audit.sh", "./tests/run.sh"]

---

;;; PHASE: Completion ;;;

execution-history:
  provenance: chronological ledger; authoritative seal evidence is the registry verificationSeal + commit 3778e27 (see #verify-pe)
  1. pe  | completed 2026-06-13T01:27 | validation:passed | scope:full   | paths:4
  2. tw  | completed 2026-06-13T01:28 | validation:passed | scope:scoped | paths:1
  3. pa  | sealed    2026-06-13T01:31 | verification:passed | seal        | paths:4
  4. pa  | assessed  2026-06-13T01:33 | verdict:success     | assessment  | paths:4

[#verify-tw] tw | audit:pass | remediation:none | final-audit:pass | 2026-06-13T01:28+02:00
  G11 note present in aggregate/index.md line 42; no content defects

[#verify-pe] pe | audit:pass | remediation:none | final-audit:pass | 2026-06-13T01:31+02:00
  full-body projection + entity cleanup + atomic write + anchor fix; 100 tests passed; commit:3778e27

summary:
  closed-after: completed execution for pe, tw
  validation: passed
  touched-paths-count: 4
  touched-paths:
    commands/collab/aggregate/index.md
    commands/collab/engine/registry.py
    tests/commands/collab/registry.py/full-body-block-flow.test.sh
    tests/commands/collab/registry.py/aggregate-projection-output.test.sh
```
