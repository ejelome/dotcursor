# Advisory Coverage Policy

Documents the namespace coverage decision and denylist extension
paths. Both lists live in `data/command-advisory-policy.json` and are
read by `tools/command-system/command-advisories.py` at validation
time.

## Namespace coverage decision

`data/command-advisory-policy.json` → `requiredNamespaces` declares
which namespaces must have a corresponding advisory file under
`data/advisories/`. The required set is `["agent", "collab",
"narrative", "quality"]`.

The following namespaces are explicitly exempt from advisory coverage.
Exemption reasons are authoritative in
`data/command-advisory-policy.json` → `namespaceCoverageExemptions`:

| Namespace | Advisory file | Decision | Reason |
|---|---|---|---|
| `doc` | none | exempt | Documentation rewrite routes are artifact-specific and intentionally exempt from caller recommendations. |
| `git` | none | exempt | Git workflow routes depend on repository and issue state, so caller recommendations remain policy-exempt. |
| `test` | none | exempt | Test harness dispatch is a maintainer QA surface and remains policy-exempt from caller recommendations. |

To add a namespace to required coverage: add it to `requiredNamespaces`
in `data/command-advisory-policy.json` and create
`data/advisories/<namespace>.json` conforming to
`data/command-advisory.schema.json`.

To add an explicit exemption: add a `"<namespace>": "<reason>"` entry
to `namespaceCoverageExemptions` in `data/command-advisory-policy.json`.

## Model/harness leakage denylist

`data/command-advisory-policy.json` → `modelOrHarnessLeakageTerms`
lists vocabulary tokens whose presence in advisory content signals a
model- or harness-specific leak. The current set is `["claude",
"codex", "gpt", "haiku", "opus", "sonnet"]`.

To add a new model family token: add the lowercase base name to
`modelOrHarnessLeakageTerms` in `data/command-advisory-policy.json`.

**Extension rule:** Tokens must be lowercase base names (no version
suffixes, no punctuation). The checker normalizes to lowercase before
matching; adding `Claude` or `Claude-3` is redundant — add `claude`
only.
