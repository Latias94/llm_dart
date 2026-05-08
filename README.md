# llm_dart

[![pub package](https://img.shields.io/pub/v/llm_dart.svg)](https://pub.dev/packages/llm_dart)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Dart](https://img.shields.io/badge/Dart-3.5.0+-blue.svg)](https://dart.dev)
[![CI](https://github.com/Latias94/llm_dart/actions/workflows/ci.yml/badge.svg)](https://github.com/Latias94/llm_dart/actions/workflows/ci.yml)

Modular Dart library for LLM providers with a stable model-first API,
provider-owned typed options, and a Flutter-friendly chat session layer.

## Status

The repository is currently on the `0.11.0-alpha.x` preview line.

Breaking changes are still allowed before `1.0.0`, but the model-first surface
below is the intended direction for new code.

The new primary entry path is:

- `openai(...).chatModel(...)`
- `anthropic(...).chatModel(...)`
- `google(...).chatModel(...)`
- `deepSeek(...).chatModel(...)`
- `groq(...).chatModel(...)`
- `openRouter(...).chatModel(...)`
- `xai(...).chatModel(...)`

The equivalent grouped facade remains available as
`AI.<provider>(...).chatModel(...)` when you prefer a single namespace.

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

Recommended entry flow for new code:

- import `package:llm_dart/llm_dart.dart` or `package:llm_dart/ai.dart`
- create concrete models through `openai(...).chatModel(...)`,
  `anthropic(...).chatModel(...)`, `embeddingModel(...)`,
  `imageModel(...)`, `speechModel(...)`, or `transcriptionModel(...)`
- call shared helpers from the same root import or from
  `package:llm_dart/core.dart` when you want a narrower shared-runtime import
- add provider-owned option types, metadata inspection, or lifecycle APIs only
  at explicit application boundaries
- reach for `package:llm_dart/legacy.dart` only when migrating older
  builder-era code

For Ollama and ElevenLabs specifically, the root compatibility shells should now
be read as broader provider-specific migration surfaces rather than the primary
shared-capability entrypoint.

Community-provider capability profiles are now also available through the
modern `llm_dart_community` package. For app and Flutter gating, treat the
current ElevenLabs descriptors and the shared Ollama baseline as descriptive
library-owned signals, but treat family-shaped Ollama hints such as image input
or reasoning output as potentially `inferred` rather than as hard guarantees.

## Packages

- `llm_dart`
  - recommended root package for the stable model-first API
- `llm_dart_provider`
  - provider-facing prompt, content, tool, model, response, and stream
    contracts
- `llm_dart_ai`
  - framework-neutral generation helpers, runners, result accumulation, and
    structured output utilities
- `llm_dart_core`
  - compatibility package for historical core imports
- `llm_dart_transport`
  - HTTP, SSE, and shared logging primitives
- `llm_dart_chat`
  - pure Dart chat sessions, transports, snapshots, and persistence helpers
- `llm_dart_openai`
  - OpenAI-family providers
- `llm_dart_anthropic`
  - Anthropic provider
- `llm_dart_google`
  - Google provider
- `llm_dart_community`
  - alpha package for Ollama chat/embeddings and ElevenLabs speech/transcription
- `llm_dart_flutter`
  - thin Flutter adapter above `llm_dart_chat`

For the `0.11.0-alpha.x` preview line, the focused workspace packages are also
available as alpha packages. The root `llm_dart` package remains the default
entrypoint, while the split packages are available for narrower adoption when
you want those dependencies directly. They are normal consumable Dart packages,
not implementation-only internals. For example, an OpenAI-only app can depend
on `llm_dart_openai` directly without adding the root `llm_dart` package.

## Installation

```yaml
dependencies:
  llm_dart: ^0.11.0-alpha.1
```

For a focused dependency set, depend on the package boundary you actually use:

```yaml
dependencies:
  llm_dart_openai: ^0.11.0-alpha.1
  llm_dart_ai: ^0.11.0-alpha.1
```

`llm_dart_ai` is needed only when you want the shared helper calls such as
`generateTextCall(...)`; provider packages such as `llm_dart_openai` can also
be imported directly on their own.

Then run:

```bash
dart pub get
```

If you are developing inside this monorepo, make sure your workspace bootstrap
flow generates local `pubspec_overrides.yaml` files for workspace package
linking before you run package resolution or analysis.

The supported bootstrap command is:

```bash
dart run tool/bootstrap_workspace_pubspec_overrides.dart
```

Those generated `pubspec_overrides.yaml` files are intentionally ignored by git.

For release validation across the root package plus the publishable workspace
packages, run:

```bash
dart run tool/release_readiness.dart
```

## Focused Entry Points

- `package:llm_dart/llm_dart.dart`
  - default modern root entrypoint, equivalent stable surface to `ai.dart`;
    exposes short provider factories such as `openai(...)` plus the grouped
    `AI` facade
- `package:llm_dart/ai.dart`
  - explicit equivalent alias of the default modern root surface
- `package:llm_dart/chat.dart`
  - focused pure Dart chat runtime entrypoint over `llm_dart_chat`
- `package:llm_dart/openai.dart`
  - focused OpenAI-family provider entrypoint for `openai(...)`,
    provider-owned options, native tools, custom parts, and
    `OpenAIMessageMapper`
- `package:llm_dart/xai.dart`
  - focused xAI entrypoint for `xai(...)`, live-search options, and xAI-owned
    source controls
- `package:llm_dart/deepseek.dart`
  - focused DeepSeek entrypoint for `deepSeek(...)` and DeepSeek-owned
    invocation options
- `package:llm_dart/openrouter.dart`
  - focused OpenRouter entrypoint for `openRouter(...)`, online-model routing,
    and OpenRouter-owned settings
- `package:llm_dart/groq.dart`
  - focused Groq entrypoint for `groq(...)` and Groq profile settings
- `package:llm_dart/phind.dart`
  - focused Phind entrypoint for `phind(...)` and Phind profile settings
- `package:llm_dart/google.dart`
  - focused Google provider entrypoint for `google(...)`, provider-owned
    options, replay helpers, custom parts, and `GoogleMessageMapper`
- `package:llm_dart/anthropic.dart`
  - focused Anthropic provider entrypoint for `anthropic(...)` and
    Anthropic-owned types
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
Most applications should stay on this layer until they have a concrete need for
provider-owned options, remote lifecycle APIs, or compatibility-only flows.

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

Future<void> main() async {
  final model = llm.openai(
    apiKey: 'your-openai-key',
  ).chatModel('gpt-4.1-mini');

  final result = await llm.generateTextCall(
    model: model,
    prompt: [
      llm.SystemPromptMessage.text('You are concise.'),
      llm.UserPromptMessage.text('Explain Dart in one sentence.'),
    ],
  );

  print(result.text);
}
```

Example file:
[quick_start.dart](example/01_getting_started/quick_start.dart)

## Provider-Owned Helper Boundaries

Some useful product features are intentionally not shared abstractions. Use the
focused provider helper when the semantics are provider-native:

| Product need | Modern path | Why it stays provider-owned |
| --- | --- | --- |
| OpenAI hosted files | `openai(...).files()` | Purpose values, hosted storage, and download semantics are OpenAI-specific |
| Anthropic beta files | `anthropic(...).files()` | File lifecycle, beta headers, and IDs are Anthropic-specific |
| OpenAI moderation | `openai(...).moderation()` | Category taxonomy and score meanings must map into app-owned policy |
| OpenAI image editing | `openai(...).imageModel(...).edit(...)` | File inputs, masks, fidelity, and output options are OpenAI-specific |
| Google image editing/variation | `google(...).imageModel(...).edit(...)` / `createVariation(...)` | Gemini edit inputs and variation prompts are Google-specific |
| Ollama installed models | `community.Ollama(...).catalog().listModels()` | Local runtime tags are not a shared remote model registry |
| ElevenLabs voices | `community.ElevenLabs(...).voices().listVoices()` | Voice IDs, preview URLs, labels, and tiers are provider-owned |

The rule is simple: keep the shared helper for the common model operation, and
use a provider-owned helper for lifecycle, policy, catalog, or edit workflows
whose request and result semantics differ materially by provider.

## Structured Output

Shared structured generation now lives above the main text-call layer through
`OutputSpec`, `generateTextCall(...)`, and `streamTextCall(...)`.

```dart
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/core.dart' as core;

Future<void> main() async {
  final model = llm.openai(
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
typed capability models such as `openai(...).embeddingModel(...)`.

```dart
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/core.dart' as core;

Future<void> main() async {
  final model = llm.openai(
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
[embeddings_stable.dart](example/02_core_features/embeddings_stable.dart)

## Streaming

The shared streaming boundary is `TextStreamEvent`.

```dart
import 'dart:io';

import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/core.dart' as core;

Future<void> main() async {
  final model = llm.deepSeek(
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
[streaming_chat.dart](example/02_core_features/streaming_chat.dart)

## Tool Calling

Tool definitions live in `llm_dart_provider`, and `llm_dart_core` re-exports them while providers map them into provider-owned request codecs.

```dart
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/core.dart' as core;

Future<void> main() async {
  final model = llm.openai(
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
[tool_calling.dart](example/02_core_features/tool_calling.dart)

## Reasoning

Reasoning is part of the common result and stream model, but replay fidelity remains provider-owned.

```dart
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/core.dart' as core;

Future<void> main() async {
  final model = llm.anthropic(
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
[reasoning_models.dart](example/03_advanced_features/reasoning_models.dart)

## Pure Dart Chat Runtime

For chat runtimes outside Flutter, prefer the focused root entrypoint:

```dart
import 'package:llm_dart/chat.dart';
```

This entrypoint re-exports `DefaultChatSession`, `DirectChatTransport`,
`HttpChatTransport`, `ChatRequestOptions`, `ChatMessageMapper`, and the stable
provider factories without pulling Flutter adapters into the root package
surface.

`ChatMessageMapper` now lives in `package:llm_dart/core.dart` as part of the
shared UI model layer, and remains available from `package:llm_dart/chat.dart`
for chat-runtime-oriented imports.

Runnable pure Dart runtime example:
[chat_runtime.dart](packages/llm_dart_chat/example/chat_runtime.dart)

Package guide:
[packages/llm_dart_chat/README.md](packages/llm_dart_chat/README.md)

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
        model: llm.openai(
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
[flutter_integration.dart](packages/llm_dart_flutter/example/flutter_integration.dart)

Package guide:
[packages/llm_dart_flutter/README.md](packages/llm_dart_flutter/README.md)

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

Import provider-owned option types and provider factories from focused
entrypoints such as `package:llm_dart/openai.dart`,
`package:llm_dart/xai.dart`, `package:llm_dart/openrouter.dart`,
`package:llm_dart/deepseek.dart`, or `package:llm_dart/google.dart`.
OpenAI-family providers still share the same internal transport adapter, but
dedicated focused entrypoints keep application imports provider-shaped.

OpenAI Responses example:

```dart
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/openai.dart' as openai;

Future<void> main() async {
  final model = openai.openai(
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
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/xai.dart' as xai;

Future<void> main() async {
  final model = xai.xai(
    apiKey: 'your-xai-key',
  ).chatModel('grok-3');

  final result = await core.generateTextCall(
    model: model,
    prompt: [
      core.UserPromptMessage.text('Find the latest Grok announcements.'),
    ],
    callOptions: const core.CallOptions(
      providerOptions: xai.XAIGenerateTextOptions(
        search: xai.XAILiveSearchOptions.autoWeb(),
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
- Prefer approved model IDs, app-owned history, and local attachment state as
  the default product path before introducing provider-managed assistants,
  remote files, or catalog discovery.
- Treat `LLMBuilder()`, `ai()`, and old root provider surfaces as
  compatibility APIs, not the target architecture.
- Treat the root Ollama and ElevenLabs surfaces as compatibility-first shells
  when the modern shared-capability path already exists in
  `llm_dart_community`.

## Current Reference Docs

- Post-closure roadmap:
  [docs/workstreams/2026-04-post-closure-priorities/README.md](docs/workstreams/2026-04-post-closure-priorities/README.md)
- Community provider workspace guide:
  [packages/llm_dart_community/README.md](packages/llm_dart_community/README.md)
- Migration guide:
  [38-migration-guide.md](docs/workstreams/2026-03-architecture-refactor/38-migration-guide.md)
- Architecture workstream index:
  [docs/workstreams/2026-03-architecture-refactor/README.md](docs/workstreams/2026-03-architecture-refactor/README.md)
- Provider UI extension contract:
  [docs/workstreams/2026-04-post-closure-priorities/01-provider-ui-extension-contract.md](docs/workstreams/2026-04-post-closure-priorities/01-provider-ui-extension-contract.md)
- Community provider public-entry guidance:
  [104-community-provider-public-entry-guidance.md](docs/workstreams/2026-03-architecture-refactor/104-community-provider-public-entry-guidance.md)
- Prompt normalization contract:
  [37-prompt-normalization-contract.md](docs/workstreams/2026-03-architecture-refactor/37-prompt-normalization-contract.md)
- Stream coverage matrix:
  [36-provider-stream-coverage-matrix.md](docs/workstreams/2026-03-architecture-refactor/36-provider-stream-coverage-matrix.md)

## Legacy Compatibility

The repository still keeps compatibility APIs through `package:llm_dart/legacy.dart`, including:

- `LLMBuilder()` and the deprecated `ai()` alias
- old root provider constructors
- compatibility adapters for legacy chat/config surfaces

These remain temporarily for migration inside the alpha preview line, but new
code should prefer the stable model API shown above.

If you still need the compatibility-era builder and broad legacy surface, prefer
the explicit import:

```dart
import 'package:llm_dart/legacy.dart';
```
