# Single-Step Calls Versus Multi-Step Runner

## Goal

This note freezes one important follow-up to the step-lifecycle discussion:

> Should `llm_dart` add Vercel-style step callbacks directly to the current
> `generateText` / `streamText` helpers, or should multi-step orchestration live
> in a separate layer?

The answer should be:

- keep the current model calls single-step
- add multi-step lifecycle orchestration in a higher-level runner

## 1. Current Truth In `llm_dart`

The current core text API is still intentionally low-level:

- `LanguageModel.generate(request)` means one provider call
- `LanguageModel.stream(request)` means one provider stream
- `generateText(...)` is a thin helper around `LanguageModel.generate(...)`
- `streamText(...)` is a thin helper around `LanguageModel.stream(...)`

That means the current API does not yet own:

- repeated tool-loop orchestration
- accumulated cross-step prompt growth
- automatic step-level retries or model switching
- multi-step `StepResult` history
- final aggregated total usage across several provider calls

Those concerns currently live either:

- in provider-owned behavior
- in the Flutter session layer
- or nowhere yet in shared core orchestration

## 2. Why The Reference API Looks Different

In `repo-ref/ai`, step callbacks make sense directly on `generateText` and
`streamText` because those APIs already own more orchestration:

- tool-result continuation
- prepare-step mutation
- multi-step history accumulation
- final aggregated step output

That architecture is valid there.

It is not our current architecture.

If we copied only the callback names without copying the orchestration layer, we
would create an API that sounds richer than it really is.

## 3. Frozen Boundary

The boundary should be:

- keep `LanguageModel` as the single provider-call abstraction
- keep `generateText(...)` and `streamText(...)` as single-step convenience
  helpers above that abstraction
- add any future multi-step lifecycle API in a separate higher-level runner

This means we should not force the current low-level API to suddenly own:

- `steps`
- `prepareStep`
- multi-step `onStepFinish`
- aggregated total usage
- tool-execution orchestration callbacks

Those belong to a runner, not to the raw provider-call abstraction.

## 4. Recommended New Layer

If we want repo-ref-style maturity, add a provider-agnostic orchestration layer
above the current model calls.

Recommended shape:

```dart
final run = GenerateTextRunner(
  model: model,
  prompt: prompt,
  tools: tools,
  functionToolExecutor: functionToolExecutor,
  onStepStart: (event) async {},
  onStepFinish: (step) async {},
  onFinish: (result) async {},
);

final result = await run.run();
```

Or as top-level helpers:

```dart
final result = await runTextGeneration(
  model: model,
  prompt: prompt,
  tools: tools,
  functionToolExecutor: functionToolExecutor,
  onStepStart: (event) async {},
  onStepFinish: (step) async {},
  onFinish: (result) async {},
);
```

The important rule is structural, not nominal:

- multi-step lifecycle belongs to a runner layer that orchestrates repeated
  provider calls

Current status:

- this runner layer now exists in `llm_dart_core`
- its first shared continuation contract is intentionally narrow:
  app-supplied common function-tool execution only

## 5. What The Runner Should Own

The future runner may own:

- accumulated `StepResult` history
- prompt growth between steps
- optional tool execution orchestration
- optional prepare-step model or prompt mutation
- final aggregated usage across steps
- final multi-step result assembly

The runner should consume the existing low-level building blocks:

- `GenerateTextRequest`
- `GenerateTextResult`
- `TextStreamEvent`
- prompt/content/tool/source/file/common metadata models

This keeps the orchestration layer additive instead of rewriting the core again.

## 6. What Must Stay Out Of The Runner

The runner must still not become a new dumping ground.

It should not absorb:

- provider-native admin or storage APIs
- provider-native file management
- provider-native built-in tool families that need their own execution
  environments
- Flutter UI session state

The runner owns shared orchestration only.

## 7. Phase Order Recommendation

The safest implementation order is:

1. define a shared `StepResult` model
2. define lifecycle callback shapes
3. add a non-Flutter higher-level runner for multi-step text generation
4. only then consider whether a streamed runner result is worth adding

This order is better than starting with a giant streaming wrapper because:

- the low-level stream boundary is already stable
- Flutter chat already has a streaming/session abstraction
- a non-streaming runner is enough to prove the step model first

## 8. Streaming Guidance

If a future streaming runner is added, it should still preserve the same split:

- low-level `streamText(...)` stays a raw single-step provider stream
- higher-level streaming orchestration may wrap several single-step calls and
  emit lifecycle callbacks or a richer run result

Do not redefine the meaning of `streamText(...)` itself.

## Conclusion

The next orchestration feature should not be implemented by making the current
low-level model helpers pretend to be a multi-step agent runtime.

Instead:

- keep current `generateText(...)` and `streamText(...)` honest and single-step
- add a separate shared runner for multi-step lifecycle orchestration
- build `StepResult` and lifecycle callbacks there
