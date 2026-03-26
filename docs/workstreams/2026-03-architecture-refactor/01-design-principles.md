# Design Principles

## Goals

This refactor needs to solve four problems at the same time:

1. Thin the core abstractions so not every capability hangs off one provider object.
2. Keep provider-specific features extensible without continuing to rely on `dynamic` extension maps as the main path.
3. Make Flutter chat integration natural, including streamed text, reasoning, tools, sources, and files.
4. Make new-provider implementation cost predictable instead of copying another `config + client + chat + factory` stack.

## Non-Goals

The following are explicitly not goals of this refactor:

- matching the Vercel AI SDK API shape one-to-one
- unifying every provider-exclusive feature in phase 1
- exposing every provider API as a cross-provider stable standard
- sacrificing Flutter renderability just to force abstraction uniformity
- introducing a heavy agent or workflow framework in the first phase

## Design Principles

## 1. Unify Stable Layers, Not Noisy Layers

The layers that are genuinely worth unifying are:

- model types: language, embedding, image, speech, transcription
- input prompt structures: prompt messages and prompt parts
- output structures: content parts, stream events, usage, warnings
- UI render structures: chat messages, message parts, tool state, sources, files

The layers that should not be forced into a shared abstraction are:

- provider management APIs
- provider beta capabilities
- provider-specific HTTP parameter names
- provider-specific experimental features

## 2. Provider Features Must Be Typed

Patterns such as `extensions['reasoningEffort']` and `extensions['mcpServers']` were flexible in the short term, but they do not scale.

In the new architecture:

- shared parameters belong in shared call options
- provider-specific features belong in typed provider options
- provider-specific return details belong in `providerMetadata` or custom parts

A small escape hatch may still exist, but it must stay an edge mechanism rather than the primary design.

## 3. Message Models Must Be Layered

Following the idea of layered message models from the Vercel AI SDK, the Dart version should keep at least three layers:

1. Prompt Layer
   - for model calls
   - focused on what the model needs to see
2. Result / Stream Layer
   - for model outputs
   - focused on what the model returned
3. UI Chat Layer
   - for Flutter or web chat rendering
   - focused on how the application displays and interacts with the output

The current `ChatMessage` effectively tries to carry all three roles at once. That must be split.

## 4. Flutter-Friendliness Matters More Than a String-Only CLI API

For chat applications, a single `String text` is not enough. A renderable message must support at least:

- text parts
- reasoning parts
- tool input streaming, tool execution state, and tool output
- source references
- file, image, and audio attachments
- provider-defined custom blocks

That means the new chat-facing layer must be `parts`-based rather than centered around a single `content` string.

## 5. Keep the Top-Level Experience Simple and the Lower Layers Composable

The top-level user experience should look close to this:

```dart
final model = AI.openai(apiKey: key).chatModel('gpt-5-mini');

final result = await generateText(
  model: model,
  prompt: [
    UserMessage.text('Explain isolates in Dart.'),
  ],
);
```

But the provider implementation must not be trapped by that top-level API shape.

That means:

- the top-level API is use-case oriented
- the provider API is adapter oriented
- the UI API is render oriented

All three layers should exist, but they should not collapse into one class.

## 6. Follow Dart Best Practices

The new architecture should follow these Dart constraints:

- `core` must not depend on `dio`
- `core` must not depend on Flutter
- provider packages should hide internals through `src/`
- public models should be immutable where practical
- use `sealed class`, `final class`, and `base class` intentionally to define boundaries
- reduce `dynamic` and `Map<String, dynamic>` exposure in public APIs
- public return models should have clear copying, serialization, and equality semantics where needed
- file and network boundaries should not be embedded into message semantics

## 7. Capability Detection Should Move to Model Metadata

Today, many capability checks rely on string guessing such as:

- `model.contains('gpt')`
- `model.contains('claude')`
- `model.contains('gemini-2.5')`

Those checks should be concentrated into provider catalogs instead, forming:

- model capability tables
- provider default capability profiles
- fallback strategies

They should not stay scattered across config, chat, factory, and builder layers.

## 8. Freeze the Architecture Before Migrating Providers

Implementation order matters:

1. freeze the spec
2. freeze message, stream, and UI state models
3. migrate the OpenAI mainline
4. migrate the remaining providers

If provider files are split before the new spec is frozen, the result will just be a more fragmented version of the old architecture.

## Success Criteria

If this refactor succeeds, the result should look like this:

- `core` is thin and does not know any specific provider
- `PromptMessage` and `ChatUiMessage` are fully separated
- provider features no longer mainly depend on string-based extension keys
- OpenAI family duplication is significantly reduced
- Flutter chat UIs can directly consume a unified `parts` model
- adding a new provider no longer requires copying another oversized template
