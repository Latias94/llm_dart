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

The legacy `ai()` builder still exists, but it is now compatibility-oriented rather than the recommended main API.

## Packages

- `llm_dart`
  - root facade and legacy compatibility surface
- `llm_dart_core`
  - prompt, result, stream, and UI message models
- `llm_dart_transport`
  - HTTP and SSE transport
- `llm_dart_openai`
  - OpenAI-family providers
- `llm_dart_anthropic`
  - Anthropic provider
- `llm_dart_google`
  - Google provider
- `llm_dart_flutter`
  - Flutter-facing chat transport and session layer

## Installation

```yaml
dependencies:
  llm_dart: ^0.10.7
  llm_dart_flutter: ^0.1.0-dev.0
```

Then run:

```bash
dart pub get
```

## Quick Start

Use the stable facade plus the shared core request model.

```dart
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/core.dart' as core;

Future<void> main() async {
  final model = llm.AI.openai(
    apiKey: 'your-openai-key',
  ).chatModel('gpt-4.1-mini');

  final result = await core.generateText(
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

  await for (final event in core.streamText(
    model: model,
    prompt: [
      core.UserPromptMessage.text('Solve 15 * 27 and show your reasoning.'),
    ],
  )) {
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

  final firstTurn = await core.generateText(
    model: model,
    prompt: [
      core.UserPromptMessage.text('What is the weather in Hong Kong?'),
    ],
    tools: tools,
    toolChoice: const core.RequiredToolChoice(),
  );

  final toolCall =
      firstTurn.content.whereType<core.ToolCallContentPart>().single.toolCall;

  final secondTurn = await core.generateText(
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

  final result = await core.generateText(
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

## Flutter Chat Session

The Flutter-facing layer sits above `TextStreamEvent` and projects it into `ChatUiMessage`.

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
      print('messages=${state.messages.length}');
    }
  });

  await controller.sendMessage(ChatInput.text('Write a short haiku about Flutter.'));
}
```

Example file:
[flutter_integration.dart](E:/codes/flutter/llm_dart/packages/llm_dart_flutter/example/flutter_integration.dart)

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

  final result = await core.generateText(
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

  final result = await core.generateText(
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
- Keep provider-native features in typed provider options, provider metadata, or custom parts.
- Keep UI/session concerns above `TextStreamEvent`.
- Treat `ai()` and old root provider surfaces as compatibility APIs, not the target architecture.

## Current Reference Docs

- Migration guide:
  [38-migration-guide.md](E:/codes/flutter/llm_dart/docs/workstreams/2026-03-architecture-refactor/38-migration-guide.md)
- Architecture workstream index:
  [docs/workstreams/2026-03-architecture-refactor/README.md](E:/codes/flutter/llm_dart/docs/workstreams/2026-03-architecture-refactor/README.md)
- Prompt normalization contract:
  [37-prompt-normalization-contract.md](E:/codes/flutter/llm_dart/docs/workstreams/2026-03-architecture-refactor/37-prompt-normalization-contract.md)
- Stream coverage matrix:
  [36-provider-stream-coverage-matrix.md](E:/codes/flutter/llm_dart/docs/workstreams/2026-03-architecture-refactor/36-provider-stream-coverage-matrix.md)

## Legacy Compatibility

The repository still exports:

- the old `ai()` builder
- old root provider constructors
- compatibility adapters for legacy chat/config surfaces

These remain temporarily for migration, but new code should prefer the stable model API shown above.
