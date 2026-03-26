# Unified API And Boundaries

## Core Conclusion

The unified API should no longer revolve around one giant provider interface. It should be split into three layers:

1. model interfaces
2. shared use-case functions
3. UI session interfaces

These layers have different responsibilities and different stability requirements.

## 1. Recommended Unified Interface Scope

## 1. Unified Model Types

The following stable model interfaces should be frozen:

- `LanguageModel`
- `EmbeddingModel`
- `ImageModel`
- `SpeechModel`
- `TranscriptionModel`

These interfaces should correspond to real cross-provider commonality, not simply to “whatever features currently exist in the library”.

### `LanguageModel`

Responsible for:

- non-streaming text generation
- streaming text generation
- tool calling
- structured output
- reasoning output
- source, file, and provider metadata output

Not responsible for:

- provider management APIs
- provider-side response storage, deletion, or cancellation
- file management APIs

### `EmbeddingModel`

Responsible for:

- single or batched embeddings
- dimensions and usage output

### `ImageModel`

Responsible for:

- text-to-image generation
- image editing
- image variation generation

### `SpeechModel`

Responsible for:

- text-to-speech
- streaming speech output

### `TranscriptionModel`

Responsible for:

- audio transcription
- translation-style transcription

## 2. Unified High-Level Use-Case Functions

Following the Vercel AI SDK pattern, the truly stable cross-provider API should be function-based rather than provider-object-based:

- `generateText`
- `streamText`
- `embed`
- `embedMany`
- `generateImage`
- `generateSpeech`
- `transcribe`

Benefits:

- the shared call surface stays stable
- provider differences are pushed down into model adapters
- the API shape works naturally for Flutter, servers, and CLI code

Example:

```dart
final model = AI.openai(apiKey: apiKey).chatModel('gpt-5-mini');

final result = await generateText(
  model: model,
  prompt: [
    UserMessage.text('Explain Dart isolates in simple words.'),
  ],
  options: const GenerateTextOptions(
    temperature: 0.2,
  ),
);
```

## 3. Unified UI Session Interfaces

What a chat application really needs is neither a provider object nor a raw text stream. It needs a session layer:

- `ChatSession`
- `ChatTransport`
- `ChatState`
- `ChatUiMessage`
- `ChatUiPart`

This layer is the key to Flutter-friendly integration.

## 2. Interfaces That Should Not Be Forced Into the Stable Unified Spec

The following capabilities should not enter the stable shared spec:

- OpenAI Responses CRUD
- OpenAI built-in tool management
- Anthropic MCP connector
- OpenAI Assistants
- provider file management APIs
- moderation, admin, or model management APIs

The reason is not that these features are unimportant. The reason is that:

- they are not stable across providers
- their naming, lifecycle, and state models vary too much
- forcing them into the shared spec too early would distort the spec

Recommended handling:

- expose them as provider-package-specific APIs
- attach useful return details to `providerMetadata`
- only project them into `ChatUiPart` when they have direct chat UI meaning

## 3. Message Model Boundaries

## 1. Prompt Messages

The prompt layer should only answer “what gets sent to the model”, not “how the UI works”.

Suggested shape:

```dart
sealed class PromptMessage {
  PromptRole get role;
  List<PromptPart> get parts;
}

sealed class PromptPart {}

final class TextPromptPart extends PromptPart { ... }
final class FilePromptPart extends PromptPart { ... }
final class ImagePromptPart extends PromptPart { ... }
final class ToolCallPromptPart extends PromptPart { ... }
final class ToolResultPromptPart extends PromptPart { ... }
```

Key rules:

- do not keep relying on one `content` string to represent everything
- do not place UI state into the prompt layer
- do not place provider-specific UI blocks into the prompt layer

## 2. Content Parts and Result Layer

Model results should not only expose `text` and `toolCalls`. They should expose parts:

```dart
sealed class ContentPart {}

final class TextContentPart extends ContentPart { ... }
final class ReasoningContentPart extends ContentPart { ... }
final class ToolCallContentPart extends ContentPart { ... }
final class ToolResultContentPart extends ContentPart { ... }
final class SourceContentPart extends ContentPart { ... }
final class FileContentPart extends ContentPart { ... }
final class CustomContentPart extends ContentPart { ... }
```

After that:

- `text` becomes a convenience projection
- `thinking` becomes a convenience projection of reasoning parts
- provider-defined outputs can move into `CustomContentPart`

## 3. UI Chat Messages

The UI layer answers “how should this be rendered and interacted with”, which is not the same thing as prompt input.

Suggested shape:

```dart
final class ChatUiMessage {
  final String id;
  final ChatUiRole role;
  final List<ChatUiPart> parts;
  final Map<String, Object?> metadata;
}

sealed class ChatUiPart {}

final class TextUiPart extends ChatUiPart { ... }
final class ReasoningUiPart extends ChatUiPart { ... }
final class ToolUiPart extends ChatUiPart { ... }
final class SourceUiPart extends ChatUiPart { ... }
final class FileUiPart extends ChatUiPart { ... }
final class DataUiPart<T> extends ChatUiPart { ... }
final class CustomUiPart extends ChatUiPart { ... }
final class StepBoundaryUiPart extends ChatUiPart { ... }
```

This layer should serve Flutter chat rendering first. Provider payload details should adapt to it, not the other way around.

Additional UI-boundary rules:

- `ToolUiPart` should carry streamed input state, final input, output, approval state, and separate call/result provider metadata.
- `ToolUiPart` should expose `providerExecuted`, `isDynamic`, `preliminary`, and `title`, because these directly affect how a Flutter chat UI renders tool cards.
- `ChatUiMessage.metadata` should keep reserved call-level keys such as warnings, response metadata, finish metadata, streamed errors, and optional diagnostic raw chunks.
- `llm_dart_core` should ship a pure Dart projector from `TextStreamEvent` to `ChatUiMessage` so Flutter applications do not have to rebuild the stream state machine themselves.

## 4. Stream Event Boundaries

The current `TextDeltaEvent`, `ThinkingDeltaEvent`, and `ToolCallDeltaEvent` style is too thin for real chat state handling.

It should evolve into a more complete streamed event model:

```dart
sealed class TextStreamEvent {}

final class StartEvent extends TextStreamEvent { ... }
final class ResponseMetadataEvent extends TextStreamEvent { ... }

final class TextStartEvent extends TextStreamEvent { ... }
final class TextDeltaEvent extends TextStreamEvent { ... }
final class TextEndEvent extends TextStreamEvent { ... }

final class ReasoningStartEvent extends TextStreamEvent { ... }
final class ReasoningDeltaEvent extends TextStreamEvent { ... }
final class ReasoningEndEvent extends TextStreamEvent { ... }

final class ToolInputStartEvent extends TextStreamEvent { ... }
final class ToolInputDeltaEvent extends TextStreamEvent { ... }
final class ToolInputEndEvent extends TextStreamEvent { ... }
final class ToolApprovalRequestEvent extends TextStreamEvent { ... }
final class ToolCallEvent extends TextStreamEvent { ... }
final class ToolResultEvent extends TextStreamEvent { ... }
final class ToolOutputDeniedEvent extends TextStreamEvent { ... }

final class SourceEvent extends TextStreamEvent { ... }
final class FileEvent extends TextStreamEvent { ... }
final class StepStartEvent extends TextStreamEvent { ... }
final class StepFinishEvent extends TextStreamEvent { ... }
final class CustomEvent extends TextStreamEvent { ... }
final class RawChunkEvent extends TextStreamEvent { ... }
final class FinishEvent extends TextStreamEvent { ... }
final class ErrorEvent extends TextStreamEvent { ... }
```

This allows Flutter applications to build message state directly instead of reconstructing everything from half-formed text deltas.

Additional stream-boundary rules:

- `StartEvent` should carry call-level warnings so streaming and non-streaming calls expose the same diagnostics surface.
- `ResponseMetadataEvent` should be independent from `FinishEvent` because some providers send response IDs, timestamps, or model IDs early.
- `CustomEvent` should preserve provider-native streamed blocks that do not belong in the common event set.
- `RawChunkEvent` should remain opt-in and diagnostic-focused instead of becoming a default public transport surface.
- tool-approval must be a first-class event because provider-executed tools can pause generation until the caller decides.
- `ToolOutputDeniedEvent` should exist because an approval flow can end without a provider-side tool output payload.
- step-boundary events belong to the orchestration layer rather than to provider transport only, because multi-step tool loops can span multiple provider calls.

## 5. UI Projection Boundary

The stream model is still not enough by itself. A reusable projection layer is also needed:

```dart
final accumulator = ChatUiAccumulator(messageId: 'assistant-1');

await for (final event in streamText(model: model, prompt: prompt)) {
  final message = accumulator.apply(event);
  render(message);
}
```

This projection layer belongs in pure Dart core, not in Flutter-specific code, because:

- CLI tools also need streamed rich-message state
- backend transports may want to persist or replay projected message parts
- the message projection rules are part of the architecture contract, not a widget concern

## 6. How Provider Features Should Be Represented

## 1. Model-Level Typed Options

Provider-specific configuration that is stable for the lifetime of a model should be passed at model creation time:

```dart
final model = AI.openai(apiKey: key).chatModel(
  'gpt-5-mini',
  options: const OpenAIChatModelOptions(
    reasoningEffort: ReasoningEffort.medium,
    parallelToolCalls: true,
  ),
);
```

## 2. Invocation-Level Typed Options

Provider-specific features that change per call should be carried through invocation-level typed options:

```dart
await generateText(
  model: model,
  prompt: prompt,
  providerOptions: const OpenAIInvocationOptions(
    serviceTier: OpenAIServiceTier.priority,
  ),
);
```

## 3. Provider Metadata

Information that is useful to the caller but does not deserve a shared top-level field should go into `providerMetadata`, for example:

- OpenAI compaction or cache details
- Anthropic token-cache hits
- xAI search metadata
- Google candidate metadata

## 4. Custom Parts

Provider-specific message blocks that genuinely need to reach the UI should go through `CustomContentPart` and `CustomUiPart` instead of polluting the common part set.

## 7. Recommended Top-Level Facade

Keep a unified facade, but change its meaning from “build a giant provider” to “get a model or session”:

```dart
final model = AI.openai(apiKey: apiKey).chatModel('gpt-4.1-mini');
final embedding = AI.openai(apiKey: apiKey).embeddingModel('text-embedding-3-small');

final chat = ChatSession.direct(model: model);
```

The old `ai()` builder can remain as a compatibility layer, but it should stop being the center of the architecture.

## 8. Boundary Decision Rules

A capability should enter the stable shared spec only if all of the following are true:

1. at least two primary providers expose a stable corresponding concept
2. the lifecycle model is similar enough
3. the input and output shape can be normalized
4. Flutter or server callers are likely to use it across providers

If two of these conditions are not met, that capability should stay out of the shared spec for now.
