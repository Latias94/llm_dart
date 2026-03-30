# Step Result And Runner API Design

## Goal

This note translates the step-lifecycle boundary into a concrete API direction.

It does two things:

1. define the first shared step-result model we can add safely now
2. define the runner API shape we should target later without overcommitting to
   the full orchestration surface yet

Current status:

- the shared step model has landed
- the first narrow non-streaming multi-step runner slice has also landed
- this note now describes the frozen boundary for expanding that runner further

## 1. Design Constraint

The most important constraint from the earlier decisions is:

- current `LanguageModel.generate/stream` and `generateText` / `streamText`
  remain single-step abstractions

Therefore:

- the first shared step model must be additive
- it should wrap existing request and result models instead of replacing them
- it should not force a multi-step runtime into the low-level model interfaces

## 2. First Safe Shared Type

The first type we should add is a shared step snapshot for one provider call.

Recommended name:

- `GenerateTextStepResult`

Recommended minimal shape:

```dart
final class GenerateTextStepResult {
  final int stepNumber;
  final String providerId;
  final String modelId;
  final GenerateTextRequest request;
  final GenerateTextResult result;
}
```

Why this shape is the safest first move:

- it reuses the already-frozen request model
- it reuses the already-frozen result model
- it avoids duplicating every field from `GenerateTextResult`
- it keeps the step layer honest: a step is one request plus one result

## 3. Recommended Convenience Getters

The wrapper should expose convenience getters so callers do not need to drill
through `result` all the time.

Recommended getters:

```dart
List<ContentPart> get content;
String get text;
String? get reasoningText;
List<SourceReference> get sources;
List<GeneratedFile> get files;
List<ToolCallContent> get toolCalls;
List<ToolResultContent> get toolResults;
List<ToolApprovalRequestContent> get toolApprovalRequests;
FinishReason get finishReason;
String? get rawFinishReason;
String? get responseId;
DateTime? get responseTimestamp;
String? get responseModelId;
UsageStats? get usage;
ProviderMetadata? get providerMetadata;
List<ModelWarning> get warnings;
```

These getters should all be derived projections from `result`.

## 4. What Should Not Go Into The First Step Model

Do not put these into the first shared step model yet:

- accumulated previous steps
- aggregated total usage
- multi-step finish result
- prepare-step mutation results
- tool execution callback state
- telemetry-specific fields
- Flutter session state

Those belong either in the future runner layer or in app-owned orchestration.

## 5. Recommended Runner Direction

After `GenerateTextStepResult` exists, the next layer can be a higher-level
runner.

Recommended names:

- `GenerateTextRunner`
- or top-level `runTextGeneration(...)`

The first runner version should target this contract:

```dart
final result = await runTextGeneration(
  model: model,
  prompt: prompt,
  tools: tools,
  functionToolExecutor: functionToolExecutor,
  maxSteps: 8,
  onStepStart: (event) async {},
  onStepFinish: (step) async {},
  onFinish: (run) async {},
);
```

That first implementation should stay intentionally narrow.

## 6. Runner V1 Scope

Runner v1 now owns:

- repeated provider calls when the orchestration policy is explicitly supported
- `GenerateTextStepResult` accumulation
- final aggregated run result
- lifecycle callbacks
- replay of prior assistant/tool messages between steps
- app-supplied continuation for declared common function tools only

Runner v1 still does not own:

- model switching
- arbitrary `prepareStep`
- generic tool execution for arbitrary tool families
- provider-native built-in tool execution
- approval-gated continuation
- Flutter session concerns

This keeps the first runner small enough to prove the API without opening a new
coupling sink.

## 7. Recommended Run Result Shape

When the runner lands, its final result should be separate from the single-step
result.

Recommended direction:

```dart
final class GenerateTextRunResult {
  final List<GenerateTextStepResult> steps;
  final GenerateTextStepResult lastStep;
  final UsageStats? totalUsage;
}
```

Recommended convenience getters:

- `content`
- `text`
- `reasoningText`
- `sources`
- `files`
- `toolCalls`
- `toolResults`
- `finishReason`
- `rawFinishReason`
- `providerMetadata`

Those should default to the final step unless the field is explicitly
aggregated, such as `totalUsage`.

## 8. Callback Shape Recommendation

The callback API should start with only three hooks:

```dart
typedef GenerateTextOnStepStart = FutureOr<void> Function(
  GenerateTextStepStartEvent event,
);

typedef GenerateTextOnStepFinish = FutureOr<void> Function(
  GenerateTextStepResult step,
);

typedef GenerateTextOnFinish = FutureOr<void> Function(
  GenerateTextRunResult result,
);
```

And the step-start event should stay small:

```dart
final class GenerateTextStepStartEvent {
  final int stepNumber;
  final String providerId;
  final String modelId;
  final GenerateTextRequest request;
  final List<GenerateTextStepResult> previousSteps;
}
```

This is enough for tracing and orchestration visibility without introducing a
large callback contract too early.

## 9. Why `prepareStep` Should Wait

The reference SDK also exposes `prepareStep`.

We should not copy that immediately.

Reason:

- `prepareStep` is not just observability
- it lets the orchestration layer mutate model choice, prompt, and call options
- it is easy to turn into a new coupling sink before the runner semantics are
  proven

Recommended rule:

- first add read-oriented lifecycle callbacks
- only add `prepareStep` after one runner implementation proves which mutation
  points are truly necessary

## 10. Why Broader Tool Execution Still Waits

The same rule now applies to broader runner-owned tool execution.

The runner now has a very narrow contract:

- app-supplied execution for declared common function tools

What still must wait is a broader cross-package executor contract that tries to
cover every tool family.

Reason:

- local tool execution in chat sessions already has a Flutter-owned boundary
- provider-native built-in tools often have provider-owned lifecycles
- a premature core tool executor risks collapsing provider/runtime/UI concerns
  back together

Recommended first step:

- keep the current narrow function-tool continuation stable first
- decide any broader shared runner-owned tool execution only after that

## 11. Recommended Implementation Order

1. add `GenerateTextStepResult` to `llm_dart_core`
2. export it from the package entrypoint
3. add tests for the convenience projections
4. keep the runner narrow until the model proves stable
5. only then expand continuation scope beyond common function tools if that is
   still justified

## Conclusion

The first code move was modest:

- add `GenerateTextStepResult` as a wrapper around existing request/result
  models

The first runner is also modest:

- read-oriented lifecycle hooks first
- narrow common function-tool continuation only
- mutation hooks and broader tool-execution orchestration later
