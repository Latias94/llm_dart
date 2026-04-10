# 166 Streamed Runner Inter-Step Projection Policy

## Goal

Freeze one follow-up question after `StreamTextRunner` landed:

> should the stitched `eventStream` also synthesize locally generated
> inter-step events such as tool execution results, or should it stay a pure
> concatenation of provider-originated step streams in the narrow phase?

## Short Answer

Keep the streamed runner `eventStream` provider-step-only for now.

Do **not** synthesize local inter-step projection events in phase 1.

That means:

- provider-originated `ToolCallEvent`, `ToolResultEvent`, `ToolInput*Event`,
  `StepStartEvent`, and `StepFinishEvent` continue to flow through normally
- locally executed shared function-tool outputs do **not** get re-emitted into
  the stitched `eventStream`
- local tool execution remains observable through the executor boundary,
  `stepStream`, and final `result`

## Why This Question Exists

The reference `repo-ref/ai` streamed orchestration path does more here.

Because its top-level streamed helper owns a broader orchestration runtime, it
can:

- execute tools inside the same stream pipeline
- re-emit tool result parts into the higher-level stream
- expose richer callback timing around tool execution
- treat the stream as a productized orchestration protocol rather than just a
  stitched provider stream

Now that `llm_dart_core` has `StreamTextRunner`, it is reasonable to ask
whether we should copy that behavior.

The answer is still no in the current phase.

## Frozen Rule

`StreamTextRunResult.eventStream` should remain:

- a stitched stream of provider-originated `TextStreamEvent` sequences
- ordered by step execution
- free of synthetic local tool-result or local tool-error replay

In other words, the current stream contract is:

- step 0 provider stream
- then step 1 provider stream
- then step 2 provider stream
- and so on

The runner may use local tool execution **between** those steps, but it should
not inject that local execution back into the raw stitched event stream.

## Why We Should Not Inject Local Tool Events Yet

## 1. It Blurs Event Provenance

Today the stitched event stream can still be read as:

- "these are the events emitted by model invocations, replayed in order"

If we inject local tool results into the same stream, the semantics become:

- some events came from the provider
- some events came from the app-owned executor
- some events might later come from session or approval logic

That is a much less honest contract for the current phase.

## 2. It Creates Ordering And Grouping Questions

Once local tool results enter the stream, several follow-up questions appear:

- should tool results be emitted immediately when each local tool finishes?
- should they preserve declaration order or completion order?
- should denied execution become `ToolOutputDeniedEvent` in the same stream?
- should synthetic `StepStartEvent` / `StepFinishEvent` markers wrap local tool
  execution phases?
- should the next provider step start only after all synthetic local events are
  consumed?

Those are real design questions, not implementation trivia.

They belong to a richer orchestration layer than the current narrow runner.

## 3. It Pushes UI/Product Concerns Into Core

The strongest reason to inject local tool-result events is usually UI:

- show tool output immediately,
- show tool failure immediately,
- show tool progress between model steps.

Those are valid product needs, but they are closer to:

- chat runtime behavior,
- UI stream processing,
- telemetry/product instrumentation,
- or a future richer run-level protocol.

They are not required for the minimal shared streamed runner to be useful.

## 4. We Already Have Narrow Observation Points

Even without synthetic local tool events, callers can still observe useful
shared milestones through:

- `functionToolExecutor`
- `stepStream`
- final `result`
- `onStepStart`
- `onStepFinish`
- `onFinish`

So the absence of synthetic local tool-result events is not a functional
blocker for the current layer.

## 5. It Keeps The Layering Clean

The current architecture stays cleaner if we keep these concerns separate:

- raw provider stream stitching in `llm_dart_core`
- chat/session/UI projection in `llm_dart_chat`
- richer remote or UI-stream helpers above `ChatUiStreamChunk`

If we inject local orchestration events into the core runner now, that
separation gets weaker immediately.

## What Still Appears In The Stream

This policy does **not** mean tool-related events disappear from the stitched
run stream.

They still appear when the provider emits them itself, for example:

- tool input deltas from the provider
- finalized tool calls from the provider
- provider-originated tool results
- provider-originated step markers

The restriction applies only to **locally synthesized inter-step events**.

## Relationship To `stepStream`

`stepStream` is now the main shared surface for consumers that need a stable
cross-step snapshot.

That is the right current place to observe:

- the tool calls produced by a finished step
- the exact finish reason of that step
- the step content that will later be replayed into continuation prompts

If a future use case needs immediate tool-execution visibility before the next
provider step starts, that should be treated as a separate requirement rather
than quietly widening the stitched event stream.

## What A Future Expansion Should Look Like Instead

If we later need richer inter-step visibility, the better options are:

1. a dedicated run-level event or chunk layer above `TextStreamEvent`
2. a lightweight helper in `llm_dart_chat` for projected UI/tool lifecycle
3. explicit streamed tool-execution callbacks, if they can stay narrow

What we should avoid is silently turning the stitched raw event stream into a
mixed provenance protocol without freezing that change clearly.

## Promotion Criteria For Reconsideration

Revisit this only if all of these become true:

1. at least two concrete consumers need immediate local tool-result streaming
2. `stepStream` plus executor wrapping is clearly insufficient
3. ordering semantics can be specified cleanly
4. provenance remains explicit and replay-safe
5. the change does not force session/UI responsibilities back into
   `llm_dart_core`

If those criteria are met later, the next move should still be an explicit
additive surface, not a casual broadening of the current stitched stream.

## Conclusion

The policy is now frozen:

- `StreamTextRunner` stays useful but narrow
- its `eventStream` remains provider-step-only
- local tool execution does not synthesize extra `TextStreamEvent`s in phase 1
- richer inter-step projection, if needed later, should come through a more
  explicit higher-layer contract
