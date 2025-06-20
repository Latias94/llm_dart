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
- **Thinking process access**: Model reasoning for Claude, DeepSeek, Gemini
- **Unified capabilities**: Chat, streaming, tools, audio, images, files, web search, embeddings
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
| Google | ✅ | ✅ | ✅ | 🧠 | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Gemini models with reasoning |
| DeepSeek | ✅ | ✅ | ✅ | 🧠 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | DeepSeek reasoning models |
| Groq | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Ultra-fast inference |
| Ollama | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | Local models, privacy-focused |
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
  llm_dart: ^0.8.0
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

### Basic Usage

```dart
import 'package:llm_dart/llm_dart.dart';

void main() async {
  // Method 1: Using the new ai() builder with provider methods
  final provider = await ai()
      .openai()
      .apiKey('your-api-key')
      .model('gpt-4')
      .temperature(0.7)
      .build();

  // Method 2: Using provider() with string ID (extensible)
  final provider2 = await ai()
      .provider('openai')
      .apiKey('your-api-key')
      .model('gpt-4')
      .temperature(0.7)
      .build();

  // Method 3: Using convenience function
  final directProvider = await createProvider(
    providerId: 'openai',
    apiKey: 'your-api-key',
    model: 'gpt-4',
    temperature: 0.7,
  );

  // Simple chat
  final messages = [ChatMessage.user('Hello, world!')];
  final response = await provider.chat(messages);
  print(response.text);

  // Access thinking process (for supported models)
  if (response.thinking != null) {
    print('Model thinking: ${response.thinking}');
  }
}
```

### Streaming with DeepSeek Reasoning

```dart
import 'dart:io';
import 'package:llm_dart/llm_dart.dart';

// Create DeepSeek provider for streaming with thinking
final provider = await ai()
    .deepseek()
    .apiKey('your-deepseek-key')
    .model('deepseek-reasoner')
    .temperature(0.7)
    .build();

final messages = [ChatMessage.user('What is 15 + 27? Show your work.')];

// Stream with real-time thinking process
await for (final event in provider.chatStream(messages)) {
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

## Provider Examples

### OpenAI

```dart
final provider = await createProvider(
  providerId: 'openai',
  apiKey: 'sk-...',
  model: 'gpt-4',
  temperature: 0.7,
  extensions: {'reasoningEffort': 'medium'}, // For reasoning models
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

### Ollama

```dart
final provider = ollama(
  baseUrl: 'http://localhost:11434',
  model: 'llama3.2',
  // No API key needed for local Ollama
);
```

### xAI (with Web Search)

```dart
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

## Error Handling

```dart
try {
  final response = await provider.chatWithTools(messages, null);
  print(response.text);
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
final provider = await ai()
    .openai()
    .apiKey('your-key')
    .model('gpt-4')
    .reasoningEffort(ReasoningEffort.high)  // OpenAI-specific
    .extension('voice', 'alloy')           // OpenAI TTS voice
    .build();
```

## Examples

See the [example directory](example) for comprehensive examples:

**Getting Started**: [quick_start.dart](example/01_getting_started/quick_start.dart), [provider_comparison.dart](example/01_getting_started/provider_comparison.dart)

**Core Features**:

- [chat_basics.dart](example/02_core_features/chat_basics.dart), [streaming_chat.dart](example/02_core_features/streaming_chat.dart)
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
