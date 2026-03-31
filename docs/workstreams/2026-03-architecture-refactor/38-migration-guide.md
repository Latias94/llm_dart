# Migration Guide

## Goal

This guide explains how to move from the old root-package compatibility surface
to the new stable model API without assuming that every historical feature is
already migrated.

The core rule is simple:

- use `AI.*(...).chatModel(...)` for migrated chat behavior
- use `package:llm_dart/core.dart` for prompt, result, tool, and stream models
- use provider entrypoints such as `package:llm_dart/openai.dart` or
  `package:llm_dart/google.dart` for provider-owned option types
- keep the old compatibility path only where the stable replacement is not yet
  real

## 1. What Should Migrate Now

These paths are already the recommended primary API:

- `AI.openai(...).chatModel(...)`
- `AI.openRouter(...).chatModel(...)`
- `AI.deepSeek(...).chatModel(...)`
- `AI.groq(...).chatModel(...)`
- `AI.xai(...).chatModel(...)`
- `AI.google(...).chatModel(...)`
- `AI.anthropic(...).chatModel(...)`

`AI.phind(...).chatModel(...)` also exists as a stable facade entrypoint, but it
should currently be treated as a direct new-path experiment rather than a
legacy-parity migration target.

These helpers should be treated as the stable request helpers above the model:

- `generateTextCall(...)`
- `streamTextCall(...)`

The older low-level helpers still exist:

- `generateText(...)`
- `streamText(...)`

Use them when you intentionally want the raw single-step boundary rather than
the richer app-facing call result layer.

These shared model families are already the intended stable boundary:

- prompt messages and prompt parts
- generate-text results and content parts
- shared text stream events
- Flutter chat session state and UI messages

## 2. What Should Stay On The Old Path For Now

Do not force migration yet for areas that still do not have stable package-owned
coverage:

- OpenAI embeddings, image, speech, and transcription
- Google image, embeddings, speech, and TTS
- Anthropic MCP and broader provider-native feature coverage beyond the frozen
  replay-safe subsets
- Ollama and ElevenLabs
- any legacy Phind request that depends on parity with the old provider protocol
- bridge-incompatible provider-native replay shapes that the compatibility layer
  still rejects on purpose

If you need those old surfaces, prefer:

- the base compatibility constructors for that provider family
- the existing old provider path

Do not migrate those call sites into the new API just to keep old behavior by
guesswork.

## 3. Quick Replacement Map

| Old surface | New surface | Notes |
| --- | --- | --- |
| `ai().openai()...build()` | `AI.openai(...).chatModel(...)` | Use this when you only need migrated chat behavior. |
| `ai().anthropic()...build()` | `AI.anthropic(...).chatModel(...)` | Same rule. |
| `ai().google()...build()` | `AI.google(...).chatModel(...)` | Same rule. |
| `provider.chat(messages)` | `generateTextCall(model: ..., prompt: ...)` | Recommended app-facing text call surface. |
| `provider.chatStream(messages)` | `streamTextCall(model: ..., prompt: ...)` | Recommended app-facing streamed text call surface. |
| `ChatMessage.*` | `PromptMessage.*` | Replace legacy message DTOs with replay-safe prompt messages. |
| `Tool.function(...)` | `FunctionToolDefinition(...)` | Use `ToolJsonSchema` and `ToolChoice`. |
| legacy preset helpers | `AI.*(...).chatModel(...)` | Preset helpers are now compatibility-only. |
| root-package provider-specific extension keys | typed `providerOptions` | Import option types from provider entrypoints. |

## 4. Minimal Chat Migration

Old compatibility path:

```dart
import 'package:llm_dart/llm_dart.dart';

Future<void> main() async {
  final provider = await ai()
      .openai()
      .apiKey('your-openai-key')
      .model('gpt-4.1-mini')
      .build();

  final response = await provider.chat([
    ChatMessage.user('Explain Dart in one sentence.'),
  ]);

  print(response.text);
}
```

New stable path:

```dart
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/core.dart' as core;

Future<void> main() async {
  final model = llm.AI.openai(
    apiKey: 'your-openai-key',
  ).chatModel('gpt-4.1-mini');

  final result = await core.generateTextCall(
    model: model,
    prompt: [
      core.UserPromptMessage.text('Explain Dart in one sentence.'),
    ],
  );

  print(result.text);
}
```

The architectural shift is intentional:

- construction returns a model, not a chat-capability object
- shared request helpers own the request shape
- provider-specific behavior moves into typed provider options instead of free
  string extension keys

## 5. Message Migration

The message migration should be mechanical for the replay-safe common subset.

| Old message | New message |
| --- | --- |
| `ChatMessage.system(text)` | `SystemPromptMessage.text(text)` |
| `ChatMessage.user(text)` | `UserPromptMessage.text(text)` |
| `ChatMessage.assistant(text)` | `AssistantPromptMessage.text(text)` |
| tool result replay through ad hoc legacy blocks | `ToolPromptMessage` with `ToolResultPromptPart` |

For direct tool-call replay, the stable shared path is:

1. declare tools with `FunctionToolDefinition`
2. inspect `ToolCallContentPart` in the first result
3. append `AssistantPromptMessage` with `ToolCallPromptPart`
4. append `ToolPromptMessage` with `ToolResultPromptPart`
5. call `generateTextCall(...)` again

This is the replay-safe common subset.

Provider-native replay that does not fit this shared shape should stay
provider-owned.

## 6. Streaming Migration

Old compatibility path:

```dart
await for (final event in provider.chatStream(messages)) {
  switch (event) {
    case ThinkingDeltaEvent(delta: final delta):
      stderr.write(delta);
    case TextDeltaEvent(delta: final delta):
      stdout.write(delta);
    case CompletionEvent(response: final response):
      stdout.writeln(response.text);
    case ErrorEvent(error: final error):
      stderr.writeln(error);
  }
}
```

New stable path:

```dart
final stream = core.streamTextCall(
  model: model,
  prompt: [
    core.UserPromptMessage.text('Solve 15 * 27 and show your reasoning.'),
  ],
);

await for (final event in stream) {
  switch (event) {
    case core.ReasoningDeltaEvent(:final delta):
      stderr.write(delta);
    case core.TextDeltaEvent(:final delta):
      stdout.write(delta);
    case core.FinishEvent(:final finishReason, :final usage):
      stdout.writeln('\n[$finishReason, tokens=${usage?.totalTokens}]');
    case core.ErrorEvent(:final error):
      stderr.writeln(error);
    default:
      break;
  }
}
```

The shared streaming boundary is still `TextStreamEvent`.

Do not treat UI-only lifecycle chunks or transport-only chunks as reasons to
expand the shared core event model.

For structured streaming, the preferred additive main-call helper is now:

```dart
final streamResult = core.streamTextCall(
  model: model,
  prompt: [
    core.UserPromptMessage.text('Return structured JSON.'),
  ],
  outputSpec: core.ObjectOutputSpec.json(
    schema: core.JsonSchema.object(
      properties: const {
        'value': {'type': 'string'},
      },
      required: const ['value'],
      additionalProperties: false,
    ),
  ),
);

await for (final partialOutput in streamResult.partialOutputStream) {
  print(partialOutput);
}

print(await streamResult.output);
```

Current streaming rule:

- `streamOutput(...)` forwards raw `TextStreamEvent`s through
  `OutputTextStreamEvent`
- it now also emits best-effort `OutputPartialEvent`s for built-in structured
  output modes
- array outputs now also emit `OutputElementEvent`s for newly completed
  elements while staying on the same event stream
- `streamOutputResult(...)` remains the dedicated structured event surface
- `streamTextCall(...)` now adds buffered `partialOutputStream`,
  `elementStream<T>()`, final `result`, and final `output` access while still
  being directly iterable as `Stream<TextStreamEvent>`

## 7. Provider-Specific Options Migration

The root facade intentionally does not re-export every provider-owned option
type.

That boundary is part of the new design.

Use this rule:

- `package:llm_dart/llm_dart.dart`
  - import for the stable `AI` facade
- `package:llm_dart/core.dart`
  - import for shared prompt, result, tool, and stream types
- `package:llm_dart/openai.dart`
  - import for OpenAI-family option types, built-in tools, and profile-owned
    helpers
- `package:llm_dart/google.dart`
  - import for Google option types and native tool entries
- `package:llm_dart/anthropic.dart`
  - import for Anthropic option types and native tool entries

Example: OpenAI-family built-in tools

```dart
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/openai.dart' as openai;

final model = llm.AI.openai(apiKey: 'your-openai-key').chatModel('gpt-5-mini');

final result = await core.generateTextCall(
  model: model,
  prompt: [
    core.UserPromptMessage.text('Search for recent Dart SDK news.'),
  ],
  callOptions: const core.CallOptions(
    providerOptions: openai.OpenAIGenerateTextOptions(
      builtInTools: [openai.OpenAIWebSearchTool()],
    ),
  ),
);
```

Example: Google reasoning options

```dart
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/google.dart' as google;

final model = llm.AI.google(apiKey: 'your-google-key').chatModel('gemini-2.5-flash');

final result = await core.generateTextCall(
  model: model,
  prompt: [
    core.UserPromptMessage.text('Think through how layouts work in Flutter.'),
  ],
  callOptions: const core.CallOptions(
    providerOptions: google.GoogleGenerateTextOptions(
      includeThoughts: true,
    ),
  ),
);
```

This keeps the common request shape small while still giving providers room for
real feature differences.

### Structured Output Migration

The compatibility builder still accepts legacy `jsonSchema(...)`, but that path
is now only a bridge.

Current rule:

- legacy `jsonSchema` is normalized into shared
  `GenerateTextOptions.responseFormat`
- OpenAI-family providers currently preserve `name`, `description`, `schema`,
  and `strict`
- Google currently uses the shared schema payload and ignores shared fields
  that do not map to its wire format
- new code should prefer `OutputSpec`, `generateTextCall(...)`,
  `streamTextCall(...)`, dedicated `generateOutput(...)` / `streamOutput(...)`
  wrappers when their event surface is specifically desired, or explicit shared
  `JsonResponseFormat`
- do not add new app logic that depends on provider-specific compatibility
  injection of `responseFormat`

If a legacy `jsonSchema` value does not include a real schema, the compatibility
bridge now rejects that request shape instead of silently dropping structured
generation.

## 8. Flutter Migration

The Flutter migration should move one level up in abstraction.

Old pattern:

- call providers directly from UI state holders
- manually merge streaming deltas into view state
- manually store message history in app code

New pattern:

- create a model with `AI.*(...).chatModel(...)`
- wrap it with `DirectChatTransport` or `HttpChatTransport`
- let `DefaultChatSession` own chat state, message projection, replay-safe
  history, and tool-output continuation
- use `ChatController` as the widget-facing `ValueNotifier<ChatState>` wrapper
  when Flutter UI code wants `Listenable` integration instead of manual stream
  wiring
- use `ChatPersistenceAdapter` when snapshots need to be encoded, stored, and
  restored through an application-owned persistence backend
- use `ChatMessageMapper` when widget code wants pre-filtered text, reasoning,
  tool, source, file, warning, and error projections from `ChatUiMessage`

Example:

```dart
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart_flutter/llm_dart_flutter.dart';

final controller = ChatController(
  session: DefaultChatSession(
    transport: DirectChatTransport(
      model: llm.AI.openai(
        apiKey: 'your-openai-key',
      ).chatModel('gpt-4.1-mini'),
    ),
  ),
);

await controller.sendMessage(
  ChatInput.text('Write a short haiku about Flutter widgets.'),
);
```

If your Flutter app still needs provider-native behavior that the session layer
does not project yet, keep that feature provider-owned instead of widening the
shared UI model prematurely.

## 9. When To Stay On Compatibility Constructors

Use the base compatibility constructors when all of these are true:

- you still need the old root provider class shape
- the stable model API does not yet replace that feature family
- you want honest migration staging instead of partial rewrites

Do not use deprecated preset helpers as the long-term migration target.

The migration order should be:

1. stable `AI` facade, when migrated chat behavior is enough
2. base compatibility constructor, when the old provider surface is still needed
3. old preset helper only as a temporary stopgap while that call site is being
   cleaned up

## 10. Current Compatibility Expectations

The compatibility layer is conservative by design.

That means:

- some legacy requests still route into migrated providers safely
- some legacy requests still fall back to the old provider implementation
- some provider-native replay shapes are still rejected with migration-oriented
  wording

Do not read compatibility success on one legacy request as proof that the entire
provider surface has migrated.

That is especially important for:

- schema-less legacy `jsonSchema` requests, which now fail fast on the bridged
  path
- OpenRouter search beyond the audited online-model subset
- xAI search and replay beyond the audited live-search subset
- Anthropic provider-native result families beyond the frozen replay-safe blocks
- Phind legacy traffic as a whole

## 11. Removal Policy

The old root-package compatibility surface is not removed during the current
`0.x` line.

Current frozen policy:

- deprecations may continue during `0.x`
- examples and docs should move to the stable `AI` facade now
- actual removal should happen no earlier than `1.0.0`
- even at `1.0.0`, removal should happen only with migration docs, stable
  replacements, and explicit release-note coverage

So the right strategy today is not “wait until the old APIs disappear”.

The right strategy is:

- stop teaching the old path
- migrate the chat mainline now
- keep non-migrated surfaces honest until their replacements are real

## 12. Suggested Migration Checklist

For each caller, apply this checklist:

1. Replace provider construction with `AI.*(...).chatModel(...)` if the caller
   only needs migrated chat behavior.
2. Replace `ChatMessage` with shared prompt messages.
3. Replace `provider.chat(...)` or `provider.chatStream(...)` with
   `generateTextCall(...)` or `streamTextCall(...)`.
4. Replace string-based provider extensions with typed `providerOptions`.
5. Import provider-owned option types from provider entrypoints instead of the
   root facade.
6. Keep non-migrated features on compatibility constructors instead of forcing
   a half-migration.
7. For Flutter apps, move direct UI-provider coupling into `ChatSession`.

## Related Docs

- [33-legacy-factory-entrypoint-deprecations.md](33-legacy-factory-entrypoint-deprecations.md)
- [34-legacy-api-removal-window.md](34-legacy-api-removal-window.md)
- [35-bridge-incompatible-provider-result-migration-guidance.md](35-bridge-incompatible-provider-result-migration-guidance.md)
- [37-prompt-normalization-contract.md](37-prompt-normalization-contract.md)
