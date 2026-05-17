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

See [GOAL.md](GOAL.md) for the canonical goal text and completion definition.

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

- [GOAL.md](GOAL.md)
  - Canonical goal text, completion definition, non-goals, and decision rules.
- [00-priority-map.md](00-priority-map.md)
  - Ordered second-wave priorities, stop conditions, and non-goals.
- [01-architecture-blueprint.md](01-architecture-blueprint.md)
  - Source-versus-reference blueprint for the next wave after the completed
    provider/runtime stream boundary.
- [02-modern-surface-audit.md](02-modern-surface-audit.md)
  - Audit of docs and examples that still lead with provider-facing or
    compatibility APIs.
- [03-root-core-compatibility-inventory.md](03-root-core-compatibility-inventory.md)
  - Root and `llm_dart_core` compatibility surface classification with
    blockers and review windows.
- [04-provider-helper-duplication-inventory.md](04-provider-helper-duplication-inventory.md)
  - Provider helper duplication inventory and provider-utils extraction
    decision.
- [05-goal-completion-audit.md](05-goal-completion-audit.md)
  - Prompt-to-artifact completion audit for the canonical Wave 2 goal.
- [06-modern-surface-docs-cleanup.md](06-modern-surface-docs-cleanup.md)
  - Docs-only cleanup that moves default provider examples to `messages:` while
    preserving provider-contract `PromptMessage` usage for advanced material.
- [07-release-posture-decision-gate.md](07-release-posture-decision-gate.md)
  - Maintainer decision gate that closes the remaining publish versus
    non-publish evidence gap before scheduling further refactors.
- [08-consumer-smoke-modern-surface.md](08-consumer-smoke-modern-surface.md)
  - Small implementation milestone that removes provider-prompt usage from the
    split-package consumer smoke program.
- [MILESTONES.md](MILESTONES.md)
  - Milestones and acceptance criteria.
- [TODO.md](TODO.md)
  - Executable checklist for the workstream.
