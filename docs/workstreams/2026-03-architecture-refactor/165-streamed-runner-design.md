# 165 Streamed Runner Design

## Goal

Define the next additive orchestration layer above the already-frozen raw
single-step stream API and the already-landed non-streaming shared runner.

The question is:

> how should `llm_dart_core` expose streamed multi-step orchestration without
> redefining `streamText(...)`, widening `TextStreamEvent`, or pulling
> Flutter/session concerns into the shared core?

## Short Answer

Add a new streamed runner layer.

Do **not**:

- change the meaning of `streamText(...)`,
- widen `TextStreamEvent`,
- collapse the streamed runner into `GenerateTextRunner`,
- copy the full breadth of `repo-ref/ai` step policy, `prepareStep`, or
  provider-native continuation ownership.

The shared streamed runner should stay narrow, just like the current
non-streaming runner.

## Frozen Boundary

The shared text-generation stack should now be read as four layers:

1. `generateText(...)` / `streamText(...)`
   - low-level single-step shared model helpers
2. `generateTextCall(...)` / `streamTextCall(...)`
   - richer single-step result surfaces
3. `GenerateTextRunner` / `runTextGeneration(...)`
   - non-streaming shared multi-step continuation
4. `StreamTextRunner` / `streamTextRun(...)`
   - streamed shared multi-step continuation

The new streamed runner is additive.

It is **not** a replacement for the existing helpers.

## Why This Should Be A Separate API

`streamText(...)` already has a clean and stable meaning:

- one request,
- one provider stream,
- raw shared events,
- no orchestration policy beyond that request.

If we changed `streamText(...)` into a stitched multi-step stream, we would
blur:

- provider request boundaries,
- shared versus app-owned continuation policy,
- raw stream semantics versus run-level orchestration.

Keeping a separate streamed runner preserves the current architecture:

- raw stream stays raw,
- run orchestration stays explicit,
- Flutter/session layers can still choose whether to consume raw model streams
  or a shared run-level stream.

## Supported Scope In Phase 1

The first streamed runner should support only the same continuation subset as
the current `GenerateTextRunner`:

- common function tools declared through shared `FunctionToolDefinition`
- app-supplied tool execution through a shared executor callback
- prompt replay through existing shared prompt/content models
- `maxSteps` as a guardrail

This means the shared streamed runner may continue automatically only when all
tool calls are:

- client executed,
- non-dynamic,
- declared in the shared tool list.

## Explicitly Out Of Scope

The streamed runner should still reject or avoid owning:

- approval-gated continuation
- provider-executed built-in tools
- dynamic tool calls
- `prepareStep`
- retry policies
- model switching
- fallback chains
- provider-native tool declaration or provider-native tool replay policy
- UI/session state management
- transport protocol concerns

Those remain app-owned, provider-owned, or `llm_dart_chat`-owned.

## Result Surface

The result surface should mirror the current additive style used by
`StreamTextCallResult`:

- a stitched `Stream<TextStreamEvent>` for the full run
- a `Stream<GenerateTextStepResult>` for completed steps
- a `Future<GenerateTextRunResult>` for the final aggregated run

Recommended shape:

- `StreamTextRunResult extends StreamView<TextStreamEvent>`
- `Future<GenerateTextRunResult> result`
- `Stream<GenerateTextStepResult> stepStream`
- convenience getters for `text`, `finishReason`, `totalUsage`, and `lastStep`

This keeps the streamed runner easy to compose:

- stream consumers can render incrementally,
- step-aware consumers can observe per-step completion,
- result-oriented consumers can wait for the final run snapshot.

## Event Model Rule

The stitched run stream should stay within the existing `TextStreamEvent`
vocabulary.

It should not invent new shared event types for run orchestration.

In particular, phase 1 should not add:

- run-start or run-finish events,
- synthetic tool-output-available events,
- new UI-oriented event families.

If step boundaries matter to consumers, they should continue to use the
existing shared `StepStartEvent` / `StepFinishEvent` semantics already carried
by provider streams, plus the separate `stepStream` if they need finished step
snapshots.

## Step Stream Rule

`stepStream` should emit only after a step is fully accumulated and converted
into `GenerateTextStepResult`.

That keeps it replay-safe and easy to consume:

- no partial step snapshots,
- no mutable step state,
- no coupling to provider-specific incremental parser internals.

## Continuation Rule

Continuation should follow the same policy as `GenerateTextRunner`:

- if the step does not end with `FinishReason.toolCalls`, stop
- if no shared executor is provided, stop
- if tool approval is requested, throw unsupported
- if provider-executed or dynamic tools appear, throw unsupported
- if `maxSteps` is exceeded, throw

The streamed runner should not introduce a broader continuation contract than
the non-streaming runner already owns.

## Relationship To `DefaultChatSession`

The streamed runner and `DefaultChatSession` solve different problems.

The streamed runner is:

- model-oriented,
- prompt-in / event-stream-out,
- shared across CLI/server/backend use cases,
- intentionally narrow on policy.

`DefaultChatSession` is:

- chat-oriented,
- UI-message/session-state oriented,
- responsible for local session history, approval injection, UI chunks,
  transport integration, and persistence-friendly state.

So the streamed runner should stay in `llm_dart_core`, while any richer
message/session processing continues to live above it.

## Why This Aligns With `repo-ref/ai` Without Copying It

The reference SDK proves that a richer streamed orchestration layer is useful.

But its broader ownership model is different:

- its top-level helpers already own more lifecycle policy,
- its UI stream layer is richer and more server-oriented,
- its orchestration surface mixes more concerns into one runtime.

`llm_dart` should borrow the layering lesson, not the full shape:

- keep raw helpers low-level,
- keep run orchestration explicit,
- keep UI/session orchestration separate,
- grow only the shared continuation subset we can support honestly.

## Recommended Phase-1 Implementation

Phase 1 should be intentionally small:

1. add `StreamTextRunResult`
2. add `StreamTextRunner`
3. add `streamTextRun(...)`
4. stitch step streams into one run stream
5. accumulate each step into `GenerateTextStepResult`
6. expose finished steps through `stepStream`
7. expose final run aggregation through `result`

The implementation should reuse:

- `GenerateTextResultAccumulator`
- `GenerateTextStepResult`
- `GenerateTextRunResult`
- `ReplayStreamChannel`
- the current shared continuation logic already used by
  `GenerateTextRunner`

## Deferred Follow-Ups

After this phase lands, the next evaluation points are still separate:

- whether a lightweight `llm_dart_chat` UI-stream helper is warranted
- whether any richer streamed-runner callbacks are justified in real use
- whether a constrained pre-step hook is ever needed

These should be decided only after the narrow streamed runner is used in
concrete shared call paths.

## Conclusion

The boundary is now frozen:

- streamed multi-step orchestration is worth adding,
- it must be a new additive shared runner API,
- it must keep the same narrow continuation subset as the current runner,
- it must not redefine `streamText(...)`,
- it must not widen the shared event model,
- it must not absorb chat/session responsibilities.
