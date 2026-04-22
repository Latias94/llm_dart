# llm_dart

[![pub package](https://img.shields.io/pub/v/llm_dart.svg)](https://pub.dev/packages/llm_dart)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Dart](https://img.shields.io/badge/Dart-3.5.0+-blue.svg)](https://dart.dev)
[![CI](https://github.com/Latias94/llm_dart/actions/workflows/ci.yml/badge.svg)](https://github.com/Latias94/llm_dart/actions/workflows/ci.yml)

Modular Dart library for LLM providers with a stable model API, provider-owned typed options, and a Flutter-friendly chat session layer.

## Status

The repository is currently in a breaking architecture transition.

The new primary entry path is:

- `AI.openai(...).chatModel(...)`
- `AI.anthropic(...).chatModel(...)`
- `AI.google(...).chatModel(...)`
- `AI.deepSeek(...).chatModel(...)`
- `AI.groq(...).chatModel(...)`
- `AI.openRouter(...).chatModel(...)`
- `AI.xai(...).chatModel(...)`

Within this workspace, the modern shared-capability path for the current
community providers now lives in:

- `package:llm_dart_community/llm_dart_community.dart` for
  `Ollama(...).chatModel(...)`, `Ollama(...).embeddingModel(...)`,
  `ElevenLabs(...).speechModel(...)`, and
  `ElevenLabs(...).transcriptionModel(...)`

The legacy compatibility builder still exists through
`package:llm_dart/legacy.dart`.

`LLMBuilder()` remains the explicit compatibility builder surface.
The old `ai()` helper is now a deprecated migration alias rather than the
recommended main API.

For modern code, prefer `package:llm_dart/llm_dart.dart` as the default import.
`package:llm_dart/ai.dart` remains the explicit equivalent alias when you want a
named AI-focused shell.

For Ollama and ElevenLabs specifically, the root compatibility shells should now
be read as broader provider-specific migration surfaces rather than the primary
shared-capability entrypoint.

## Packages

- `llm_dart`
  - modern default root facade over the stable migrated model API
- `llm_dart_core`
  - prompt, result, stream, UI message models, and the shared `ChatMessageMapper`
- `llm_dart_transport`
  - HTTP, SSE, and shared logging primitives
- `llm_dart_chat`
  - pure Dart chat session, transport, snapshot, and compatibility re-exports over the chat runtime layer
- `llm_dart_openai`
  - OpenAI-family providers
- `llm_dart_anthropic`
  - Anthropic provider
- `llm_dart_google`
  - Google provider
- `llm_dart_community`
  - alpha-preview package for modern Ollama chat/embeddings and ElevenLabs speech/transcription shared-capability surfaces
- `llm_dart_flutter`
  - thin Flutter adapter above `llm_dart_chat`

For the `0.11.0-alpha.x` preview line, the focused workspace packages are also
being prepared as publishable alpha packages. The root `llm_dart` facade
remains the default entrypoint, while `llm_dart_chat`, `llm_dart_community`,
and `llm_dart_flutter` are available for narrower adoption when you want the
split package boundaries directly.

## Installation

```yaml
dependencies:
  llm_dart: ^0.11.0-alpha.1
```

Then run:

```bash
dart pub get
```

If you are developing inside this monorepo, make sure your workspace bootstrap
flow generates local `pubspec_overrides.yaml` files for workspace package
linking before you run package resolution or analysis.

The supported bootstrap command is:

```bash
dart tool/bootstrap_workspace_pubspec_overrides.dart
```

Those generated `pubspec_overrides.yaml` files are intentionally ignored by git.

For release validation across the root package plus the publishable workspace
packages, run:

```bash
dart tool/run_workspace_publish_dry_run.dart
```

## Focused Entry Points

- `package:llm_dart/llm_dart.dart`
  - default modern root entrypoint, equivalent stable surface to `ai.dart`
- `package:llm_dart/ai.dart`
  - explicit equivalent alias of the default modern root surface
- `package:llm_dart/chat.dart`
  - focused pure Dart chat runtime entrypoint over `llm_dart_chat`
- `package:llm_dart/openai.dart`
  - focused OpenAI-family provider entrypoint for provider-owned options,
    native tools, custom parts, and `OpenAIMessageMapper`
- `package:llm_dart/google.dart`
  - focused Google provider entrypoint for provider-owned options, replay
    helpers, custom parts, and `GoogleMessageMapper`
- `package:llm_dart/anthropic.dart`
  - focused Anthropic provider entrypoint for Anthropic-owned types
- `package:llm_dart/legacy.dart`
  - explicit compatibility shell for `LLMBuilder()`, `ai()`,
    `createProvider(...)`, legacy models, and builder-era APIs
- `package:llm_dart_community/llm_dart_community.dart`
  - alpha-preview modern community-provider entrypoint for Ollama
    chat/embeddings and ElevenLabs speech/transcription shared-capability
    models
- `package:llm_dart/transport.dart`
  - transport abstractions and shared logging primitives re-exported from `llm_dart_transport`
- `package:llm_dart_transport/dio.dart`
  - explicit raw Dio entrypoint for transport-specific compatibility integration
- `package:llm_dart_flutter/llm_dart_flutter.dart`
  - Flutter-specific adapters such as `ChatController`

## Quick Start

Use the default modern root entrypoint plus the shared core request model.

Current text-call layering:

- `generateTextCall(...)` / `streamTextCall(...)`
  - recommended app-facing text generation helpers
- `generateText(...)` / `streamText(...)`
  - lower-level raw single-step helpers

Other shared capability helpers:

- `embed(...)` / `embedMany(...)`
- `generateImage(...)`
- `generateSpeech(...)`
- `transcribe(...)`

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
      core.SystemPromptMessage.text('You are concise.'),
      core.UserPromptMessage.text('Explain Dart in one sentence.'),
    ],
  );

  print(result.text);
}
```

Example file:
[quick_start.dart](E:/codes/flutter/llm_dart/example/01_getting_started/quick_start.dart)

## Structured Output

Shared structured generation now lives above the main text-call layer through
`OutputSpec`, `generateTextCall(...)`, and `streamTextCall(...)`.

```dart
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/core.dart' as core;

Future<void> main() async {
  final model = llm.AI.openai(
    apiKey: 'your-openai-key',
  ).chatModel('gpt-4.1-mini');

  final result = await core.generateTextCall<String>(
    model: model,
    prompt: [
      core.UserPromptMessage.text('Return a JSON object with a short title.'),
    ],
    outputSpec: core.ObjectOutputSpec<String>(
      schema: core.JsonSchema.object(
        properties: const {
          'title': {'type': 'string'},
        },
        required: const ['title'],
      ),
      decode: (json) => json['title']! as String,
    ),
  );

  print(result.output);
}
```

## Embeddings

Shared embeddings now follow the same function-based helper direction:
application code uses `embed(...)` / `embedMany(...)`, while providers expose
typed capability models such as `AI.openai(...).embeddingModel(...)`.

```dart
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/core.dart' as core;

Future<void> main() async {
  final model = llm.AI.openai(
    apiKey: 'your-openai-key',
  ).embeddingModel('text-embedding-3-small');

  final result = await core.embed(
    model: model,
    value: 'Dart is optimized for client apps.',
  );

  print(result.embedding.length);
}
```

Example file:
[embeddings_stable.dart](E:/codes/flutter/llm_dart/example/02_core_features/embeddings_stable.dart)

## Streaming

The shared streaming boundary is `TextStreamEvent`.

```dart
import 'dart:io';

import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/core.dart' as core;

Future<void> main() async {
  final model = llm.AI.deepSeek(
    apiKey: 'your-deepseek-key',
  ).chatModel('deepseek-reasoner');

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

  stderr.writeln('finalText=${await stream.text}');
}
```

Example file:
[streaming_chat.dart](E:/codes/flutter/llm_dart/example/02_core_features/streaming_chat.dart)

## Tool Calling

Tool definitions live in `llm_dart_core`, and providers map them into provider-owned request codecs.

```dart
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/core.dart' as core;

Future<void> main() async {
  final model = llm.AI.openai(
    apiKey: 'your-openai-key',
  ).chatModel('gpt-4.1-mini');

  final tools = [
    core.FunctionToolDefinition(
      name: 'weather',
      description: 'Get the weather for a city.',
      inputSchema: core.ToolJsonSchema.object(
        properties: {
          'city': {'type': 'string'},
        },
        required: ['city'],
      ),
    ),
  ];

  final firstTurn = await core.generateTextCall(
    model: model,
    prompt: [
      core.UserPromptMessage.text('What is the weather in Hong Kong?'),
    ],
    tools: tools,
    toolChoice: const core.RequiredToolChoice(),
  );

  final toolCall =
      firstTurn.content.whereType<core.ToolCallContentPart>().single.toolCall;

  final secondTurn = await core.generateTextCall(
    model: model,
    prompt: [
      core.UserPromptMessage.text('What is the weather in Hong Kong?'),
      core.AssistantPromptMessage(
        parts: [core.ToolCallPromptPart(
          toolCallId: toolCall.toolCallId,
          toolName: toolCall.toolName,
          input: toolCall.input,
        )],
      ),
      core.ToolPromptMessage(
        toolName: toolCall.toolName,
        parts: [
          core.ToolResultPromptPart(
            toolCallId: toolCall.toolCallId,
            toolName: toolCall.toolName,
            output: {'temperature': 28, 'condition': 'humid'},
          ),
        ],
      ),
    ],
  );

  print(secondTurn.text);
}
```

Example file:
[tool_calling.dart](E:/codes/flutter/llm_dart/example/02_core_features/tool_calling.dart)

## Reasoning

Reasoning is part of the common result and stream model, but replay fidelity remains provider-owned.

```dart
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/core.dart' as core;

Future<void> main() async {
  final model = llm.AI.anthropic(
    apiKey: 'your-anthropic-key',
  ).chatModel('claude-sonnet-4-5');

  final result = await core.generateTextCall(
    model: model,
    prompt: [
      core.UserPromptMessage.text('Solve 15% of 240 step by step.'),
    ],
  );

  print('Reasoning: ${result.reasoningText}');
  print('Answer: ${result.text}');
}
```

Example file:
[reasoning_models.dart](E:/codes/flutter/llm_dart/example/03_advanced_features/reasoning_models.dart)

## Pure Dart Chat Runtime

For chat runtimes outside Flutter, prefer the focused root entrypoint:

```dart
import 'package:llm_dart/chat.dart';
```

This entrypoint re-exports `DefaultChatSession`, `DirectChatTransport`,
`HttpChatTransport`, `ChatRequestOptions`, `ChatMessageMapper`, and the stable
`AI` facade without pulling Flutter adapters into the root package surface.

`ChatMessageMapper` now lives in `package:llm_dart/core.dart` as part of the
shared UI model layer, and remains available from `package:llm_dart/chat.dart`
for chat-runtime-oriented imports.

Runnable pure Dart runtime example:
[chat_runtime.dart](E:/codes/flutter/llm_dart/packages/llm_dart_chat/example/chat_runtime.dart)

Package guide:
[packages/llm_dart_chat/README.md](E:/codes/flutter/llm_dart/packages/llm_dart_chat/README.md)

## Flutter Chat Session

The reusable chat runtime lives in `llm_dart_chat`, and the Flutter package
adds Flutter-specific adapters such as `ChatController` and controller-aware
persistence helpers. The root `package:llm_dart/chat.dart` entrypoint stays
pure Dart and does not re-export Flutter-only types.

```dart
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart_flutter/llm_dart_flutter.dart';

Future<void> main() async {
  final controller = ChatController(
    session: DefaultChatSession(
      transport: DirectChatTransport(
        model: llm.AI.openai(
          apiKey: 'your-openai-key',
        ).chatModel('gpt-4.1-mini'),
      ),
    ),
  );

  controller.addListener(() {
    final state = controller.state;
    print('status=${state.status}');
    if (state.messages.isNotEmpty) {
      final mapped = const ChatMessageMapper().map(state.messages.last);
      print('messages=${state.messages.length}');
      print('latestText=${mapped.text}');
    }
  });

  await controller.sendMessage(ChatInput.text('Write a short haiku about Flutter.'));
}
```

Example file:
[flutter_integration.dart](E:/codes/flutter/llm_dart/packages/llm_dart_flutter/example/flutter_integration.dart)

Package guide:
[packages/llm_dart_flutter/README.md](E:/codes/flutter/llm_dart/packages/llm_dart_flutter/README.md)

For snapshot persistence, keep storage application-owned and use
`ChatPersistenceAdapter` as the thin codec bridge:

```dart
final adapter = ChatPersistenceAdapter(store: myStore);

await adapter.saveController(controller);

final restoredController = await adapter.restoreController(
  'chat-1',
  createController: (snapshot) => ChatController(
    session: DefaultChatSession.fromSnapshot(
      transport: transport,
      snapshot: snapshot,
    ),
  ),
);
```

For widget-friendly rendering, `ChatMessageMapper` projects a `ChatUiMessage`
into common text, reasoning, tool, source, file, warning, and error summaries
without inventing another transport or provider layer.

Use `ChatMessageMapper` as the stable rendering baseline. When the UI also
needs provider-owned inspection, compose it with the focused provider
entrypoints instead of widening the shared chat layer.

The default recommendation is now:

- import `ChatMessageMapper` from `package:llm_dart/core.dart` or any package
  that re-exports it
- use `OpenAIMessageMapper.mapComposed(...)` or
  `GoogleMessageMapper.mapComposed(...)` when the UI needs both the shared
  baseline and provider-owned metadata in one call

Focused provider mapper helpers:

- `package:llm_dart/openai.dart`
  - `OpenAIMessageMapper` for response/item/source/tool metadata, custom parts,
    and logprobs-aware part inspection
- `package:llm_dart/google.dart`
  - `GoogleMessageMapper` for thought signatures, response-part metadata,
    source metadata, and Google custom-part inspection

```dart
import 'package:llm_dart_flutter/llm_dart_flutter.dart';
import 'package:llm_dart/google.dart' as google;
import 'package:llm_dart/openai.dart' as openai;

void renderOpenAI(ChatUiMessage message) {
  final mapped = const openai.OpenAIMessageMapper().mapComposed(message);
  final shared = mapped.shared;
  final provider = mapped.provider;

  print(shared.text);
  print(provider.hasOpenAIMetadata);
  print(provider.hasLogprobs);

  for (final detail in provider.partDetails) {
    print('${detail.type}: ${detail.label}');
  }
}

void renderGoogle(ChatUiMessage message) {
  final mapped = const google.GoogleMessageMapper().mapComposed(message);
  final shared = mapped.shared;
  final provider = mapped.provider;

  print(shared.text);
  print(provider.hasGoogleMetadata);
  print(provider.hasThoughtSignatures);

  for (final detail in provider.partDetails) {
    print('${detail.type}: ${detail.label}');
    print(detail.sourceId);
    print(detail.chunkType);
  }
}
```

## Provider-Specific Options

The unified request shape stays small. Provider-specific features are passed through typed provider options.

Import provider-owned option types from provider entrypoints such as
`package:llm_dart/openai.dart` or `package:llm_dart/google.dart`.
OpenAI-family providers, including xAI, currently share the `openai.dart` entrypoint.

OpenAI Responses example:

```dart
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/openai.dart' as openai;

Future<void> main() async {
  final model = llm.AI.openai(
    apiKey: 'your-openai-key',
  ).chatModel('gpt-5-mini');

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

  print(result.text);
}
```

xAI live search example:

```dart
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/openai.dart' as openai;

Future<void> main() async {
  final model = llm.AI.xai(
    apiKey: 'your-xai-key',
  ).chatModel('grok-3');

  final result = await core.generateTextCall(
    model: model,
    prompt: [
      core.UserPromptMessage.text('Find the latest Grok announcements.'),
    ],
    callOptions: const core.CallOptions(
      providerOptions: openai.XAIGenerateTextOptions(
        search: openai.XAILiveSearchOptions.autoWeb(),
      ),
    ),
  );

  print(result.text);
}
```

## Design Rules

- Keep the shared API focused on common model semantics.
- Prefer `generateTextCall(...)` / `streamTextCall(...)` for app-facing text
  generation, and keep `generateText(...)` / `streamText(...)` for lower-level
  raw access.
- Keep provider-native features in typed provider options, provider metadata, or custom parts.
- Keep UI/session concerns above `TextStreamEvent`.
- Treat `LLMBuilder()`, `ai()`, and old root provider surfaces as
  compatibility APIs, not the target architecture.
- Treat the root Ollama and ElevenLabs surfaces as compatibility-first shells
  when the modern shared-capability path already exists in
  `llm_dart_community`.

## Current Reference Docs

- Post-closure roadmap:
  [docs/workstreams/2026-04-post-closure-priorities/README.md](E:/codes/flutter/llm_dart/docs/workstreams/2026-04-post-closure-priorities/README.md)
- Community provider workspace guide:
  [packages/llm_dart_community/README.md](E:/codes/flutter/llm_dart/packages/llm_dart_community/README.md)
- Migration guide:
  [38-migration-guide.md](E:/codes/flutter/llm_dart/docs/workstreams/2026-03-architecture-refactor/38-migration-guide.md)
- Architecture workstream index:
  [docs/workstreams/2026-03-architecture-refactor/README.md](E:/codes/flutter/llm_dart/docs/workstreams/2026-03-architecture-refactor/README.md)
- Provider UI extension contract:
  [docs/workstreams/2026-04-post-closure-priorities/01-provider-ui-extension-contract.md](E:/codes/flutter/llm_dart/docs/workstreams/2026-04-post-closure-priorities/01-provider-ui-extension-contract.md)
- Community provider public-entry guidance:
  [104-community-provider-public-entry-guidance.md](E:/codes/flutter/llm_dart/docs/workstreams/2026-03-architecture-refactor/104-community-provider-public-entry-guidance.md)
- Prompt normalization contract:
  [37-prompt-normalization-contract.md](E:/codes/flutter/llm_dart/docs/workstreams/2026-03-architecture-refactor/37-prompt-normalization-contract.md)
- Stream coverage matrix:
  [36-provider-stream-coverage-matrix.md](E:/codes/flutter/llm_dart/docs/workstreams/2026-03-architecture-refactor/36-provider-stream-coverage-matrix.md)

## Legacy Compatibility

The repository still keeps compatibility APIs through `package:llm_dart/legacy.dart`, including:

- `LLMBuilder()` and the deprecated `ai()` alias
- old root provider constructors
- compatibility adapters for legacy chat/config surfaces

These remain temporarily for migration, but new code should prefer the stable
model API shown above.

If you still need the compatibility-era builder and broad legacy surface, prefer
the explicit import:

```dart
import 'package:llm_dart/legacy.dart';
```
