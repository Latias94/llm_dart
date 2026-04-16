# Deprecation Policy

## Goal

Define the repository-wide rules for deprecating and removing legacy public
surface after the architecture-heavy refactor.

## Policy Principles

### 1. Deprecate By Migration Clarity, Not By Architectural Taste

A public symbol becomes a deprecation candidate only when its replacement is
clear enough to explain in one short migration note.

If the replacement still requires a long compatibility explanation, the symbol
is probably not ready for deprecation yet.

### 2. Remove Leaves Before Trunks

Small preset helpers and narrow compatibility aliases should be removed before
the main compatibility hosts that still carry migration weight.

That means:

- remove preset provider helpers before removing root provider constructors
- remove narrow builder convenience aliases before removing `LLMBuilder`
- remove compatibility-only raw escape hatches before removing `legacy.dart`

### 3. Keep Provider-Native Value Out Of Shared Deprecation Pressure

Provider-native residual APIs should not be deprecated just because a shared
story would look cleaner without them.

Only true compatibility-era surfaces belong in this plan.

### 4. No Silent Public Removals In Patch Releases

Even though the repository is still below `1.0.0`, it should continue to act
predictably:

- patch releases may add docs, warnings, and `@Deprecated` annotations
- patch releases must not silently remove public legacy surface
- actual removals should happen only in an explicit breaking window

### 5. Deprecation Must Be Accompanied By Migration Guidance

Every newly deprecated public surface should have:

- a concrete replacement path
- updated docs or examples that show that replacement
- a changelog note
- a deprecation message that points to the replacement directly

## Status Vocabulary

This workstream uses four public postures:

| Status | Meaning |
| --- | --- |
| Stable modern | Preferred public API; not part of the legacy cleanup |
| Frozen compatibility host | Not recommended for new code, but not yet ready for deprecation |
| Soft-deprecated | Supported temporarily, but scheduled for the next explicit breaking-window review |
| Removal-candidate | Already soft-deprecated long enough, with migration guidance ready for the next breaking window |

## Release Rules

### Short-Term Releases

Short-term non-breaking releases may:

- tighten docs toward modern entrypoints
- expand warnings and deprecation annotations
- improve migration examples
- narrow what the default README teaches

Short-term non-breaking releases should not:

- remove public compatibility barrels
- remove `LLMBuilder`
- remove root provider constructors

### Next Explicit Breaking Window

The next deliberate breaking window may remove:

- preset helper aliases that are already soft-deprecated
- builder web-search helpers that are already soft-deprecated
- other narrow compatibility leaves whose replacement path is already stable

The next deliberate breaking window should usually not remove:

- `legacy.dart`
- `LLMBuilder`
- root provider constructors

unless migration guidance and user-facing examples are already complete enough
to make those removals unsurprising.

### Later Breaking Window

A later breaking window may consider removing or drastically slimming the main
compatibility trunks only if all of the following are true:

1. modern task-based recipes cover common text, streaming, tools, embedding,
   image, audio, and community-provider use cases
2. the README and examples no longer need the compatibility path to explain
   common usage
3. compatibility-only test coverage can shrink without losing product
   confidence
4. release notes explicitly announce the break

## Default Policy Outcome

The default outcome after this policy is:

- freeze the main compatibility rail
- continue documenting modern APIs first
- prepare already-deprecated leaves for the next deliberate removal window
- avoid turning "legacy cleanup" into another architecture-expansion phase
