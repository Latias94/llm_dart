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
- [TODO.md](TODO.md)
  - Open work items for this planning phase.
- [MILESTONES.md](MILESTONES.md)
  - Milestones and acceptance criteria for this planning phase.
