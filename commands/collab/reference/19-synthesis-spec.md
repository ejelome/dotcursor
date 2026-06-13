# Agent-authored per-phase synthesis — collab audit

**Type:** Collab audit (feature specification + design catalogue)
**Authoring roles:** Technical Writer, Platform Engineer (lifecycle/correctness), Principal Architect (reviewer judgment)
**Date:** 2026-06-13
**Grounding:** `~/.cursor` at HEAD `a15cf7c` (branch `collab/2026-W24`), collab #8 record `2026-06-12-transcript-file-design-naming-format-and-reader-contract` Discussion round 2; `17-collab-audit-transcript-file-design.md` G9; collab #8 `c8/#discussion-mod-2`, `c8/#discussion-tw-2`, `c8/#discussion-pe-2`, `c8/#discussion-pa-2`.
**Status (2026-06-13):** **CLOSED — sealed success.** This audit is the charter source for collab record `2026-06-13-19-agent-authored-per-phase-synthesis`, which progressed Audit -> Discussion -> Conclusion -> Action Plan -> Handoff -> Completion and sealed `success`. The Conclusion converged (`partially satisfies`): `(collab synthesize)` replaces `(collab aggregate)` in two phases (parity first, route deletion second), the deterministic projection is kept as a lower layer, the synthesis record binds observed revision + source/contribution-store digests + anchor set with staleness on any touching mutation, `dp` retires in favour of a generative `sy` identity placed outside `projectors/`, and §10 item 2 is a `[precondition]`. **F1 satisfied (commits `057a572`, `a5b939c`):** the 18 findings in this document are now durable in the `~/.cursor` git tree at `commands/collab/reference/19-synthesis-spec.md` — Invariant #4 precondition met before the Principal Architect's verify-precondition and seal. The seal did not use a `charteredDeliverables` coverage gate; it rested on recorded execution, participant verification, and reviewer judgment. `(collab synthesize)` does not yet exist in the repo; implementation charter queued as `next-collabs.md` row #22. -> `next-collabs.md` row #19.
**Subject:** `(collab aggregate)` is a deterministic renderer — it copies, it does not synthesize. The moderator must read every participant's full response per round, which defeats the purpose of a multi-agent Discussion if the human still carries the entire reading load. This audit specifies the synthesis deliverable contract and the lifecycle constraints the implementation charter must preserve.

---

## 1. The problem the moderator named

After Discussion round 2 of collab #8, the moderator stated (`c8/#discussion-mod-2`):

> "The aggregate command does not synthesize — it copies. As moderator, I have to read every participant's full response per round, which defeats the purpose of having multiple agents if I still carry the entire reading load. I want the system to produce a per-phase synthesis: one condensed view of where each role stands, what converged, and what's still open — not a reformatted dump of the same walls of text."

The complaint names two independent problems:

1. **The renderer problem.** `(collab aggregate)` renders a table of contribution detail — structural, deterministic, no judgment. The Issue A full-content fix removes truncation but does not remove the reading load. The moderator still reads four full responses.
2. **The synthesis gap.** Producing a condensed view of role stances, convergence, and open items requires agent judgment — reading across contributions, detecting agreement and disagreement, naming what is resolved and what is not. A deterministic renderer cannot do this. It requires a separate agent-authored step.

These are different problems. Issue A (full-content projection) is an aggregate fix chartered in collab #8. Synthesis cannot be fixed by any change to the deterministic renderer.

---

## 2. Why aggregate cannot synthesize

The `aggregate` command is governed by a determinism contract (`commands/collab/aggregate/index.md`):

> "The renderer must not call generative functions, paraphrase, or introduce prose not traceable to a raw source anchor or a registry field."

Every word in the projection must trace verbatim to a raw source anchor or a registry field. Synthesis — detecting convergence, naming gaps, summarizing stance — requires reasoning across contributions. It is generative, not mechanical. This is not a limitation of the current implementation; it is the design contract.

Producing synthesis inside `aggregate` would violate that contract. The projection's authority derives from its determinism: a moderator can verify the projection against the raw record mechanically. A projection that includes agent-generated summarization paragraphs cannot make that guarantee.

**Synthesis is a different class of operation.** It requires an explicit agent-authored step with its own trigger, author role, provenance record, and stale-protection guard.

---

## 3. Relationship to G9

`17-collab-audit-transcript-file-design.md` §10 records G9:

> "G9 — Projection delivers citation index, not narrative synthesis — Open, long-term — `tw/pe/dp`"

The narrative-projection gap described at G9 and the synthesis contract the moderator specified in `c8/#discussion-mod-2` are the same deliverable seen from two angles: G9 named the missing output; `c8/#discussion-mod-2` specified its contract. They are not two separate features.

`17-collab-audit-transcript-file-design.md` §11 step 5 stated G9 "should be chartered as a new collab rather than treated as a backlog item." That charter has not been opened.

The collab #8 Principal Architect's contribution (`c8/#discussion-pa-2`) resolved the G9 provenance question raised at Audit R1: the moderator-facing sample (`~/Downloads/YYYY-MM-DD-kebab-case-title.md`) was a hand-authored target document, not aggregator output. G9 is a feature gap — an unbuilt capability — not a path-bug in the current renderer.

**Implementation guidance:** do not charter a separate synthesis-implementation collab and a G9-narrative collab. Collapse them into one projection charter — the synthesis block is the narrative output G9 always described. One deliverable, one charter.

---

## 4. PE angle: lifecycle and correctness constraints

From a platform-engineering perspective, synthesis is not just a richer projection format. It is a new lifecycle artifact: agent-authored, phase-scoped, derived from contribution records, and consumed by a deterministic renderer. The dangerous failure mode is not "no synthesis"; it is a stale, misattributed, or silently regenerated synthesis that looks authoritative.

The implementation charter should preserve these constraints:

1. **Synthesis is authored, not rendered.** `aggregate` may display a stored synthesis block, but it must not create one. Generation belongs to an explicit synthesis command or lifecycle step with an accountable author.
2. **Synthesis needs a stable unit of work.** The contract says "current phase round", but the registry does not currently expose a first-class round boundary. The charter must either add that boundary or define an explicit synthesis unit from existing anchors before implementation starts.
3. **Synthesis must be stale-safe.** The persisted record needs the observed registry revision, source phase, source contribution anchors, author role, and agent ID. Any new contribution, rewrite, retract, or phase transition that changes the source set must make the displayed synthesis stale.
4. **Projection is not storage.** The moderator projection should render synthesis, not own it. Inline projection-only synthesis would be lost on regeneration and would break the derived-file model.
5. **Registry should not become a prose store.** The registry can hold pointers, revisions, and lifecycle metadata, but the synthesis body should live in a dedicated record or typed artifact store.
6. **Contribution semantics should stay explicit.** If synthesis is stored beside contributions, it needs a distinct artifact type. It must not masquerade as a participant `speak` turn.
7. **Writes must be complete-or-absent.** Synthesis generation and projection update should follow the same atomic-write discipline recommended for G10, so a failed generation cannot leave a half-current projection or body.

Practical implementation bias: start with an explicit `(collab synthesize)` command that writes one typed synthesis artifact for the selected phase/unit, guarded by observed revision. Then let `(collab aggregate)` display the latest non-stale artifact above the contribution detail. That keeps generation, storage, and rendering separable while giving the moderator the condensed view they asked for.

---

## 5. The synthesis output contract

The following contract was converged across three collab #8 Discussion contributors (`c8/#discussion-tw-2`, `c8/#discussion-pe-2`, `c8/#discussion-pa-2`).

### 5.1 Inputs

Pinned source unit: one phase contribution round — the ordered set of visible contribution anchors in a single phase from the first contribution after the previous phase-local synthesis boundary through the last contribution included by the synthesizer.

Implementation note: until the registry exposes a first-class round number, `(collab synthesize)` must persist the explicit source anchor set. That anchor set is the source-unit identity used for placement, stale labeling, storage keys, rewrite/retract handling, and accumulation-vs-replace decisions.

### 5.2 Output block structure

The synthesis block is a structured markdown section. Heading level and exact placement within the projection are decisions for the charter collab; the content shape is fixed here.

```markdown
## [Phase] — Round [N] synthesis

**Role stances**
| Role | Stance | Summary |
|------|--------|---------|
| tw   | converges | <one-line summary of tw's position> |
| pe   | qualifies | <one-line summary of qualification> |
| pa   | qualifies | <one-line summary of pa's position> |

**Converged**
- <item 1: what all roles agreed on this round>
- <item 2>

**Open**
- <item 1: unresolved or disputed>
- <item 2>

**Action-plan deltas** _(if any)_
- <item flagged as a candidate for the Action Plan>

_Synthesized by [agent-id] at registry revision [N]. Source anchors: [anchor list]._
```

_`[N]` is an interim placeholder. Until the registry exposes a first-class round number, round identity is the persisted source-anchor set defined in §6.8. The charter collab determines the final rendered label._

### 5.3 Placement

The synthesis block appears **above** the per-contribution detail in the moderator projection. The moderator reads the synthesis block first. The per-contribution detail is there for verification and follow-up, not primary consumption.

### 5.4 Authorship and provenance

- Author role and agent ID are recorded in the synthesis block footer.
- Observed registry revision is recorded so staleness is detectable.
- Source phase/unit and source contribution anchors are recorded so the synthesis can be audited against the exact input set.
- The author role is not `aggregate` — that would violate the determinism contract. It is an agent acting in a designated synthesis capacity, separate from its participant role in the Discussion.

### 5.5 Stale-read protection

An absent or stale synthesis block is **labeled as such** in the projection — never silently omitted or silently reused from a prior round. The existing `speak-render` stale-write guard (observed-revision comparison) is the model; the synthesis step should reuse or mirror that mechanism rather than invent a new one. At minimum, stale status must be recomputed when the registry revision changes, when source anchors change, or when a referenced contribution is rewritten or retracted.

### 5.6 Failure modes

If synthesis has not yet been produced for a round, the projection renders a placeholder:

```markdown
## [Phase] — Round [N] synthesis

_Not yet produced. Run (collab synthesize) to generate._
```

If synthesis is stale (produced before the most recent contribution in the round), the projection renders:

```markdown
## [Phase] — Round [N] synthesis

_Stale — produced at revision [M]; current revision [N]. Re-run (collab synthesize) to update._
```

---

## 6. Design questions open for the charter collab

The following questions are not resolved by this audit. They are the design space the implementation charter must address. **§6.8 is the load-bearing question**: the source-unit definition is a sequencing precondition that blocks implementation items 3–8; see §7 for the full architect judgment ranking.

### 6.1 Trigger timing

When does synthesis run?
- After every contribution in a round? (automatic, but may be premature before all roles have spoken)
- After the last expected turn in a round? (requires a "round complete" lifecycle signal — none exists today)
- On explicit moderator invocation? (manual, predictable, fits the existing command surface)
- After `(collab aggregate)` is called? (piggybacks on view-refresh, but blurs the determinism boundary)

There is no "round complete" lifecycle event. The system tracks phase and turn order but not round boundaries within a phase. A manual `(collab synthesize)` invocation avoids inventing new lifecycle machinery and is the path of least resistance until a round-complete signal exists.

### 6.2 Author role

Which agent produces the synthesis?
- A designated synthesis role (a new `sy` key in the registry)?
- The moderator's agent (conflicts with the moderator boundary — moderator contributions require human-authored text)?
- Any agent acting in a synthesis capacity (role-less, agent-only)?
- The reviewer (the Principal Architect already reviews — layering synthesis on top overloads the role)?

Synthesis must not be attributed to `aggregate` (violates the determinism contract) and must not be attributed to a participant role as if it were a Discussion contribution (it is not a turn). It needs its own attribution slot.

### 6.3 Command surface

Is synthesis a new top-level command `(collab synthesize)`, a sub-command of `(collab aggregate)`, or a lifecycle hook?
- `(collab synthesize)` — explicit, self-documenting, fits the existing surface pattern.
- `(collab aggregate --synthesize)` — extends the view-refresh command, but blurs the determinism boundary.
- A lifecycle hook — automatic and hidden from the user, harder to debug and audit.

The Discussion converged on keeping `aggregate` deterministic. A separate `(collab synthesize)` command is the consistent choice.

### 6.4 Storage location

Where does synthesis content live between invocations?
- In the contribution store (as a special contribution type, extending the schema)?
- In a separate `<slug>-synthesis.json` store?
- Inline in the projection file (written directly by the synthesis command)?
- In the registry (as a phase-scoped synthesis field)?

Constraints: the projection is derived and should not be the authoritative source. The raw transcript is lifecycle-authored and synthesis is not a lifecycle operation. The registry should hold lifecycle metadata and pointers, not long-form generated prose. The contribution store currently holds only participant contributions — adding a synthesis entry requires schema extension and a distinct artifact type.

### 6.5 Reviewer interaction

Does the reviewer (Principal Architect) participate in synthesis, review it, or neither?

The reviewer currently reads the moderator projection and will see the synthesis block there. But synthesis is not a Discussion contribution, so the reviewer has no designated response path. The remediation path when the reviewer disagrees with a synthesis claim is undefined.

### 6.6 Rewrite and retract behavior

Can synthesis be rewritten after the fact? Options:
- A parallel `(collab rewrite synthesize)` command (consistent with `(collab rewrite speak)`).
- Synthesis can only be regenerated by re-running `(collab synthesize)`, overwriting the prior block.
- Retract: is a retracted synthesis preserved in audit history, as speak contributions are?

### 6.7 Multi-round accumulation vs replace

Does each round's synthesis block replace the prior one, or does the projection accumulate one synthesis block per round?
- Accumulation gives the moderator a history of how convergence evolved across rounds.
- Replace gives a single clean current view — less noisy, but loses the progression.
- A mixed model (current round prominent, prior rounds collapsed) is possible but adds complexity.

### 6.8 Source-unit identity

**Resolved (2026-06-13).** The source unit is a **phase-round**: the ordered set of visible contribution anchors in one phase selected for synthesis. Until the registry has a first-class round number, the persisted source-anchor set is authoritative; moderator contribution timing is not the identity boundary. F14 and F16 are unblocked.

Concretely: `roundStartAnchor` = anchor of the last moderator contribution before the participant contributions in question (`null` for the initial round before any moderator speaks in a phase). The synthesis artifact records `{ phase, roundStartAnchor, contributionAnchors: [...], observedRevision, authorRole, agentId }`. Stale detection triggers when any contribution added after `observedRevision` has an anchor that falls after `roundStartAnchor` in the phase sequence.

The charter collab must verify this operationalization against live Discussion contribution sequences before beginning `[execute]` items — specifically that the moderator's contribution pattern maps cleanly to the `roundStartAnchor` boundary, and that rewrites and retractions trigger stale correctly.

~~Original question: do not ship synthesis until the artifact records source anchors.~~ Superseded; source anchors are recorded per the definition above.

---

## 7. PA angle: architect judgment — coherence, sequencing, risk

§4 enumerates the lifecycle constraints; §6 enumerates the open questions. This section ranks them. The reviewer's job is to name which open question is load-bearing, what the dominant risk is, and where the charter is likely to fragment — not to re-list the design space.

**1. The load-bearing decision is the source unit (§6.8 / F14), and it is a sequencing precondition, not a release gate.** Every other part of the contract — stale detection, provenance, accumulation-vs-replace, even "what does this block summarize" — is defined in terms of "the round." Until the source unit is a defined, auditable set, *stale* has no referent and the contract is unbuildable. §6.8 recommends not shipping until the artifact records anchors; the architect call is stronger: do not *begin* the `[execute]` items until the unit is defined. It blocks items 3–8 of §10, not just the final gate.

**2. The dominant risk is a trusted-but-wrong synthesis, not a missing one — and it is the same risk class as G10.** A non-atomic aggregate write yields a plausible-but-false orientation document (collab #8 Audit R3). A synthesis block sitting *above* the evidence is a second, worse false-orientation surface: it is generative, so no mechanical check confirms the summary matches the contributions it claims to condense. The mitigations are structural, not procedural. Placement above the detail (§5.3) is not a convenience — it is the verification affordance: the moderator must be able to falsify the summary against the evidence one screen down. The stale-label (§5.5 / F6) is the integrity guard. Neither is optional, and neither can be deferred to "polish."

**3. Synthesis and review are adjacent operations on the same input set; the charter must decide whether they are one role or two (resolves the direction of F11).** Both read all visible contributions in a round and name convergence and open items. §6.2 and §6.5 circle this without resolving it. Architect call: they are different acts on the same evidence — synthesis is *descriptive* (what was said), review is *evaluative* (whether it holds). Keep them separate. Collapsing them overloads the reviewer and lets the summarizer grade its own summary. Use a non-participant synthesis author (§6.2); let reviewer dissent ride on the underlying contributions, not on the synthesis block. The moment synthesis adjudicates rather than describes, it has silently absorbed the reviewer's authority.

**4. Charter discipline: one projection charter — resist the gravity to fragment.** §9 draws the boundary; the risk is worth naming plainly. The G9 / synthesis / Issue B / G1–G2 cluster will tend to fragment into four init records that each re-derive the same shared context. Collapse synthesis into G9 (one projection charter, per `c8/#discussion-pa-2`); keep Issue B and G1/G2 out (agent/raw plane and filename interface — different blast radius). This is the converse of collab #8 Audit R2: there the discipline was to split an over-stuffed plan; here it is to refuse to over-split a coherent one. Same principle — match charter boundaries to design boundaries, not to ticket count.

**5. Seal check for collab #8.** The synthesis contract (§5) lands in collab #8 as a `[doc-fix]` spec; the implementation is chartered out. Confirm that seam holds at Conclusion: the spec is the deliverable, the feature is not, and the Action Plan must tag accordingly so collab #8 seals without a half-built capability pulling its chartered-deliverable coverage check open (Invariants #17/#19).

---

## 8. Findings catalogue

| # | Finding | Status | Owner |
|---|---------|--------|-------|
| F1 | Aggregate cannot synthesize — determinism contract prohibits generative prose | **Confirmed** | tw/pe/pa |
| F2 | Full-content projection fix (Issue A) removes truncation but not the moderator's reading load | **Confirmed** | tw |
| F3 | G9 ("projection delivers citation index, not narrative synthesis") is the same gap as the synthesis request — a feature, not a path-bug | **Confirmed** (R1 resolved) | pa |
| F4 | Synthesis output contract converged: per-role stance, convergence list, open items, action-plan deltas | **Specified** (§5 of this audit) | tw/pe |
| F5 | Provenance model converged: author role + agent ID + observed revision + source anchors | **Specified** (§5.4) | pe |
| F6 | Stale-read model converged: absent/stale is labeled, never silently omitted; mirrors speak-render guard | **Specified** (§5.5) | pa |
| F7 | Trigger timing unresolved — no "round complete" lifecycle event exists | **Open** | pe |
| F8 | Author attribution slot unresolved — synthesis is not a participant turn; needs its own registry slot | **Open** | pe/pa |
| F9 | Command surface unresolved — `(collab synthesize)` vs aggregate sub-command vs lifecycle hook | **Open** | pe |
| F10 | Storage location unresolved — contribution store extension, separate store, or registry field | **Open** | pe |
| F11 | Reviewer interaction unresolved — reviewer sees synthesis in projection but has no response path | **Open** | pa |
| F12 | Rewrite/retract semantics unresolved | **Open** | pe |
| F13 | Multi-round accumulation vs replace model unresolved | **Open** | tw/pe |
| F14 | Source-unit identity pinned to an explicit phase contribution round represented by source anchors until a first-class round number exists | **Specified** (§5.1) | pe |
| F15 | Projection-only synthesis would violate the derived-file model; synthesis needs an authoritative artifact store | **Confirmed** | pe |
| F16 | Source unit (F14) is resolved as the sequencing precondition for implementation; execute items must consume the explicit anchor set | **Specified** (§5.1) | pa |
| F17 | Dominant risk is a trusted-but-wrong synthesis (same class as G10); placement-above-detail and stale-label are the structural mitigations | **Confirmed** | pa |
| F18 | Synthesis (descriptive) and review (evaluative) are adjacent ops on the same input — keep the roles separate; resolves the direction of F11 | **Specified** (§7) | pa |

---

## 9. Scope boundary

**In this audit:** the PE lifecycle constraints (§4), the synthesis deliverable contract (§5), the design questions the charter collab must address (§6), the architect judgment (§7), and the finding catalogue (§8). The output format specified here is the `[doc-fix]` item the Technical Writer recommended in `c8/#discussion-tw-2` — a defined shape for the charter collab to build toward.

**Out of scope (chartered or deferred elsewhere):**
- Issue A (projection full-content fix) — collab #8 Action Plan.
- G10 (atomic aggregate write) — collab #8 Action Plan.
- G7/G8 (HTML entities in excerpts, duplicate anchor) — collab #8 Action Plan.
- G11 (doc-fix for "raw = provenance, not formatting") — collab #8 Action Plan.
- Issue B (retire excerpt/full-body from raw transcript) — separate charter alongside G1/G2.
- G1/G2 (naming decision: `*-raw.md` rename) — separate charter; blast-radius-gated.

**Charter boundary:** one projection charter for synthesis/G9 implementation. Do not fold Issue B (raw transcript migration) or G1/G2 (filename rename) into this charter — those touch the agent/raw plane, have different blast radius, and are governed by separate design decisions.

---

## 10. Recommended Action Plan items for the charter collab

1. `[verify-precondition]` Confirm the `aggregate` determinism contract in `commands/collab/aggregate/index.md` is enforceable at HEAD — the synthesis step must not alter the renderer or the contribution store's read contract.
2. `[precondition]` Define the synthesis source unit: first-class phase round, explicit anchor set, or another auditable boundary. This blocks items 3–8 — *stale* has no referent until the unit is defined (§7).
3. `[execute]` Implement trigger: `(collab synthesize)` as an explicit agent-invoked command, separate from `(collab aggregate)`.
4. `[execute]` Implement synthesis author slot — a non-participant, non-moderator attribution entry with author role and agent ID.
5. `[execute]` Implement synthesis storage: a typed artifact record or dedicated store for the synthesis body, with registry metadata/pointer only.
6. `[execute]` Persist source phase/unit, source contribution anchors, observed registry revision, author role, and agent ID with each synthesis artifact.
7. `[execute]` Implement stale-read protection: observed-revision and source-anchor guard mirroring the `speak-render` stale-write guard.
8. `[execute]` Implement synthesis block placement in the moderator projection — above per-contribution detail (the verification affordance, §7); absent/stale placeholder when not yet produced.
9. `[doc-fix]` Write the `(collab synthesize)` route playbook (`commands/collab/synthesize/index.md`) specifying the output contract (§5) and failure modes (§5.6).
10. `[doc-fix]` Update `commands/collab/aggregate/index.md` to explicitly state that synthesis is out of scope for `aggregate` generation — the determinism contract boundary.
11. `[verify-objective]` Suite green after implementation: `audit.sh`, `./tests/run.sh`, and new synthesis-specific tests.

---

## 11. Evidence

| Claim | Citation |
|-------|----------|
| Moderator's reading-load complaint | collab #8 raw transcript `#discussion-mod-2` |
| Aggregate determinism contract | `commands/collab/aggregate/index.md:32` — "The renderer must not call generative functions, paraphrase, or introduce prose not traceable to a raw source anchor or a registry field." |
| G9 — projection delivers citation index, not narrative synthesis | `17-collab-audit-transcript-file-design.md` §10 row G9 |
| G9 recommended for separate charter | `17-collab-audit-transcript-file-design.md` §11 step 5 |
| tw synthesis spec: per-role stance, convergence list, open items | collab #8 raw transcript `#discussion-tw-2` |
| pe synthesis contract: inputs, output, placement, provenance, failure mode | collab #8 raw transcript `#discussion-pe-2` |
| pa: synthesis is G9's spec, not new scope; collapse into one G9 charter | collab #8 raw transcript `#discussion-pa-2` |
| pa R1 resolved: moderator-facing sample was hand-authored; G9 is a feature, not a path-bug | collab #8 raw transcript `#discussion-pa-2` |
| pa: reuse observed-revision stale-write guard from speak-render | collab #8 raw transcript `#discussion-pa-2` |
| pa: trusted-but-wrong synthesis is a false-orientation surface, same risk class as G10 | collab #8 raw transcript `#audit-pa-1` (R3) |
| Invariants #17/#19: chartered-deliverable coverage at seal | `commands/collab/reference/invariants.md` Invariants #17, #19 |
| Observed-revision stale-write guard | `commands/collab/speak/index.md` — Stale-write guard note |
| Invariant #4: helpers recompute state from files, not from agent memory | `commands/collab/reference/invariants.md` Invariant #4 |
| PE lifecycle constraints: synthesis is an explicit agent-authored lifecycle step, not hidden aggregate behavior | collab #8 raw transcript `#discussion-pe-2` |
