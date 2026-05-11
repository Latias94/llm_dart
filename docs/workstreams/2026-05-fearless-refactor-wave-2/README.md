# Fearless Refactor Wave 2

## Why This Workstream Exists

The first fearless refactor wave split provider contracts, AI runtime,
transport, chat, Flutter adapters, provider packages, and the root facade into
clearer ownership boundaries. The alpha line is now release-ready locally, so
the next work should not reopen broad architecture debates by accident.

This workstream turns the next phase into an explicit post-alpha plan:

- finish the `0.11.0-alpha.1` release handoff
- capture alpha feedback before removing larger compatibility trunks
- keep root and `llm_dart_core` thin without breaking migration rails early
- define when a future `llm_dart_provider_utils` package is justified

## Goal

Prepare the second fearless refactor wave around evidence from the alpha line,
not package-count parity with `repo-ref/ai`.

The target posture is:

- release gates prove root and focused packages, not just the root test suite
- `legacy.dart`, `LLMBuilder`, root provider constructors, and `createProvider`
  stay explicitly classified before any removal work starts
- root `llm_dart` remains a facade and compatibility host, not a new
  implementation home
- `llm_dart_core` remains a compatibility shell unless a later breaking window
  makes its exit cheaper than keeping it
- `llm_dart_provider_utils` is extracted only after repeated provider package
  duplication proves a stable helper contract

## Scope

This workstream should:

- finish or prepare the alpha publish sequence and post-publish smoke checks
- strengthen release readiness so package-local test suites are part of the
  default gate
- define the second-wave priority order for legacy, root, core, and provider
  utility work
- keep removal candidates tied to explicit migration replacements and release
  windows
- record alpha feedback as targeted follow-up items instead of broad TODOs

## Non-Goals

This workstream should not:

- publish packages automatically from tooling
- remove `legacy.dart`
- remove `LLMBuilder`
- remove root provider constructors
- delete `llm_dart_core`
- publish `llm_dart_provider_utils` before at least two provider packages need
  the same stable helper boundary
- widen shared model or stream abstractions only to match the reference
  repository
- add new provider product features without a release or migration reason

## Success Criteria

The workstream is complete when:

- the alpha publish sequence is either executed or still blocked only on an
  explicit maintainer decision
- post-publish smoke instructions are clear and repeatable
- release readiness runs focused package tests by default
- the second-wave priority order is frozen
- deferred removals have clear blockers and earliest review windows
- `llm_dart_provider_utils` extraction criteria are written down
- no second-wave task can silently reintroduce implementation ownership into
  root or `llm_dart_core`

## Documents

- [00-priority-map.md](00-priority-map.md)
  - Ordered second-wave priorities, stop conditions, and non-goals.
- [MILESTONES.md](MILESTONES.md)
  - Milestones and acceptance criteria.
- [TODO.md](TODO.md)
  - Executable checklist for the workstream.
