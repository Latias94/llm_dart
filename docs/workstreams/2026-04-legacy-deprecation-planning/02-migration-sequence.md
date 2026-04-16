# Migration Sequence

## Goal

Define the practical order for moving from the current compatibility-heavy root
surface toward a smaller, more intentional legacy shell.

## Sequence Overview

The correct sequence is docs-first, leaves-first, trunks-last.

## Phase A - Make Modern Usage The Default Story

Before broader deprecation expands, the repository should make modern usage the
default thing users see first:

- prefer `package:llm_dart/ai.dart` and focused provider entrypoints in README
  examples
- prefer provider-owned typed model APIs in package docs and examples
- document capability-gated app patterns through the modern model-centric
  direction
- keep `legacy.dart` documented as the migration path, not as the default path

This phase does not require removing anything.

Its job is to reduce future surprise.

## Phase B - Finish The First Deprecation Wave

The first wave should target surfaces whose replacement path is already clear:

- preset provider helpers already marked `@Deprecated`
- deprecated builder web-search helpers
- old compatibility escape hatches that already point users toward typed
  provider options or transport-owned types

Expected outcome:

- these APIs remain available temporarily
- but they are formally treated as first removal candidates for the next
  breaking window

## Phase C - Decide The Builder Trunk Posture

`LLMBuilder` should not be deprecated by reflex.

Instead, the repository should first publish modern migration recipes for the
main old-builder jobs:

- text generation and streaming chat
- tool-calling follow-up flows
- embeddings
- image generation or editing
- audio generation or transcription
- community-provider migration cases

After that, the repository can make an honest decision:

- if the recipes are good enough, deprecate `ai()` first and then review
  whether `LLMBuilder` should also become soft-deprecated
- if the recipes are still incomplete, keep the builder trunk frozen as the
  compatibility rail and continue shrinking only leaf aliases around it

## Phase D - Execute A Deliberate Breaking Window

The first breaking window after this plan should be conservative.

It should remove the soft-deprecated leaves first:

- preset provider aliases
- deprecated builder web-search helpers
- narrow deprecated compatibility escape hatches

It should usually keep:

- `legacy.dart`
- `LLMBuilder`
- root provider constructors

unless their migration story has become genuinely simple.

## Phase E - Reevaluate The Compatibility Trunks

Only after the first breaking window lands cleanly should the repository
revisit the main compatibility trunks.

Reopen that question only when there is evidence such as:

1. docs and examples no longer need the compatibility rail
2. compatibility bug churn is low enough that keeping the trunk costs more than
   removing it
3. common user migrations can be expressed in short task-oriented recipes

If those conditions are not true, the correct action is to keep the trunk and
continue documenting the modern path around it.

## Bottom Line

The deprecation route should not behave like a purge.

It should behave like a staged product migration:

- modern by default
- compatibility explicit
- leaf aliases removed first
- main migration rail removed last, if ever
