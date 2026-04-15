# Streamed Runner Maturity Audit

## Goal

This note rechecks the next-phase runner question using current evidence rather
than older migration assumptions:

> after the Flutter backend-hint, approval, paused-state restore, and reconnect
> demos landed, does `llm_dart_core` now need a broader shared streamed runner
> surface similar to `repo-ref/ai`?

## Short Answer

No.

The current `StreamTextRunner` is still the right shared scope for now:

- keep `maxSteps` as the only shared stop guard
- keep declared common function-tool continuation only
- keep `eventStream` provider-step-only
- keep `prepareStep`, retry, model switching, and richer stop policy deferred

That means the runner-maturity question is now closed again for the current
phase.

## Current Shared Runner Surface

Today the shared streamed runner already provides:

- `streamTextRun(...)`
- stitched `eventStream`
- `stepStream` with completed `GenerateTextStepResult` values
- final `result`
- `onStepStart`, `onStepFinish`, and `onFinish`
- automatic continuation for declared common function tools through
  `functionToolExecutor`
- explicit unsupported errors for provider-executed tool continuation

The current tests cover the narrow contract honestly:

- single-step streaming
- stitched function-tool continuation
- missing executor stop behavior
- provider-executed tool rejection
- `maxSteps` guard failure

## What `repo-ref/ai` Adds Beyond This

The reference repository still owns a broader streamed orchestration surface:

- `prepareStep`
- richer stop conditions through `stopWhen`
- per-step model and provider-option mutation
- retry and timeout policy around the run loop
- more tool lifecycle callbacks
- higher-level UI stream production above raw provider streams

Those are useful product signals, but they are not automatically truthful
shared-core requirements for `llm_dart`.

## Current Evidence From `llm_dart`

### 1. The New Flutter Demos Do Not Need A Broader Shared Runner

The recent Flutter validation slices all landed without widening the shared
runner:

- backend hint routing stays transport-owned and backend-owned
- approval and paused-state restore stay session-owned
- reconnect recovery stays transport-owned

Those are the newest real application-facing validations in the repository, and
none of them required:

- shared `prepareStep`
- shared retry or model fallback
- shared run-level UI chunking

### 2. There Are Still No Shared Production Call Paths That Wrap Both Runners

The current codebase still does not show two concrete shared call paths that
repeatedly need the same pre-step mutation or run policy above both:

- `GenerateTextRunner`
- `StreamTextRunner`

That means the repository still lacks the evidence threshold for freezing a
broader shared mutation hook.

### 3. `prepareStep` Would Reopen Multiple Ownership Boundaries At Once

The reference `prepareStep` contract can alter:

- model
- tool choice
- active tools
- messages
- system
- context
- provider options

That is not one small convenience hook. It is a large policy surface.

In `llm_dart`, those mutation axes cut across boundaries we already froze:

- provider options stay provider-owned or backend-owned
- approval-safe continuation stays outside the shared runner
- model fallback and retry stay app-owned
- richer message/session policy stays above `llm_dart_core`

Adding `prepareStep` now would therefore reopen several questions at once
instead of solving one narrow proven need.

### 4. Richer Stop Policy Still Looks App-Owned

The reference `stopWhen` helpers are useful, but the current `llm_dart`
repository still does not show a clean cross-provider stop-policy subset beyond
the current guardrail:

- stop after non-tool finish
- continue only for the common shared function-tool path
- fail honestly when richer continuation is required

Retry, model fallback, and broader stopping rules still look more like:

- app policy
- backend policy
- or provider-family policy

than like a proven shared-core contract.

## Decision

Keep the current shared streamed runner boundary frozen:

- no shared `prepareStep`
- no shared `stopWhen`
- no shared retry or model fallback policy
- no mixed-provenance synthetic event injection into `eventStream`

The current runner already provides the honest shared subset that the codebase
has actually validated.

## Promotion Criteria For Reopening

Reopen runner expansion only if all of these become true:

1. at least two concrete shared call paths outside tests need the same
   runner-level mutation or stop policy
2. the need appears in both non-streaming and streaming runner usage, or is
   clearly streaming-specific with a stable contract
3. at least two provider families can honor the same contract without widening
   shared prompt, event, or UI models
4. the feature does not require approval, reconnect, persistence, or
   provider-native side channels

## Workstream Consequence

This closes the active runner-maturity decision work for this phase:

- `prepareStep` remains deferred
- retry/model fallback remains deferred
- richer shared stop policy remains deferred

The next active architecture task should therefore move to:

- `llm_dart_core` internal boundary hardening

not to broader streamed-runner expansion.

## Bottom Line

`repo-ref/ai` is still directionally useful here, but the useful lesson is not
"add all of `streamText` productization now."

The useful lesson is:

- keep the runner explicit
- keep its ownership honest
- promote new shared lifecycle policy only when the repository has real
  cross-provider evidence for it

That evidence still does not exist yet.
