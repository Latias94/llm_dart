# Runner Stop Policy And Mutation Hooks

## Goal

This note freezes the next boundary question after the first shared
`GenerateTextRunner` and continuation-ownership rules landed:

> Should the shared runner grow `stopWhen`, `prepareStep`, streaming
> orchestration, retry policies, or model switching like `repo-ref/ai`?

The short answer is:

- not in the current phase
- keep `maxSteps` as a guardrail only
- keep `prepareStep` out of the shared runner
- keep retry and model switching app-owned
- evaluate streaming orchestration later as a separate runner layer, not as a
  change to `streamText(...)`

## 1. Why The Reference SDK Is Broader

The reference SDK already owns a much wider loop contract:

- `stopWhen`
- `prepareStep`
- step-aware tool execution control
- server-oriented streaming loop assembly
- richer stop conditions after tool-result steps

That is coherent there because the same runtime owns:

- model invocation
- tool execution
- stop policy
- stream stitching
- server-side orchestration

`llm_dart` should not copy that breadth directly.

Our architecture is intentionally split:

- `llm_dart_core` owns the shared low-level model contract
- provider packages own provider-native behavior
- `llm_dart_flutter` owns chat-session orchestration
- apps own higher-level policy

## 2. Freeze `maxSteps` As A Guardrail, Not A Policy DSL

The current shared runner should keep `maxSteps` as a simple safety limit.

It should not become a general stop-policy DSL yet.

Why:

- the current runner supports only one narrow continuation family
- `repo-ref/ai` evaluates `stopWhen` in a broader tool-result loop that we do
  not fully own
- a richer stop DSL would immediately pull business policy into shared core
- it would also create pressure for tool-name conditions, deferred-tool logic,
  and provider-specific stop semantics

Frozen rule:

- keep `maxSteps` as an integer guardrail in the current runner
- do not add shared `stopWhen` in phase 1
- let app-owned orchestration decide any richer stop logic above the runner

## 3. `prepareStep` Should Still Stay Out

The reference SDK can mutate per-step behavior through `prepareStep`.

That is still the wrong move for the current shared runner.

Why:

- `prepareStep` is not just observability
- it can mutate model choice, system instructions, tool exposure, and step
  strategy
- once added, it becomes the easiest place to reintroduce cross-layer coupling

Frozen rule:

- no shared `prepareStep` in the current runner
- do not allow per-step model switching through shared runner callbacks
- do not allow provider-native tool injection through shared runner callbacks
- do not let the shared runner become the place where prompt mutation policy
  lives

## 4. Retry And Model Switching Stay App-Owned

The shared runner should not own:

- retry budgets
- retry classification policies
- fallback model chains
- cost-aware escalation
- provider failover

Why:

- those policies are application-specific
- provider failures do not normalize cleanly enough for one safe shared policy
- retry and model-switch decisions often depend on cost, latency, trust, or
  product semantics outside the model layer

If an application wants richer orchestration, it should wrap the shared runner
instead of expecting `llm_dart_core` to own that policy.

## 5. Streaming Orchestration Is A Separate Future Layer

We should not widen `streamText(...)` itself.

The existing split still stands:

- `streamText(...)` is one provider stream
- `GenerateTextRunner` is the current non-streaming shared multi-step layer

If a streamed multi-step runner is ever added later, it should be a separate
layer above the current primitives.

Why:

- the low-level stream boundary is already stable
- Flutter already owns a chat/session streaming abstraction
- streaming orchestration introduces abort, teeing, buffering, and transform
  semantics that are larger than the current runner scope

Frozen rule:

- do not change the meaning of `streamText(...)`
- do not bolt a stitched multi-step stream onto the current runner
- revisit a streamed runner only after the non-streaming runner proves useful
  in real call paths

## 6. Promotion Criteria For Any Future Expansion

The shared runner may expand later only if all of these are true:

1. the feature solves a real shared problem across several providers
2. it does not require provider-native lifecycle APIs
3. it can be expressed through the existing shared request/result/step models
4. it does not force Flutter session concerns into `llm_dart_core`
5. it does not turn the runner into an application policy engine

If a feature fails one of these checks, it should remain app-owned,
provider-owned, or Flutter-owned.

## 7. The Only Plausible Future Shared Additions

If the runner expands later, the safest candidates are still narrow:

- a constrained pre-step hook that can only observe or narrow already-declared
  shared function tools
- a streamed multi-step runner as a separate API, not as a change to
  `streamText(...)`
- better guardrails and diagnostics around unsupported continuation

What still should not be the next move:

- shared model switching
- shared fallback chains
- provider-native built-in tool continuation
- approval-heavy orchestration
- dynamic-tool orchestration

## Conclusion

The stop-and-mutation boundary is now frozen:

- `maxSteps` stays a guardrail
- `stopWhen` does not enter the shared runner in phase 1
- `prepareStep` stays out
- retry and model switching stay app-owned
- streaming orchestration, if it ever exists, must be a separate layer above
  the current single-step stream API

That keeps the shared runner small enough to stay honest and reusable.
