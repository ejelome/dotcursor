# Collab message formatting

Format-preservation policy for moderator and other user-authored prose appended to collab records under `/collab speak`. The key invariant: a formatting pass must never change what was said, only how it is presented.

## Trigger

**Slash:** (reference only — not an invocable route)
**Prose dispatch:** (reference only — not an invocable route)
**Search phrases:** collab format, collab message formatting, format-preservation, captured prose formatting, moderator text formatting

## When the policy applies

- Apply only when user-authored prose is appended to `$HOME/.collabs/*/records/**/*.md`.
- Apply after `/collab speak` captures moderator (or other human-supplied) text.
- Apply when the user asks to record a statement in a collaboration file.

## Behavior

**Triggers:** `auto-collab-format`, `auto-collab-message-format`, `collab speak`, `$HOME/.collabs/*/records/`, collaboration record, post-send formatting, captured prose

1. Run the formatting pass in the same turn after the contribution is appended.
2. **Default (required):** preserve the **exact substance** of what was captured. A formatting pass is **not** permission to rephrase, polish, "improve," answer a question, or replace the author's text with a summary or consensus. Doing that is a failed application of this policy, not a helpful default.
3. Limit structure-only edits to bullets, labels (built only from the captured words), line breaks, spacing, and obvious spelling mistakes when the misspelling is clearly accidental.
4. Never add facts, decisions, scope, answers, summaries, lead-ins, or new framing.
5. Never rewrite deliberate wording, informal spelling, or chosen phrasing; never substitute a cleaner sentence for the same idea.
6. Skip the formatting pass when the user says `verbatim only`, `exactly as written`, or `do not rephrase`.

## Examples

Example: A moderator message with several related points may become bullets or short labeled lines, but every line and label must be traceable to the captured words. If you would otherwise write a "consensus" or "summary" in the moderator's name, do not: put that in your own turn or a section the moderator points to.

## References

- [speak.md](speak.md) — `/collab speak` route that invokes this formatting policy.
- [_moderator-polish.md](_moderator-polish.md) — structure-only polish transform applied to moderator contributions after append.
- [style-guide](../../_core/style-guide.md) — imperative instruction shape and LLM-consumed document constraints.
- [document-standard](../../_core/document-standard.md) — rule template and document structure.
- Canonical source is active in this file.
