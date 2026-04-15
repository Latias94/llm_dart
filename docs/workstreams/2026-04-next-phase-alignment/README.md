# Next-Phase Alignment

## Why This Phase Exists

The previous two workstreams already closed the largest architecture questions:

- the workspace package graph is now one-way
- the root compatibility layer is thinner and better contained
- provider-owned options and custom parts stay provider-owned
- the shared event surface is intentionally frozen below transport/UI chunks
- Flutter chat, approval, paused-state restore, and reconnect flows are now
  validated at the controller/widget level

That means the next phase should not behave like another open-ended
architecture cleanup.

The next phase should answer a narrower question:

> after the boundary work is done, which remaining differences versus
> `repo-ref/ai` are still worth productizing in `llm_dart`?

## Main Questions

This phase focuses on four questions:

1. Is `llm_dart_core` now too concentrated even though the package graph is
   healthy?
2. Which parts of the remaining streamed run gap versus `repo-ref/ai` are real
   product value rather than symmetry pressure?
3. How should the root package keep shrinking as a compatibility host without
   destabilizing current users?
4. Which future additions should stay explicitly deferred until real usage
   pressure appears?

## Current Working Hypothesis

The current package split is already close to the right long-term granularity:

- `llm_dart_core`
- `llm_dart_transport`
- `llm_dart_chat`
- `llm_dart_flutter`
- provider-owned packages
- `llm_dart_community`

The remaining worthwhile work is now more likely to be:

- feature-driven streamed orchestration improvement
- internal boundary hardening inside `llm_dart_core`
- clearer package ownership documentation
- continued root compatibility slimming

It is less likely to be:

- more package splitting for its own sake
- copying `@ai-sdk/provider` and `@ai-sdk/provider-utils` literally
- widening shared stream/UI contracts just to match `repo-ref/ai`

## Scope

This phase should:

- re-baseline the package graph and current ownership model using current code
  rather than older audit assumptions
- freeze the next highest-value feature-driven refactor targets
- write down the conditions that would justify any future package split
- keep the repository honest about what is mature, what is transitional, and
  what is intentionally deferred

## Non-Goals

This phase should explicitly avoid:

- reopening the shared event-model completeness debate
- reopening the renderer-registry debate without repeated app pain
- splitting provider packages into the same granularity as `repo-ref/ai`
- deleting legacy or compatibility surfaces before a deliberate deprecation
  plan exists

## Documents

- [00-priority-map.md](00-priority-map.md)
  - Ordered list of the next-phase architectural priorities.
- [01-repo-ref-gap-rebaseline.md](01-repo-ref-gap-rebaseline.md)
  - Fresh comparison between the current repository and the useful remaining
    structural signals from `repo-ref/ai`.
- [02-streamed-runner-maturity-audit.md](02-streamed-runner-maturity-audit.md)
  - Current-phase audit of whether the shared streamed runner now needs
    `prepareStep`, richer stop policy, or broader orchestration ownership.
- [03-llm-dart-core-boundary-map.md](03-llm-dart-core-boundary-map.md)
  - Frozen internal sublayer map for `llm_dart_core`, plus future split
    triggers and package-ownership rules.
- [04-root-package-role-reaudit.md](04-root-package-role-reaudit.md)
  - Re-audit of the current root `llm_dart` role after the latest package
    moves and root export cleanup.
- [TODO.md](TODO.md)
  - Open follow-up tasks for this phase.
- [MILESTONES.md](MILESTONES.md)
  - Milestones and acceptance criteria for this phase.
