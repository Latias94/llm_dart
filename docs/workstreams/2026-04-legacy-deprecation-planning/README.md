# Legacy Deprecation Planning

## Why This Phase Exists

The structural refactor is now in a good enough state.

The next question is no longer "how else can the repository be rearranged?"

It is:

> which remaining legacy root surfaces are still useful migration rails, which
> ones already have honest modern replacements, and how should removal happen
> without creating avoidable downstream breakage?

The repository now has:

- a modern stable root entrypoint through `package:llm_dart/ai.dart`
- focused modern provider entrypoints such as `openai.dart`, `google.dart`,
  and `anthropic.dart`
- provider-owned typed model APIs
- an explicit compatibility host through `package:llm_dart/legacy.dart`

That means deprecation can finally become deliberate instead of accidental.

## Main Questions

This phase focuses on four questions:

1. Which public legacy surfaces are still real migration infrastructure rather
   than accidental long-term commitments?
2. Which compatibility helpers already have stable replacements and should move
   into a real deprecation/removal window?
3. Which compatibility shells must stay frozen for now because the modern
   replacement story is not yet simple enough for users?
4. Which release rules should govern deprecation and removal so this repository
   stays predictable even before `1.0.0`?

## Current Working Hypothesis

The likely long-term direction is:

- keep `legacy.dart` as the explicit compatibility host for now
- remove leaf convenience aliases before removing the main compatibility host
- keep provider-native value provider-owned instead of forcing a shared
  "migration abstraction"
- treat `LLMBuilder` and root provider constructors as compatibility rails,
  not as the default modern API
- only remove major compatibility trunks after migration recipes, examples, and
  changelog guidance are in place

This phase should therefore be policy-first.

It should not start by deleting code.

## Scope

This phase should:

- inventory the remaining public legacy and compatibility-facing root surface
- classify each surface as keep, soft-deprecate, or removal-candidate
- define release-window rules for future removals
- map common migration targets onto modern APIs
- sequence deprecation so users lose narrow aliases before they lose the
  broader compatibility rail

## Non-Goals

This phase should explicitly avoid:

- reopening package-splitting or architecture-symmetry debates
- deleting provider-owned residual APIs just because they are old
- widening shared core to make migration look more uniform than it really is
- silently removing legacy public APIs without a documented break window

## Documents

- [00-legacy-surface-inventory.md](00-legacy-surface-inventory.md)
  - Inventory of the remaining legacy public surface and the current posture
    for each category.
- [01-deprecation-policy.md](01-deprecation-policy.md)
  - Repository-wide rules for deprecation status, release windows, and removal
    prerequisites.
- [02-migration-sequence.md](02-migration-sequence.md)
  - Ordered migration and deprecation sequence, from docs-first cleanup to
    eventual breaking-window removals.
- [03-removal-readiness-matrix.md](03-removal-readiness-matrix.md)
  - Concrete readiness table for the main legacy symbols and groups.
- [04-readme-and-example-audit.md](04-readme-and-example-audit.md)
  - Audit of the current root docs, package docs, and example hotspots that
    still teach the legacy path.
- [05-task-oriented-migration-recipes.md](05-task-oriented-migration-recipes.md)
  - Short migration recipes for the main old-builder jobs, with explicit
    stable versus provider-owned boundary guidance.
- [06-deprecated-preset-helper-aliases.md](06-deprecated-preset-helper-aliases.md)
  - Provider-family migration notes for the already-deprecated preset helper
    aliases that should disappear before broader compatibility trunks.
- [07-builder-web-search-replacements.md](07-builder-web-search-replacements.md)
  - Honest provider-owned replacement paths for the deprecated builder-era
    web-search helpers.
- [08-ai-helper-posture.md](08-ai-helper-posture.md)
  - Decision note for soft-deprecating `ai()` while keeping `LLMBuilder()`
    frozen as the real compatibility builder trunk.
- [09-create-provider-posture.md](09-create-provider-posture.md)
  - Decision note for keeping `createProvider(...)` frozen while treating
    `extensions` as the actual deprecated escape hatch.
- [10-breaking-window-removal-candidates.md](10-breaking-window-removal-candidates.md)
  - Proposed contents of the first conservative breaking window: what should
    be removed first, what should explicitly stay, and what belongs to later
    review.
- [11-removal-release-note-templates.md](11-removal-release-note-templates.md)
  - Reusable changelog and migration-note templates for leaf removals.
- [12-compatibility-test-retention.md](12-compatibility-test-retention.md)
  - Test-retention rules for legacy leaf removals so guardrails do not vanish
    with the APIs they protect.
- [13-wave-1-release-note-draft.md](13-wave-1-release-note-draft.md)
  - Concrete changelog and migration-note draft for the already-landed
    wave-1 leaf removals, ready to adapt into `CHANGELOG.md` if this branch
    becomes the breaking-release vehicle.
- [14-wave-1-execution-decision.md](14-wave-1-execution-decision.md)
  - Execution decision for the already-landed wave-1 removals: ship only in
    an explicit breaking release, otherwise keep them deferred off
    non-breaking release lines.
- [TODO.md](TODO.md)
  - Open work items for this planning phase.
- [MILESTONES.md](MILESTONES.md)
  - Milestones and acceptance criteria for this planning phase.

## Current Status

The workstream has now moved beyond general policy and inventory.

What is now written down:

- the remaining legacy surface inventory
- the deprecation/removal policy
- the ordered migration sequence
- the first removal-readiness matrix
- the README/example audit
- task-oriented migration recipes for common builder jobs
- family-by-family notes for already-deprecated preset helper aliases
- provider-owned replacements for deprecated builder web-search helpers
- an explicit soft-deprecation posture for `ai()`
- an explicit frozen-versus-escape-hatch posture for `createProvider(...)`
- a proposed first breaking-window removal set
- reusable release-note and migration-note templates
- explicit compatibility test-retention rules for removals
- a concrete wave-1 release-note and changelog draft for the branch-landed
  leaf-removal slice
- an explicit execution decision for whether that branch-landed wave-1 slice
  should ship now or stay deferred off non-breaking release lines

What is now also landed on this branch:

- `ai()` is now actually annotated as deprecated
- first-party executable code no longer uses `ai()`
- the shared builder web-search helpers are removed
- the deprecated OpenRouter builder search ergonomics are removed
- the deprecated preset helper aliases are removed
- `createProvider(..., extensions: ...)` is now reduced to
  `createProvider(...)`
- the deprecated `CancelToken` alias is removed

What remains open before a wider deprecation wave:

- choose a real release vehicle and version when maintainers are ready to open
  the next explicit breaking window
