# Structured Output Result Surface

## Goal

This note closes the next concrete gap after the shared `OutputSpec` layer
landed:

> How should streamed structured output expose `partialOutput`, array elements,
> and final parsed output in a more productized way without redefining
> `streamText(...)` itself?

## 1. Reference Signal From `repo-ref/ai`

The relevant lesson from the reference is not just "support structured output".

The more mature lesson is:

- a streamed structured-output call should expose more than one raw event stream
- partial parsed output should be available as its own surface
- array element completion should be available as its own surface
- the final parsed output should be available as a result-like future

That is exactly the shape that makes Flutter or server code easier to compose.

## 2. Current `llm_dart` Problem

Before this slice:

- `generateOutput(...)` already returned a typed wrapper result
- `streamOutput(...)` only returned one event stream
- partial output and array elements existed only as events inside that stream
- the final parsed output existed only as the terminal `OutputResultEvent`

That meant the shared structured-output capability existed, but it was still
more event-centric than result-centric.

## 3. Decision

We should not redefine `streamText(...)`.

We should also not force `GenerateTextResult` or `TextStreamEvent` to absorb
structured-output semantics yet.

The incremental result is:

- keep `streamOutput(...)` as the low-level shared event stream
- add `streamOutputResult(...)` as a higher-level streamed result surface

This preserves the current single-step low-level boundaries while adding a more
productized shared API above them.

## 4. New Shared Surface

`streamOutputResult(...)` returns `StreamOutputResult<T>`.

That result exposes:

- `eventStream`
- `textStream`
- `partialOutputStream`
- `elementStream<TElement>()`
- `result`
- `output`

The important architectural rule is:

- parsed structured output is now available as shared result data
- partial output and array elements are now available as dedicated shared
  streams
- the raw event stream still remains available for advanced consumers

## 5. Why This Is The Right Increment

### 5.1 It Closes The Most Valuable Gap

The previous gap versus the reference was not missing provider wire support.

The previous gap was that the shared structured-output surface still required
apps to fish important signals back out of one event stream manually.

`streamOutputResult(...)` fixes that without widening the low-level model
boundary.

### 5.2 It Does Not Pollute `LanguageModel.stream(...)`

`LanguageModel.stream(...)` still means:

- one provider call
- raw shared `TextStreamEvent`s

We do not overload it with:

- parsed output futures
- array-only side channels
- higher-level orchestration semantics

Those capabilities now live in the higher shared helper where they belong.

### 5.3 It Avoids A Premature Generic Migration

We still do not need to make the low-level `GenerateTextResult` generic.

That avoids unnecessary churn across provider packages while still making the
structured-output path much easier to consume.

## 6. Remaining Gap After This Slice

The remaining structured-output gap is now narrower:

- `generateOutput(...)` and `streamOutputResult(...)` are shared productized
  surfaces
- `generateText(...)` and `streamText(...)` themselves still do not take an
  `OutputSpec`

That remaining gap should stay open until we are confident that deeper
main-call integration is worth the breaking cost.

## Conclusion

The correct next step was not to redefine `streamText(...)` and not to push
structured output back into provider-owned metadata.

The correct next step was to add a higher-level shared streamed result surface:

- keep `streamOutput(...)` for low-level event access
- add `streamOutputResult(...)` for buffered partial output, array elements, and
  final parsed output

This moves `llm_dart` closer to the mature `repo-ref/ai` shape while keeping
the Dart-first layering discipline intact.

The next landed slice after this note is the additive main-call result layer in
`53-main-text-call-result-layer.md`.
