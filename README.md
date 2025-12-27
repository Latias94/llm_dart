# LLM Dart Library

[![pub package](https://img.shields.io/pub/v/llm_dart.svg)](https://pub.dev/packages/llm_dart)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Dart](https://img.shields.io/badge/Dart-3.5.0+-blue.svg)](https://dart.dev)
[![likes](https://img.shields.io/pub/likes/llm_dart?logo=dart)](https://pub.dev/packages/llm_dart/score)
[![CI](https://github.com/Latias94/llm_dart/actions/workflows/ci.yml/badge.svg)](https://github.com/Latias94/llm_dart/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/Latias94/llm_dart/branch/main/graph/badge.svg)](https://codecov.io/gh/Latias94/llm_dart)

A modular Dart library for AI provider interactions.

Recommended mental model (Vercel AI SDK style):

- Use `llm_dart_ai` task APIs as the stable, provider-agnostic surface.
- Use `providerOptions` / `providerTools` / `providerMetadata` as escape hatches.
- Keep provider-specific innovation out of the “standard” surface.

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
| **Configure HTTP/proxy** | [HTTP configuration](example/03_advanced_features/http_configuration.dart) |
| **See production app** | [Yumcha](https://github.com/Latias94/yumcha) |

## Features

- **Multi-provider support**: OpenAI, Anthropic, Google, DeepSeek, Groq, Ollama, xAI, ElevenLabs
- **OpenAI Responses API (OpenAI-only)**: Stateful conversations with built-in tools (web search, file search, computer use)
- **Thinking process access**: Model reasoning for Claude, DeepSeek, Gemini, Ollama
- **Unified tasks (recommended)**: `generateText`, `streamText`, `streamChatParts`, `generateObject`, `embed`, `generateImage`, `generateSpeech`, `transcribe`, tool loops
- **Request cancellation**: Cancel in-flight requests for chat, streaming, and API operations
- **MCP integration**: Model Context Protocol for external tool access
- **Content moderation**: Built-in safety and content filtering
- **Type-safe building**: Compile-time capability validation
- **Builder pattern**: Fluent configuration API
- **Production ready**: Error handling, retry logic, monitoring

## Supported Providers

This repository ships as a monorepo split into multiple packages. You can use
the umbrella `llm_dart` package (all-in-one) or pick subpackages.

Built-in packages (high-level):

- Standard providers (Vercel-style): `llm_dart_openai`, `llm_dart_anthropic`, `llm_dart_google`
- Protocol reuse layers: `llm_dart_openai_compatible`, `llm_dart_anthropic_compatible`
- Additional providers (built on protocol reuse or provider-specific APIs): `llm_dart_deepseek`, `llm_dart_groq`, `llm_dart_xai`, `llm_dart_minimax`, `llm_dart_ollama`, `llm_dart_elevenlabs`

Notes:

- Feature availability varies by provider/model and can change over time.
- `llm_dart` does not try to maintain a complete “unsupported matrix”.
- Prefer `providerOptions` / `providerTools` / `providerMetadata` for
  provider-only features.

## Installation

### Recommended (Vercel-style split): `llm_dart_ai` + provider package(s)

Pick the provider packages you need and keep the dependency footprint small:

```yaml
dependencies:
  llm_dart_ai: ^0.10.5
  llm_dart_builder: ^0.10.5
  llm_dart_anthropic: ^0.10.5
```

Then run:

```bash
dart pub get
```

Or install directly using:

```bash
dart pub add llm_dart_ai llm_dart_builder llm_dart_anthropic
```

### All-in-one umbrella (optional)

If you prefer a single dependency that re-exports everything:

```bash
dart pub add llm_dart
```

## Quick Start

### Basic Usage (recommended: task APIs)

```dart
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';

void main() async {
  registerAnthropic(); // required when using subpackages

  final model = await LLMBuilder()
      .provider(anthropicProviderId)
      .apiKey('your-api-key')
      .model('claude-sonnet-4-20250514')
      .build();

  final prompt = Prompt(messages: [
    PromptMessage.user('Hello, world!'),
  ]);

  final result = await generateText(model: model, promptIr: prompt);

  print(result.text);
  print(result.providerMetadata); // optional provider-specific metadata
}
```

### Umbrella convenience (optional)

If you depend on `llm_dart`, it auto-registers built-in providers via `ai()`:

```dart
import 'package:llm_dart/llm_dart.dart';

void main() async {
  final model = await ai()
      .provider('anthropic')
      .apiKey('your-api-key')
      .model('claude-sonnet-4-20250514')
      .build();

  final result = await generateText(
    model: model,
    promptIr: Prompt(messages: [PromptMessage.user('Hello!')]),
  );

  print(result.text);
}
```

### Pick subpackages (example: MiniMax)

For a minimal dependency footprint, depend on only the packages you need:

```bash
dart pub add llm_dart_minimax llm_dart_builder llm_dart_ai
```

```dart
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_minimax/llm_dart_minimax.dart';

Future<void> main() async {
  registerMinimax(); // required for subpackage users

  final model = await LLMBuilder()
      .provider(minimaxProviderId)
      .apiKey('MINIMAX_API_KEY')
      .baseUrl(minimaxAnthropicV1BaseUrl)
      .model(minimaxDefaultModel)
      .build();

  final prompt = Prompt(messages: [
    PromptMessage.user('Hello from MiniMax!'),
  ]);

  final result = await generateText(model: model, promptIr: prompt);

  print(result.text);
}
```

MiniMax guide: [docs/providers/minimax.md](docs/providers/minimax.md)

### Streaming with DeepSeek Reasoning

```dart
import 'dart:io';
import 'package:llm_dart/llm_dart.dart';

// Create DeepSeek provider for streaming with thinking.
final provider = await ai()
    .provider('deepseek')
    .apiKey('your-deepseek-key')
    .model('deepseek-reasoner')
    .temperature(0.7)
    .build();

final prompt = Prompt(messages: [
  PromptMessage.user('What is 15 + 27? Show your work.'),
]);

// Recommended: stream via llm_dart_ai task APIs (provider-agnostic).
await for (final part in streamText(model: provider, promptIr: prompt)) {
  switch (part) {
    case ThinkingDeltaPart(delta: final delta):
      stdout.write('\x1B[90m$delta\x1B[0m');
    case TextDeltaPart(delta: final delta):
      stdout.write(delta);
    case ToolCallDeltaPart(toolCall: final toolCall):
      stdout.writeln('\n[tool] ${toolCall.function.name}');
    case FinishPart(result: final result):
      stdout.writeln('\n✅ Completed');
      if (result.usage != null) {
        stdout.writeln('Tokens: ${result.usage!.totalTokens}');
      }
    case ErrorPart(error: final error):
      stdout.writeln('Error: $error');
  }
}
```

## Migration notes (monorepo split refactors)

The monorepo is being refactored to better match a Vercel AI SDK-style split.
Key changes are recorded in `CHANGELOG.md` and architecture docs:

- `docs/refactor_vision.md`
- `docs/llm_dart_architecture.md`
- `docs/standard_surface.md`
- `docs/migrations/0.11.0-alpha.1.md`

Recent highlights:

- **Cancellation**: use `CancelToken` from `llm_dart` / `llm_dart_core` (no Dio type leaks).
- **HTTP config**: prefer `LLMConfig.transportOptions` (and `LLMBuilder.http((h) => ...)`).
- **Advanced Dio utilities**: import from `llm_dart_provider_utils` (not from `llm_dart`).

### 🧠 Thinking Process Access

Access the model's internal reasoning and thought processes:

```dart
// Claude with thinking
final claudeProvider = await ai()
    .provider('anthropic')
    .apiKey('your-anthropic-key')
    .model('claude-sonnet-4-20250514')
    .build();

final prompt = Prompt(messages: [
  PromptMessage.user('Solve this step by step: What is 15% of 240?'),
]);

final result =
    await generateText(model: claudeProvider, promptIr: prompt);

// Access the final answer
print('Answer: ${result.text}');

// Access the thinking process
if (result.thinking != null) {
  print('Claude\'s thinking process:');
  print(result.thinking);
}

// DeepSeek with reasoning
final deepseekProvider = await ai()
    .provider('deepseek')
    .apiKey('your-deepseek-key')
    .model('deepseek-reasoner')
    .temperature(0.7)
    .build();

final reasoningResult =
    await generateText(model: deepseekProvider, promptIr: prompt);
print('DeepSeek reasoning: ${reasoningResult.thinking}');
```

### Web Search

```dart
// Web search is provider-native and varies by provider.
// Prefer provider tools / provider-specific options (Vercel-style).

// OpenAI: Responses API built-in tool (provider-executed)
final openaiProvider = await ai()
    .provider('openai')
    .apiKey('your-openai-key')
    .providerTool(
      OpenAIProviderTools.webSearch(
        contextSize: OpenAIWebSearchContextSize.medium,
      ),
    )
    .build();

final openaiPrompt = Prompt(messages: [
  PromptMessage.user('What are the latest AI developments this week?'),
]);
final openaiResult =
    await generateText(model: openaiProvider, promptIr: openaiPrompt);
print(openaiResult.text);

// Anthropic: server tool (provider-executed)
final anthropicProvider = await ai()
    .provider('anthropic')
    .apiKey('your-anthropic-key')
    .providerTool(
      AnthropicProviderTools.webSearch(
        toolType: 'web_search_20250305',
        options: AnthropicWebSearchToolOptions(
          maxUses: 3,
          allowedDomains: ['wikipedia.org', 'arxiv.org'],
          userLocation: AnthropicUserLocation(
            city: 'San Francisco',
            region: 'California',
            country: 'US',
            timezone: 'America/Los_Angeles',
          ),
        ),
      ),
    )
    .build();

// xAI: parameter-based search (provider-specific)
final xaiProvider = await ai()
    .provider('xai')
    .apiKey('your-xai-key')
    .model('grok-3')
    .providerOptions('xai', {
      'liveSearch': true,
      'searchParameters': SearchParameters.webSearch(maxResults: 5).toJson(),
    })
    .build();

final xaiPrompt = Prompt(messages: [
  PromptMessage.user('What is the current stock price of NVIDIA?'),
]);
final xaiResult =
    await generateText(model: xaiProvider, promptIr: xaiPrompt);
print(xaiResult.text);
```

Notes:

- Web search is intentionally treated as a provider-native tool where supported.
- Some providers (e.g. MiniMax Anthropic-compatible) do not support provider-native web search yet; implement a local `FunctionTool` in your app or see `example/04_providers/minimax/local_web_search_tool_loop.dart`.
- `LLMBuilder.enableWebSearch()` / `LLMBuilder.webSearch(...)` have been removed; use `providerTools` / provider-specific `providerOptions` instead.

### Embeddings

```dart
// Generate embeddings for semantic search
final provider = await ai()
    .provider('openai')
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
    .provider('openai')
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

## Provider Examples

### OpenAI

```dart
final provider = await createProvider(
  providerId: 'openai',
  apiKey: 'sk-...',
  model: 'gpt-4',
  temperature: 0.7,
  providerOptions: {'reasoningEffort': 'medium'}, // For reasoning models
);
```

#### Responses API (Stateful Conversations)

OpenAI's new Responses API provides stateful conversation management with built-in tools.
This is **OpenAI-only** (implemented in `llm_dart_openai`), and is intentionally
not part of the `llm_dart_openai_compatible` baseline.

```dart
final provider = await OpenAIBuilder(
  ai().provider('openai').apiKey('your-key').model('gpt-4o'),
)
    .useResponsesAPI()
    .webSearchTool()
    .fileSearchTool(vectorStoreIds: ['vs_123'])
    .build();

// Cast to access stateful features
final responsesProvider = provider as OpenAIProvider;
final responses = responsesProvider.responses!;

// Stateful conversation with automatic context preservation
final response1 = await responses.chat(
  Prompt(messages: [
    PromptMessage.user('My name is Alice. Tell me about quantum computing'),
  ]).toChatMessages(),
);

final responseId = (response1 as OpenAIResponsesResponse).responseId;
final response2 = await responses.continueConversation(
  responseId!,
  Prompt(messages: [
    PromptMessage.user('Remember my name and explain it simply'),
  ]).toChatMessages(),
);

// Background processing for long tasks
final backgroundTask = await responses.chatWithToolsBackground(
  Prompt(messages: [
    PromptMessage.user('Write a detailed research report'),
  ]).toChatMessages(),
  null,
);

// Response lifecycle management
await responses.getResponse('resp_123');
await responses.deleteResponse('resp_123');
await responses.cancelResponse('resp_123');
```

### Anthropic (with Thinking Process)

```dart
final provider = await ai()
    .provider('anthropic')
    .apiKey('sk-ant-...')
    .model('claude-sonnet-4-20250514')
    .build();

final prompt = Prompt(messages: [
  PromptMessage.user('Explain quantum computing step by step'),
]);
final result = await generateText(model: provider, promptIr: prompt);

// Access Claude's thinking process
print('Final answer: ${result.text}');
if (result.thinking != null) {
  print('Claude\'s reasoning: ${result.thinking}');
}
```

### DeepSeek (with Reasoning)

```dart
final provider = await ai()
    .provider('deepseek')
    .apiKey('your-deepseek-key')
    .model('deepseek-reasoner')
    .build();

final prompt = Prompt(messages: [
  PromptMessage.user('Solve this logic puzzle step by step'),
]);
final result = await generateText(model: provider, promptIr: prompt);

// Access DeepSeek's reasoning process
print('Solution: ${result.text}');
if (result.thinking != null) {
  print('DeepSeek\'s reasoning: ${result.thinking}');
}
```

### Ollama (with Thinking Process)

```dart
// Ollama with thinking enabled
final provider = await ai()
    .provider('ollama')
    .baseUrl('http://localhost:11434')
    .model('gpt-oss:latest') // Reasoning model
    .reasoning(true)         // Enable reasoning process
    .build();

final prompt = Prompt(messages: [
  PromptMessage.user('Solve this math problem step by step: 15 * 23 + 7'),
]);
final result = await generateText(model: provider, promptIr: prompt);

// Access Ollama's thinking process
if (result.thinking != null) {
  print('Ollama\'s reasoning: ${result.thinking}');
}
```

### xAI (with Web Search)

```dart
final provider = await ai()
    .provider('xai')
    .apiKey('your-xai-key')
    .model('grok-3')
    .providerOptions('xai', {
      'liveSearch': true,
      'searchParameters': SearchParameters.webSearch(maxResults: 5).toJson(),
    })
    .build();

// Real-time web search
final prompt = Prompt(messages: [
  PromptMessage.user('What is the current stock price of NVIDIA?'),
]);
final result = await generateText(model: provider, promptIr: prompt);
print(result.text);

// News search with date filtering
final newsProvider = await ai()
    .provider('xai')
    .apiKey('your-xai-key')
    .providerOptions('xai', {
      'liveSearch': true,
      'searchParameters': SearchParameters.news(
        maxResults: 5,
        fromDate: '2024-12-01',
      ).toJson(),
    })
    .build();
```

### Google (with Embeddings)

```dart
final provider = await ai()
    .provider('google')
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
final audioProvider = await ElevenLabsBuilder(
  ai().provider('elevenlabs').apiKey('your-elevenlabs-key'),
)
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

// Create a cancel token
final cancelToken = CancelToken();

final prompt = Prompt(messages: [
  PromptMessage.user('Write a very long essay...'),
]);

// Start a long-running request
final responseFuture =
    generateText(model: provider, promptIr: prompt, cancelToken: cancelToken);

// Cancel it later (e.g., user navigates away)
cancelToken.cancel('User cancelled');

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
await for (final part in streamText(
  model: provider,
  promptIr: prompt,
  cancelToken: cancelToken,
)) {
  switch (part) {
    case TextDeltaPart(delta: final delta):
      print(delta);
      // Cancel after first token
      cancelToken.cancel('Got enough data');
      break;
    case ErrorPart(error: final error):
      if (CancellationHelper.isCancelled(error)) {
        print('Stream cancelled');
      }
      break;
    case FinishPart():
    case ThinkingDeltaPart():
    case ToolCallDeltaPart():
      break;
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

abstract class ModerationCapability {
  Future<ModerationResponse> moderate(ModerationRequest request);
}

// Providers implement only the capabilities they support
class OpenAIProvider implements
    ChatCapability,
    EmbeddingCapability,
    ModerationCapability {
  // Implementation
}
```

### Type-Safe Capability Building

The library provides capability factory methods for compile-time type safety:

```dart
// Old approach - runtime type casting
final provider = await ai().provider('openai').apiKey(apiKey).build();
if (provider is! AudioCapability) {
  throw Exception('Audio not supported');
}
final audioProvider = provider as AudioCapability; // Runtime cast!

// New approach - compile-time type safety
final audioProvider = await ai().provider('openai').apiKey(apiKey).buildAudio();
// Direct usage without type casting - guaranteed AudioCapability!

// Available factory methods:
final chatProvider = await ai().provider('openai').build(); // Returns ChatCapability
final audioProvider = await ai().provider('openai').buildAudio();
final imageProvider = await ai().provider('openai').buildImageGeneration();
final embeddingProvider = await ai().provider('openai').buildEmbedding();
final fileProvider = await ai().provider('openai').buildFileManagement();
final moderationProvider = await ai().provider('openai').buildModeration();
final assistantProvider = await ai().provider('openai').buildAssistant();
final modelProvider = await ai().provider('openai').buildModelListing();

// Web search is enabled through configuration, not a separate capability
// Example (OpenAI provider-native web search):
final webSearchProvider = await ai()
    .provider('openai')
    .providerTool(OpenAIProviderTools.webSearch())
    .build();

// Clear error messages for unsupported capabilities
try {
  final audioProvider = await ai().provider('groq').buildAudio(); // Groq doesn't support audio
} catch (e) {
  print(e); // UnsupportedCapabilityError: Provider "groq" does not support audio capabilities.
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

### Provider-Specific Options

Provider-specific features are configured via namespaced `providerOptions`
(recommended) or provider-native `providerTools`.

```dart
final provider = await ai()
    .provider('openai')
    .apiKey('your-key')
    .model('gpt-4')
    .reasoningEffort(ReasoningEffort.high)  // OpenAI-specific
    .voice('alloy')                        // OpenAI TTS voice
    .build();
```

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
