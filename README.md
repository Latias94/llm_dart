# LLM Dart Library

[![pub package](https://img.shields.io/pub/v/llm_dart.svg)](https://pub.dev/packages/llm_dart)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Dart](https://img.shields.io/badge/Dart-3.5.0+-blue.svg)](https://dart.dev)
[![likes](https://img.shields.io/pub/likes/llm_dart?logo=dart)](https://pub.dev/packages/llm_dart/score)
[![CI](https://github.com/Latias94/llm_dart/actions/workflows/ci.yml/badge.svg)](https://github.com/Latias94/llm_dart/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/Latias94/llm_dart/branch/main/graph/badge.svg)](https://codecov.io/gh/Latias94/llm_dart)

A modular Dart library for AI provider interactions. This library provides a unified interface for interacting with different AI providers using Dio for HTTP requests.

## Quick Navigation

| I want to... | Go to |
|--------------|-------|
| **Get started** | [Quick Start](#quick-start) |
| **Build a chatbot** | [Chatbot example](example/05_use_cases/chatbot.dart) |
| **Compare providers** | [Provider comparison](example/01_getting_started/provider_comparison.dart) |
| **Use streaming** | [Streaming example](example/02_core_features/streaming_chat.dart) |
| **Cancel requests** | [Cancellation demo](example/02_core_features/cancellation_demo.dart) |
| **Call functions** | [Tool calling](example/02_core_features/tool_calling.dart) |
| **Search the web** | [Web search](example/02_core_features/web_search.dart) |
| **Generate embeddings** | [Embeddings](example/02_core_features/embeddings.dart) |
| **Moderate content** | [Content moderation](example/02_core_features/content_moderation.dart) |
| **Access AI thinking** | [Reasoning models](example/03_advanced_features/reasoning_models.dart) |
| **Use MCP tools** | [MCP integration](example/06_mcp_integration/) |
| **Use local models** | [Ollama examples](example/04_providers/ollama/) |
| **See production app** | [Yumcha](https://github.com/Latias94/yumcha) |

## Features

- **Multi-provider support**: OpenAI, Anthropic, Google, DeepSeek, Groq, Ollama, xAI, ElevenLabs
- **OpenAI Responses API**: Stateful conversations with built-in tools (web search, file search, computer use)
- **Thinking process access**: Model reasoning for Claude, DeepSeek, Gemini, Ollama
- **Unified capabilities**: Chat, streaming, tools, audio, images, files, web search, embeddings
- **Request cancellation**: Cancel in-flight requests for chat, streaming, and API operations
- **MCP integration**: Model Context Protocol for external tool access
- **Content moderation**: Built-in safety and content filtering
- **Type-safe building**: Compile-time capability validation
- **Builder pattern**: Fluent configuration API
- **Production ready**: Error handling, retry logic, monitoring

## Supported Providers

| Provider | Chat | Streaming | Tools | Thinking | Audio | Image | Files | Web Search | Embeddings | Moderation | Notes |
|----------|------|-----------|-------|----------|-------|-------|-------|------------|------------|------------|-------|
| OpenAI | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | GPT models, DALL-E, o1 reasoning |
| Anthropic | ✅ | ✅ | ✅ | 🧠 | ❌ | ✅ | ✅ | ✅ | ❌ | ❌ | Claude models with thinking |
| Google | ✅ | ✅ | ✅ | 🧠 | ✅ | ✅ | ❌ | ✅ | ✅ | ❌ | Gemini models with reasoning |
| DeepSeek | ✅ | ✅ | ✅ | 🧠 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | DeepSeek reasoning models |
| Groq | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Ultra-fast inference |
| Ollama | ✅ | ✅ | ✅ | 🧠 | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | Local models, privacy-focused |
| xAI | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | Grok models with web search |
| ElevenLabs | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Advanced voice synthesis |

- **🧠 Thinking Process Support**: Access to model's reasoning and thought processes
- **🎵 Audio Support**: Text-to-speech, speech-to-text, and audio processing
- **🖼️ Image Support**: Image generation, editing, and multi-modal processing
- **📁 File Support**: File upload, management, and processing capabilities
- **🔍 Web Search**: Real-time web search across multiple providers
- **🧮 Embeddings**: Text embeddings for semantic search and similarity

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  llm_dart: ^0.11.0-rc.1
```

Then run:

```bash
dart pub get
```

Or install directly using:

```bash
dart pub add llm_dart
```

## Quick Start

### Recommended Imports

The project is now modularized. For new code, we recommend:

- High-level builder & helpers (Vercel AI SDK-style):
  - `import 'package:llm_dart/llm_dart.dart';`
- Core models, capabilities, config, agents:
  - `import 'package:llm_dart_core/llm_dart_core.dart';`
- Provider-specific features:
  - OpenAI: `import 'package:llm_dart_openai/llm_dart_openai.dart';`
  - Anthropic: `import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';`
  - Google: `import 'package:llm_dart_google/llm_dart_google.dart';`
  - DeepSeek: `import 'package:llm_dart_deepseek/llm_dart_deepseek.dart';`
  - Ollama: `import 'package:llm_dart_ollama/llm_dart_ollama.dart';`
  - xAI: `import 'package:llm_dart_xai/llm_dart_xai.dart';`
  - Groq: `import 'package:llm_dart_groq/llm_dart_groq.dart';`
  - Phind: `import 'package:llm_dart_phind/llm_dart_phind.dart';`
  - ElevenLabs: `import 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart';`
- Shared HTTP / provider utilities:
  - `import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';`

The legacy wrapper paths
`package:llm_dart/core/...` and `package:llm_dart/models/...`
are now marked as **deprecated** and will be removed in a future major release.
Please prefer the imports listed above for new code and refactors.

#### Legacy shims

For backwards compatibility, a few legacy shim entrypoints remain:

- `package:llm_dart/legacy/config_utils.dart`
- `package:llm_dart/legacy/openai_legacy.dart`
- `package:llm_dart/legacy/openai_compatible_defaults.dart`

These are all marked as `@Deprecated` and will be removed in a future
release. New code should use `llm_dart_core`, provider subpackages
(`llm_dart_openai`, `llm_dart_openai_compatible`, etc.), and
`llm_dart_provider_utils` instead.

### Basic Usage

```dart
import 'package:llm_dart/llm_dart.dart';

void main() async {
  // Method 1: Using the new ai() builder with provider methods
  final model = await ai()
      .openai()
      .apiKey('your-api-key')
      .model('gpt-4')
      .temperature(0.7)
      .buildLanguageModel();

  // Method 2: Using provider() with string ID (extensible)
  final model2 = await ai()
      .provider('openai')
      .apiKey('your-api-key')
      .model('gpt-4')
      .temperature(0.7)
      .buildLanguageModel();

  // Method 3: Using convenience function
  final directModel = await createProvider(
    providerId: 'openai',
    apiKey: 'your-api-key',
    model: 'gpt-4',
    temperature: 0.7,
  ).then((chat) => chat.buildLanguageModel());

  // Simple chat
  final prompt = ChatPromptBuilder.user().text('Hello, world!').build();
  final response = await generateTextWithModel(
    model,
    promptMessages: [prompt],
  );
  print(response.text);

  // Access thinking process (for supported models)
  if (response.thinking != null) {
    print('Model thinking: ${response.thinking}');
  }
}
```

### Prompt Building Patterns

For most use cases, prefer the structured prompt model via `ChatPromptBuilder` and `ModelMessage`:

```dart
// Build a structured, multi-part prompt
final prompt = ChatPromptBuilder.user()
    .text('Describe this image in detail.')
    .imageUrl('https://example.com/cat.png')
    .build();

// Send it via the model-centric helper (preferred)
final model = createOpenAI(apiKey: 'sk-...').chat('gpt-4o-mini');
final result = await generateTextWithModel(
  model,
  promptMessages: [prompt],
);

print(result.text);
```

**Prompt-first 推荐**：默认使用 `ChatPromptBuilder` + `ModelMessage`；`ChatMessage` 仅为兼容旧代码的便捷封装。

### Streaming with DeepSeek Reasoning

```dart
import 'dart:io';
import 'package:llm_dart/llm_dart.dart';

void main() async {
  // Create DeepSeek model for streaming with thinking
  final model = await ai()
      .deepseek()
      .apiKey('your-deepseek-key')
      .model('deepseek-reasoner')
      .temperature(0.7)
      .buildLanguageModel();

  final prompt =
      ChatPromptBuilder.user().text('What is 15 + 27? Show your work.').build();

  // Stream with real-time thinking process
  await for (final event
      in streamTextWithModel(model, promptMessages: [prompt])) {
    switch (event) {
      case ThinkingDeltaEvent(delta: final delta):
        // Show AI's thinking process in gray
        stdout.write('\x1B[90m$delta\x1B[0m');
        break;
      case TextDeltaEvent(delta: final delta):
        // Show final answer
        stdout.write(delta);
        break;
      case CompletionEvent(response: final response):
        print('\n✅ Completed');
        if (response.usage != null) {
          print('Tokens: ${response.usage!.totalTokens}');
        }
        break;
      case ErrorEvent(error: final error):
        print('Error: $error');
        break;
    }
  }
}
```

### LanguageModel-style usage (Vercel AI SDK inspired)

```dart
import 'package:llm_dart/llm_dart.dart';

Future<void> main() async {
  // Configure provider + model in one step
  final model = await ai()
      .use('deepseek:deepseek-chat')
      .apiKey('your-deepseek-key')
      .buildLanguageModel();

  // Generate a non-streaming response
  final result = await model.generateText([
    ChatMessage.user('Explain what a binary search tree is.'),
  ]);

  print('Text: ${result.text}');
  if (result.hasThinking) {
    print('Thinking: ${result.thinking}');
  }

  // Stream a response using high-level stream parts
  final streamModel = await ai()
      .use('deepseek:deepseek-reasoner')
      .apiKey('your-deepseek-key')
      .buildLanguageModel();

  await for (final part in streamModel.streamTextParts([
    ChatMessage.user('What is 15 + 27? Show your work.'),
  ])) {
    switch (part) {
      case StreamThinkingDelta(delta: final delta):
        stdout.write('\x1B[90m$delta\x1B[0m');
        break;
      case StreamTextDelta(delta: final delta):
        stdout.write(delta);
        break;
      case StreamFinish(result: final result):
        print('\nCompleted with ${result.usage?.totalTokens} tokens.');
        break;
      default:
        // Ignore other parts for this simple example (tool calls, etc.).
        break;
    }
  }
}
```

### Structured outputs with OutputSpec & generateObject

Use `OutputSpec` to define JSON schemas and typed parsers, then call `generateObject` to get strongly-typed results:

```dart
import 'package:llm_dart/llm_dart.dart';

class UserProfile {
  final String name;
  final int age;

  const UserProfile(this.name, this.age);

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      json['name'] as String,
      json['age'] as int,
    );
  }
}

Future<void> main() async {
  final output = OutputSpec<UserProfile>.object(
    name: 'UserProfile',
    properties: {
      'name': ParameterProperty(
        propertyType: 'string',
        description: 'User name',
      ),
      'age': ParameterProperty(
        propertyType: 'integer',
        description: 'Age in years',
      ),
    },
    fromJson: UserProfile.fromJson,
  );

  final result = await generateObject<UserProfile>(
    model: 'openai:gpt-4o-mini',
    apiKey: 'your-openai-key',
    output: output,
    prompt: 'Return a JSON user profile with name and age.',
  );

  print('User: ${result.object.name}, age: ${result.object.age}');
}
```

For simple scalar outputs you can use the built-in helpers:

```dart
final intOutput = OutputSpec<int>.intValue();
final boolOutput = OutputSpec<bool>.boolValue();
final listOfUsers = OutputSpec<List<UserProfile>>.listOf(
  itemOutput: output, // the UserProfile spec from above
);
```

### Agent-style tool loop with ToolLoopAgent

Use `ToolLoopAgent` to run a minimal tool loop on top of `LanguageModel` and `ExecutableTool`:

```dart
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

Future<void> main() async {
  final model = await ai()
      .use('openai:gpt-4o-mini')
      .apiKey('your-openai-key')
      .buildLanguageModel();

  final tools = <String, ExecutableTool>{
    'get_weather': ExecutableTool(
      schema: Tool.function(
        name: 'get_weather',
        description: 'Get the weather for a city',
        parameters: ParametersSchema(
          schemaType: 'object',
          properties: {
            'city': ParameterProperty(
              propertyType: 'string',
              description: 'City name',
            ),
          },
          required: const ['city'],
        ),
      ),
      execute: (args) async {
        final city = args['city'] as String;
        // Call your real weather API here
        return {'city': city, 'temperatureC': 24.5};
      },
    ),
  };

  final input = AgentInput(
    model: model,
    messages: [
      ChatMessage.user(
        'Use the get_weather tool to fetch the weather for Tokyo, '
        'then explain the result.',
      ),
    ],
    tools: tools,
  );

  const agent = ToolLoopAgent();
  final traced = await agent.runTextWithSteps(input);

  print('Final answer: ${traced.result.text}');
  for (final step in traced.steps) {
    print('Step #${step.iteration}: '
        'model call with ${step.toolCalls.length} tool calls');
  }
}
```

### Streaming structured outputs with streamObject (MVP)

If you want both streaming events and a structured result, use `streamObject`:

```dart
import 'package:llm_dart/llm_dart.dart';

Future<void> main() async {
  final output = OutputSpec<int>.intValue();

  final streamResult = streamObject<int>(
    model: 'openai:gpt-4o-mini',
    apiKey: 'your-openai-key',
    output: output,
    prompt: 'Respond with a JSON object {"value": 123}',
  );

  // Consume streaming events (for UI / logs)
  await for (final event in streamResult.events) {
    if (event is TextDeltaEvent) {
      stdout.write(event.delta);
    }
  }

  // Await the structured result once the stream completes
  final objectResult = await streamResult.asObject;
  print('\nParsed value: ${objectResult.object}');
}
```

### DeepSeek text completion & FIM

Use DeepSeek as a lightweight text completion / FIM provider via the `CompletionCapability` implemented by `DeepSeekProvider`:

```dart
import 'package:llm_dart/llm_dart.dart';

Future<void> main() async {
  final provider = await ai()
      .deepseek()
      .apiKey('your-deepseek-key')
      .model('deepseek-chat')
      .build();

  // Plain text completion
  final completion = await provider.complete(
    const CompletionRequest(
      prompt: 'Explain what a binary search tree is.',
      maxTokens: 256,
      temperature: 0.7,
    ),
  );

  print('Completion: ${completion.text}');

  // FIM-style code completion (prefix + suffix)
  final fim = await provider.completeFim(
    prefix: 'def compute_gcd(a, b):',
    suffix: '    return result',
    maxTokens: 128,
    temperature: 0.2,
  );

  print('FIM completion: ${fim.text}');
}
```

### 🧠 Thinking Process Access

Access the model's internal reasoning and thought processes:

```dart
// Claude with thinking
final claudeProvider = await ai()
    .anthropic()
    .apiKey('your-anthropic-key')
    .model('claude-sonnet-4-20250514')
    .build();

final messages = [
  ChatMessage.user('Solve this step by step: What is 15% of 240?')
];

final response = await claudeProvider.chat(messages);

// Access the final answer
print('Answer: ${response.text}');

// Access the thinking process
if (response.thinking != null) {
  print('Claude\'s thinking process:');
  print(response.thinking);
}

// DeepSeek with reasoning
final deepseekProvider = await ai()
    .deepseek()
    .apiKey('your-deepseek-key')
    .model('deepseek-reasoner')
    .temperature(0.7)
    .build();

final reasoningResponse = await deepseekProvider.chat(messages);
print('DeepSeek reasoning: ${reasoningResponse.thinking}');
```

### Using Ollama (local multimodal & admin)

Run Ollama locally:

```bash
ollama serve
ollama pull llava:latest
```

Multimodal chat with local Ollama (text + image):

```dart
import 'dart:io';
import 'package:llm_dart/llm_dart.dart';

void main() async {
  // Create a provider for a local Ollama instance
  final provider = OllamaProvider(
    const OllamaConfig(
      baseUrl: 'http://localhost:11434/',
      model: 'llava:latest',
    ),
  );

  // Load an image into memory
  final imageBytes = await File('cat.png').readAsBytes();

  final messages = [
    ChatMessage.image(
      role: ChatRole.user,
      mime: ImageMime.png,
      data: imageBytes,
      content: 'Describe this image in detail.',
    ),
  ];

  final response = await provider.chat(messages);
  print(response.text);
}
```

### Recommended Usage: Vercel-style vs Builder-style

There are two primary ways to use `llm_dart`, inspired by the Vercel AI SDK:

| Scenario | Recommended API | Example |
|---------|-----------------|---------|
| **Single provider, model-centric** | Vercel-style factories + `LanguageModel` | `createOpenAI()`, `createAnthropic()`, `generateTextWithModel()` |
| **Multi-provider, config-centric** | `LLMBuilder` + provider registry | `ai().use('openai:gpt-4o')`, `ai().deepseek()...build()` |
| **Quick one-off calls** | High-level helpers | `generateText()`, `streamTextParts()`, `generateObject()` |

**1. Vercel-style (model-centric)**

Use provider factories that mirror Vercel AI SDK exports. You configure a provider once, then get `LanguageModel` / capability objects:

```dart
import 'package:llm_dart/llm_dart.dart';

Future<void> main() async {
  // OpenAI
  final openai = createOpenAI(apiKey: 'sk-...');
  final gpt4o = openai.chat('gpt-4o');

  final result = await generateTextWithModel(
    gpt4o,
    messages: [ChatMessage.user('Hello from Vercel-style API')],
  );
  print(result.text);

  // Anthropic
  final claude = createAnthropic(apiKey: 'sk-ant-...')
      .chat('claude-sonnet-4-20250514');

  // Google (Gemini)
  final gemini = createGoogleGenerativeAI(apiKey: 'AIza-...')
      .chat('gemini-1.5-flash');

  // DeepSeek
  final deepseek = createDeepSeek(apiKey: 'sk-deepseek-...')
      .chat('deepseek-chat');

  // xAI (Grok)
  final grok = createXAI(apiKey: 'xai-...')
      .chat('grok-3');
}
```

This style is ideal when:

- You prefer **model-centric** code (`openai.chat('gpt-4o')`) over builder-style.
- You mostly stick to a small number of providers/models.
- You want the API surface to feel close to the Vercel AI SDK.

**2. Builder-style (provider registry)**

Use `ai()` and `LLMBuilder` when you want more dynamic configuration, multiple providers, or advanced features:

```dart
// Model string "provider:model" (Vercel-style)
final model = await ai()
    .use('openai:gpt-4o')
    .apiKey('sk-...')
    .buildLanguageModel();

final result = await model.generateText([
  ChatMessage.user('Hello from builder-style API'),
]);

// Provider-specific builder helpers
final deepseekProvider = await ai()
    .deepseek()
    .apiKey('sk-deepseek-...')
    .model('deepseek-reasoner')
    .build();
```

This style is ideal when:

- You need to **dynamically choose providers/models** at runtime.
- You want to use the **registry + capability system** (`LLMCapability`) and richer HTTP / logging / proxy config.
- You are building higher-level abstractions (agents, tool loops, etc.) on top of `LanguageModel` or `ChatCapability`.

**3. High-level helpers**

For one-off calls where you don't need to keep a provider/model object, use:

- `generateText(model: 'openai:gpt-4o', apiKey: ...)`
- `streamTextParts(model: 'deepseek:deepseek-reasoner', apiKey: ...)`
- `generateObject<T>(model: 'openai:gpt-4o-mini', ...)`

These map to builder-style under the hood but provide a concise API for scripting and quick experiments. Use `streamTextParts` if you want a Vercel-style stream of text/thinking/tool parts; the lower-level `streamText` that exposes raw `ChatStreamEvent` is still available for advanced scenarios.

Manage local Ollama models with `OllamaAdmin`:

```dart
import 'package:llm_dart/llm_dart.dart';

void main() async {
  // Connect to a local Ollama server
  final admin = OllamaAdmin.local(
    baseUrl: 'http://localhost:11434',
    model: 'llama3.2',
  );

  // List local models
  final localModels = await admin.listLocalModels();
  for (final model in localModels) {
    print('Local model: ${model.id}');
  }

  // List running models
  final running = await admin.listRunningModels();
  print('Running models: ${running.length}');

  // Show model details
  final info = await admin.showModel('llama3.2');
  print('llama3.2 details: ${info['details']}');

  // Pull a model if needed
  await admin.pullModel('llama3.2');

  // Get Ollama server version
  final version = await admin.serverVersion();
  print('Ollama version: ${version['version']}');
}
```

### Web Search

```dart
// Enable web search across providers
final provider = await ai()
    .xai()
    .apiKey('your-xai-key')
    .model('grok-3')
    .enableWebSearch()
    .build();

final response = await provider.chat([
  ChatMessage.user('What are the latest AI developments this week?')
]);
print(response.text);

// Provider-specific configurations
final anthropicProvider = await ai()
    .anthropic()
    .apiKey('your-key')
    .webSearch(
      mode: 'web_search_20250305', // specify Claude's web search type
      maxUses: 3,
      allowedDomains: ['wikipedia.org', 'arxiv.org'],
      location: WebSearchLocation.sanFrancisco(),
    )
    .build();
```

### Embeddings

```dart
// Generate embeddings for semantic search
final provider = await ai()
    .openai()
    .apiKey('your-key')
    .buildEmbedding();

final embeddings = await provider.embed([
  'Machine learning fundamentals',
  'Deep learning neural networks',
  'Natural language processing',
]);

// Use embeddings for similarity search
final queryEmbedding = await provider.embed(['AI research']);
// Calculate cosine similarity with your embeddings
```

### Content Moderation

```dart
// Moderate content for safety
final provider = await ai()
    .openai()
    .apiKey('your-key')
    .buildModeration();

final result = await provider.moderate(
  ModerationRequest(input: 'User generated content to check')
);

if (result.results.first.flagged) {
  print('Content flagged for review');
} else {
  print('Content is safe');
}
```

### Tool Calling

```dart
final tools = [
  Tool.function(
    name: 'get_weather',
    description: 'Get weather for a location',
    parameters: ParametersSchema(
      schemaType: 'object',
      properties: {
        'location': ParameterProperty(
          propertyType: 'string',
          description: 'City name',
        ),
      },
      required: ['location'],
    ),
  ),
];

final response = await provider.chatWithTools(messages, tools);
if (response.toolCalls != null) {
  for (final call in response.toolCalls!) {
    print('Tool: ${call.function.name}');
    print('Args: ${call.function.arguments}');
  }
}
```

## Advanced Usage: Structured Prompts (ModelMessage + ChatContentPart)

Under the hood all providers convert the legacy `ChatMessage` model into the structured `ModelMessage` model, so:

- You can keep using `ChatMessage.user(...)` / `ChatMessage.image(...)` for simple text or single‑attachment prompts.
- For **multi‑part / multi‑modal** prompts (text + multiple images/files/audio/video + tool results), use the structured prompt model:
  - `ModelMessage` as the provider‑agnostic prompt.
  - `ChatContentPart` as building blocks (text, files, tool calls/results).
  - `ChatPromptBuilder` as a fluent helper to construct them.

### When to use the structured prompt model

- You need multiple parts in a single logical message (e.g. “describe these three images together”).
- You want to share the **same prompt** across different providers (OpenAI, Anthropic, Google, DeepSeek, Ollama, Phind) without rewriting payloads.
- You are building advanced features like tool use + tool result chaining with rich context.

### Building a multi‑modal prompt once, using it everywhere

```dart
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

Future<void> describeImageAcrossProviders(List<int> imageBytes) async {
  // 1) Build a structured user prompt: text + inline image.
  final prompt = ChatPromptBuilder.user()
      .text('Describe this image in one paragraph.')
      .imageBytes(
        imageBytes,
        mime: ImageMime.png,
        filename: 'example.png',
      )
      .build();

  // 2) Use the same structured prompt with different providers via LanguageModel.
  final openai = await ai()
      .openai()
      .apiKey('OPENAI_KEY')
      .model('gpt-4o-mini')
      .build();

  final anthropic = await ai()
      .anthropic()
      .apiKey('ANTHROPIC_KEY')
      .model('claude-3-5-sonnet-20241022')
      .build();

  final google = await ai()
      .google()
      .apiKey('GOOGLE_KEY')
      .model('gemini-1.5-flash')
      .build();

  final openaiResult = await generateTextWithModel(
    openai,
    promptMessages: [prompt],
  );
  final anthropicResult = await generateTextWithModel(
    anthropic,
    promptMessages: [prompt],
  );
  final googleResult = await generateTextWithModel(
    google,
    promptMessages: [prompt],
  );

  print('OpenAI: ${openaiResult.text}');
  print('Anthropic: ${anthropicResult.text}');
  print('Google: ${googleResult.text}');
}
```

Each provider maps the same `ModelMessage` to its native format:

- OpenAI / OpenAI‑compatible: `messages[].content` with `text` + `image_url` / `input_*` parts.
- Anthropic: `messages[].content` blocks with `text` + `image`/`document` + tool use/result blocks.
- Google Gemini: `contents[].parts` with `text` + `inlineData` or uploaded file references.

### Tool calls and tool results with structured prompts

You can also drive tool use round‑trips using `ToolCallContentPart` and `ToolResultContentPart`:

```dart
import 'dart:convert';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

Future<void> toolRoundTrip(ChatCapability provider) async {
  final tools = [
    Tool.function(
      name: 'get_weather',
      description: 'Get the current weather for a city.',
      parameters: ParametersSchema(
        schemaType: 'object',
        properties: {
          'city': ParameterProperty(
            propertyType: 'string',
            description: 'City name, e.g. \"San Francisco\"',
          ),
        },
        required: ['city'],
      ),
    ),
  ];

  // 1) Ask the model to call the tool.
  final messages = [ChatMessage.user('What is the weather in Tokyo?')];
  final response = await provider.chatWithTools(messages, tools);
  final calls = response.toolCalls ?? [];
  if (calls.isEmpty) return;

  final toolCall = calls.first;
  final args = jsonDecode(toolCall.function.arguments) as Map<String, dynamic>;

  // 2) Execute the tool locally.
  final weather = {
    'city': args['city'],
    'temperatureC': 20,
    'condition': 'sunny',
  };

  // 3) Build a structured tool result and send back.
  final toolResultPrompt = ModelMessage(
    role: ChatRole.user,
    parts: [
      ToolResultContentPart(
        toolCallId: toolCall.id,
        toolName: toolCall.function.name,
        payload: ToolResultJsonPayload(weather),
      ),
    ],
  );

  final followupMessages = [
    ...messages,
    ChatMessage.fromPromptMessage(toolResultPrompt),
  ];

  final followupResponse =
      await provider.chatWithTools(followupMessages, tools);
  print('Final answer: ${followupResponse.text}');
}
```

推荐实践：

- 简单场景：继续用 `ChatMessage.user/assistant/system` 这些便捷构造方法。
- 复杂场景（多模态 + 工具 + 多部分）：用 `ChatPromptBuilder` 构造 `ModelMessage`，再通过：
  - `generateTextWithModel(model, promptMessages: [...])`
  - 或代理型 API（如 `runAgentPromptText` / `runAgentPromptObject`）
  将结构化 prompt 传递给模型。

## Provider Examples

### OpenAI

```dart
// Vercel-style (model-centric)
final openai = createOpenAI(apiKey: 'sk-...');
final gpt4o = openai.chat('gpt-4o');

final result = await generateTextWithModel(
  gpt4o,
  messages: [ChatMessage.user('Hello from OpenAI')],
);
print(result.text);

// Builder / registry-style
final provider = await createProvider(
  providerId: 'openai',
  apiKey: 'sk-...',
  model: 'gpt-4',
  temperature: 0.7,
  // For reasoning models (o1 / o3 / Gemini etc.)
  // You can also use LLMBuilder.reasoningEffort(...) which writes this key.
  extensions: {LLMConfigKeys.reasoningEffort: 'medium'},
);
```

#### Responses API (Stateful Conversations)

OpenAI's new Responses API provides stateful conversation management with built-in tools:

```dart
final provider = await ai()
    .openai((openai) => openai
        .useResponsesAPI()
        .webSearchTool()
        .fileSearchTool(vectorStoreIds: ['vs_123']))
    .apiKey('your-key')
    .model('gpt-4o')
    .build();

// Cast to access stateful features
final responsesProvider = provider as OpenAIProvider;
final responses = responsesProvider.responses!;

// Stateful conversation with automatic context preservation
final response1 = await responses.chat([
  ChatMessage.user('My name is Alice. Tell me about quantum computing'),
]);

final responseId = (response1 as OpenAIResponsesResponse).responseId;
final response2 = await responses.continueConversation(responseId!, [
  ChatMessage.user('Remember my name and explain it simply'),
]);

// Background processing for long tasks
final backgroundTask = await responses.chatWithToolsBackground([
  ChatMessage.user('Write a detailed research report'),
], null);

// Response lifecycle management
await responses.getResponse('resp_123');
await responses.deleteResponse('resp_123');
await responses.cancelResponse('resp_123');
```

### Anthropic (with Thinking Process)

```dart
// Vercel-style (model-centric)
final claudeModel = createAnthropic(apiKey: 'sk-ant-...')
    .chat('claude-sonnet-4-20250514');

final result = await generateTextWithModel(
  claudeModel,
  messages: [ChatMessage.user('Explain quantum computing step by step')],
);
print('Final answer: ${result.text}');
if (result.thinking != null) {
  print('Claude\'s reasoning: ${result.thinking}');
}

// Builder-style
final provider = await ai()
    .anthropic()
    .apiKey('sk-ant-...')
    .model('claude-sonnet-4-20250514')
    .build();

final response = await provider.chat([
  ChatMessage.user('Explain quantum computing step by step')
]);

// Access Claude's thinking process
print('Final answer: ${response.text}');
if (response.thinking != null) {
  print('Claude\'s reasoning: ${response.thinking}');
}
```

### DeepSeek (with Reasoning)

```dart
// Vercel-style (model-centric)
final deepseekModel = createDeepSeek(apiKey: 'your-deepseek-key')
    .chat('deepseek-reasoner');

final result = await generateTextWithModel(
  deepseekModel,
  messages: [ChatMessage.user('Solve this logic puzzle step by step')],
);
print('Solution: ${result.text}');
if (result.thinking != null) {
  print('DeepSeek\'s reasoning: ${result.thinking}');
}

// Builder-style
final provider = await ai()
    .deepseek()
    .apiKey('your-deepseek-key')
    .model('deepseek-reasoner')
    .build();

final response = await provider.chat([
  ChatMessage.user('Solve this logic puzzle step by step')
]);

// Access DeepSeek's reasoning process
print('Solution: ${response.text}');
if (response.thinking != null) {
  print('DeepSeek\'s reasoning: ${response.thinking}');
}
```

### Ollama (with Thinking Process)

```dart
// Ollama with thinking enabled
final provider = await ai()
    .ollama()
    .baseUrl('http://localhost:11434')
    .model('gpt-oss:latest') // Reasoning model
    .reasoning(true)         // Enable reasoning process
    .build();

final response = await provider.chat([
  ChatMessage.user('Solve this math problem step by step: 15 * 23 + 7')
]);

// Access Ollama's thinking process
if (response.thinking != null) {
  print('Ollama\'s reasoning: ${response.thinking}');
}
```

### xAI (with Web Search)

```dart
// Vercel-style (model-centric)
final grokModel = createXAI(apiKey: 'your-xai-key')
    .chat('grok-3');

final webSearchResult = await generateTextWithModel(
  grokModel,
  messages: [
    ChatMessage.user('What is the current stock price of NVIDIA?'),
  ],
);
print(webSearchResult.text);

// Builder-style
final provider = await ai()
    .xai()
    .apiKey('your-xai-key')
    .model('grok-3')
    .enableWebSearch()
    .build();

// Real-time web search
final response = await provider.chat([
  ChatMessage.user('What is the current stock price of NVIDIA?')
]);

// News search with date filtering
final newsProvider = await ai()
    .xai()
    .apiKey('your-xai-key')
    .newsSearch(
      maxResults: 5,
      fromDate: '2024-12-01',
    )
    .build();
```

### Google (with Embeddings)

```dart
// Vercel-style (model-centric)
final google = createGoogleGenerativeAI(apiKey: 'your-google-key');
final embeddingModel = google.embedding('text-embedding-004');

final embeddings = await embeddingModel.embed([
  'Text to embed for semantic search',
  'Another piece of text',
]);

// Builder-style
final provider = await ai()
    .google()
    .apiKey('your-google-key')
    .model('gemini-2.0-flash-exp')
    .buildEmbedding();

final embeddings = await provider.embed([
  'Text to embed for semantic search',
  'Another piece of text',
]);

// Use for similarity search, clustering, etc.
```

### ElevenLabs (Audio Processing)

```dart
// Use buildAudio() for type-safe audio capability building
final audioProvider = await ai()
    .elevenlabs()
    .apiKey('your-elevenlabs-key')
    .voiceId('JBFqnCBsd6RMkjVDRZzb') // George voice
    .stability(0.7)
    .similarityBoost(0.9)
    .style(0.1)
    .buildAudio(); // Type-safe audio capability building

// Direct usage without type casting
final features = audioProvider.supportedFeatures;
print('Supports TTS: ${features.contains(AudioFeature.textToSpeech)}');

// Text to speech with advanced options
final ttsResponse = await audioProvider.textToSpeech(TTSRequest(
  text: 'Hello world! This is ElevenLabs speaking.',
  voice: 'JBFqnCBsd6RMkjVDRZzb',
  model: 'eleven_multilingual_v2',
  format: 'mp3_44100_128',
  includeTimestamps: true,
));
await File('output.mp3').writeAsBytes(ttsResponse.audioData);

// Speech to text (if supported)
if (features.contains(AudioFeature.speechToText)) {
  final audioData = await File('input.mp3').readAsBytes();
  final sttResponse = await audioProvider.speechToText(
    STTRequest.fromAudio(audioData, model: 'scribe_v1')
  );
  print(sttResponse.text);
}

// Convenience methods
final quickSpeech = await audioProvider.speech('Quick TTS');
final quickTranscription = await audioProvider.transcribeFile('audio.mp3');
```

## Request Cancellation

Cancel in-flight requests for better resource management and user experience:

```dart
import 'package:llm_dart/llm_dart.dart';

// Create a cancellation token source
final cancelSource = CancellationTokenSource();
final cancelToken = cancelSource.token;

// Start a long-running request
final responseFuture = provider.chat(
  [ChatMessage.user('Write a very long essay...')],
  cancelToken: cancelToken,
);

// Cancel it later (e.g., user navigates away)
cancelSource.cancel('User cancelled');

// Handle cancellation
try {
  await responseFuture;
} on CancelledError catch (e) {
  print('Request cancelled: ${e.message}');
} catch (e) {
  if (CancellationHelper.isCancelled(e)) {
    print('Cancelled: ${CancellationHelper.getCancellationReason(e)}');
  }
}

// Cancel streaming responses
await for (final event in provider.chatStream(messages, cancelToken: cancelToken)) {
  switch (event) {
    case TextDeltaEvent(delta: final delta):
      print(delta);
      // Cancel after first token
      cancelToken.cancel('Got enough data');
      break;
    case ErrorEvent(error: final error):
      if (CancellationHelper.isCancelled(error)) {
        print('Stream cancelled');
      }
      break;
    // ... other events
  }
}
```

**Supported operations**: `chat()`, `chatStream()`, `models()`, and all other provider operations.

See [cancellation_demo.dart](example/02_core_features/cancellation_demo.dart) for comprehensive examples.

## Error Handling

```dart
try {
  final response = await provider.chatWithTools(messages, null);
  print(response.text);
} on CancelledError catch (e) {
  print('Request cancelled: $e');
} on AuthError catch (e) {
  print('Authentication failed: $e');
} on ProviderError catch (e) {
  print('Provider error: $e');
} on HttpError catch (e) {
  print('Network error: $e');
} catch (e) {
  print('Unexpected error: $e');
}
```

## Architecture

### Capability-Based Design

The library uses a capability-based interface design instead of monolithic "god interfaces":

```dart
// Core capabilities
abstract class ChatCapability {
  Future<ChatResponse> chat(List<ChatMessage> messages);
  Stream<ChatStreamEvent> chatStream(List<ChatMessage> messages);
}

abstract class EmbeddingCapability {
  Future<List<List<double>>> embed(List<String> input);
}

abstract class WebSearchCapability {
  // Web search is integrated into chat - no separate methods needed
  // Providers handle search automatically when enabled
}

abstract class ModerationCapability {
  Future<ModerationResponse> moderate(ModerationRequest request);
}

// Providers implement only the capabilities they support
class OpenAIProvider implements
    ChatCapability,
    EmbeddingCapability,
    WebSearchCapability,
    ModerationCapability {
  // Implementation
}
```

### Type-Safe Capability Building

The library provides capability factory methods for compile-time type safety:

```dart
// Old approach - runtime type casting
final provider = await ai().openai().apiKey(apiKey).build();
if (provider is! AudioCapability) {
  throw Exception('Audio not supported');
}
final audioProvider = provider as AudioCapability; // Runtime cast!

// New approach - compile-time type safety
final audioProvider = await ai().openai().apiKey(apiKey).buildAudio();
// Direct usage without type casting - guaranteed AudioCapability!

// Available factory methods:
final chatProvider = await ai().openai().build(); // Returns ChatCapability
final audioProvider = await ai().openai().buildAudio();
final imageProvider = await ai().openai().buildImageGeneration();
final embeddingProvider = await ai().openai().buildEmbedding();
final fileProvider = await ai().openai().buildFileManagement();
final moderationProvider = await ai().openai().buildModeration();
final assistantProvider = await ai().openai().buildAssistant();
final modelProvider = await ai().openai().buildModelListing();

// Web search is enabled through configuration, not a separate capability
final webSearchProvider = await ai().openai().enableWebSearch().build();

// Clear error messages for unsupported capabilities
try {
  final audioProvider = await ai().groq().buildAudio(); // Groq doesn't support audio
} catch (e) {
  print(e); // UnsupportedCapabilityError: Provider "groq" does not support audio capabilities. Supported providers: OpenAI, ElevenLabs
}
```

### Provider Registry

The library includes an extensible provider registry system:

```dart
// Check available providers
final providers = LLMProviderRegistry.getRegisteredProviders();
print('Available: $providers'); // ['openai', 'anthropic', ...]

// Check capabilities
final supportsChat = LLMProviderRegistry.supportsCapability('openai', LLMCapability.chat);
print('OpenAI supports chat: $supportsChat'); // true

// Create providers dynamically
final provider = LLMProviderRegistry.createProvider('openai', config);
```

### Custom Providers

You can register custom providers:

```dart
// Create a custom provider factory
class MyCustomProviderFactory implements LLMProviderFactory<ChatCapability> {
  @override
  String get providerId => 'my_custom';

  @override
  Set<LLMCapability> get supportedCapabilities => {LLMCapability.chat};

  @override
  ChatCapability create(LLMConfig config) => MyCustomProvider(config);

  // ... other methods
}

// Register it
LLMProviderRegistry.register(MyCustomProviderFactory());

// Use it
final provider = await ai().provider('my_custom').build();
```

## Configuration

All providers support common configuration options:

- `apiKey`: API key for authentication
- `baseUrl`: Custom API endpoint
- `model`: Model name to use
- `temperature`: Sampling temperature (0.0-1.0)
- `maxTokens`: Maximum tokens to generate
- `systemPrompt`: System message
- `timeout`: Request timeout
- `topP`, `topK`: Sampling parameters

### Provider-Specific Extensions

Use the extension system for provider-specific features:

```dart
import 'package:llm_dart/llm_dart.dart';

final provider = await ai()
    .openai()
    .apiKey('your-key')
    .model('gpt-4')
    .reasoningEffort(ReasoningEffort.high)  // OpenAI-specific
    .extension('voice', 'alloy')           // OpenAI TTS voice
    .build();
```

## OpenAI (Vercel AI-style API)

In addition to the builder-based API, `llm_dart` provides an OpenAI interface
that closely mirrors the Vercel AI SDK:

```dart
import 'package:llm_dart/llm_dart.dart';

Future<void> main() async {
  final openai = createOpenAI(
    apiKey: 'sk-...',                    // required
    baseUrl: 'https://api.openai.com/v1/', // optional override
  );

  // Chat Completions-style model
  final chatModel = openai.chat('gpt-4o');

  final result = await generateTextWithModel(
    model: chatModel,
    messages: [
      ChatMessage.user('Tell me a joke about Dart'),
    ],
  );

  print(result.text);
}
```

### Using the OpenAI Responses API

You can also create a model backed by the OpenAI Responses API:

```dart
import 'package:llm_dart/llm_dart.dart';

Future<void> main() async {
  final openai = createOpenAI(apiKey: 'sk-...');

  final responsesModel = openai.responses('gpt-4.1-mini');

  final result = await generateObjectWithModel<Map<String, dynamic>>(
    model: responsesModel,
    output: OutputSpec<Map<String, dynamic>>(
      format: StructuredOutputFormat(
        name: 'WeatherInfo',
        schema: {
          'type': 'object',
          'properties': {
            'location': {'type': 'string'},
            'temperature': {'type': 'number'},
          },
          'required': ['location', 'temperature'],
        },
      ),
      fromJson: (json) => json,
    ),
    messages: [
      ChatMessage.user('Give me the current temperature in Paris.'),
    ],
  );

  print(result.object);
}
```

### Built-in tools (web search, file search, computer use)

The OpenAI interface exposes built-in tools similar to `openai.tools` in the
Vercel AI SDK:

```dart
import 'package:llm_dart/llm_dart.dart';

Future<void> main() async {
  final openai = createOpenAI(apiKey: 'sk-...');

  final webSearchTool = openai.tools.webSearch();

  final model = openai.responses('gpt-4o');

  final result = await runAgentText(
    model: model,
    messages: [
      ChatMessage.user('What are the latest updates on Dart 3?'),
    ],
    tools: {
      'web_search': ExecutableTool.fromFunction(
        tool: Tool.function(
          name: 'web_search',
          description: 'Search the web for up-to-date information.',
          parameters: ParametersSchema(
            schemaType: 'object',
            properties: {
              'query': ParameterProperty(
                propertyType: 'string',
                description: 'Search query',
              ),
            },
            required: ['query'],
          ),
        ),
        function: (args) async {
          // Integrate with your own web search or proxy service here.
          return 'Search results for: ${args['query']}';
        },
      ),
    },
  );

  print(result.text);
}
```

This approach makes it easier to migrate from the Vercel AI SDK to `llm_dart`
while keeping a similar mental model: create a provider, then create models
for chat, responses, embeddings, images, or audio, and pass them into
high-level helpers like `generateTextWithModel` or `runAgentText`.

## Examples

See the [example directory](example) for comprehensive examples:

**Getting Started**: [quick_start.dart](example/01_getting_started/quick_start.dart), [provider_comparison.dart](example/01_getting_started/provider_comparison.dart)

**Core Features**:

- [chat_basics.dart](example/02_core_features/chat_basics.dart), [streaming_chat.dart](example/02_core_features/streaming_chat.dart), [cancellation_demo.dart](example/02_core_features/cancellation_demo.dart)
- [tool_calling.dart](example/02_core_features/tool_calling.dart), [enhanced_tool_calling.dart](example/02_core_features/enhanced_tool_calling.dart)
- [web_search.dart](example/02_core_features/web_search.dart), [embeddings.dart](example/02_core_features/embeddings.dart)
- [content_moderation.dart](example/02_core_features/content_moderation.dart), [audio_processing.dart](example/02_core_features/audio_processing.dart)
- [image_generation.dart](example/02_core_features/image_generation.dart), [file_management.dart](example/02_core_features/file_management.dart)

**Advanced**: [reasoning_models.dart](example/03_advanced_features/reasoning_models.dart), [multi_modal.dart](example/03_advanced_features/multi_modal.dart), [semantic_search.dart](example/03_advanced_features/semantic_search.dart)

**MCP Integration**: [MCP examples](example/06_mcp_integration/) - Model Context Protocol for external tool access

**Use Cases**: [chatbot.dart](example/05_use_cases/chatbot.dart), [cli_tool.dart](example/05_use_cases/cli_tool.dart), [web_service.dart](example/05_use_cases/web_service.dart), [multimodal_app.dart](example/05_use_cases/multimodal_app.dart)

**Production App**: [Yumcha](https://github.com/Latias94/yumcha) - Cross-platform AI chat app built with LLM Dart

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

See [Contributing Guide](.github/CONTRIBUTING.md) for details.

## Thanks

This project exists thanks to all the people who have [contributed](https://github.com/Latias94/llm_dart/blob/main/.github/CONTRIBUTING.md):

<a href="https://github.com/Latias94/llm_dart/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=Latias94/llm_dart" />
</a>

## Acknowledgments

This library is inspired by the Rust [graniet/llm](https://github.com/graniet/llm) library and follows similar patterns adapted for Dart.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
