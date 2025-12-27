# Core Features

Essential functionality for building AI applications with LLM Dart.

## Examples

### [capability_factory_methods.dart](capability_factory_methods.dart)
Type-safe provider initialization using specialized build methods.

### [assistants.dart](assistants.dart)
AI assistants creation, management, and tool integration.

### [embeddings.dart](embeddings.dart)
Text embeddings for semantic search and similarity analysis.

### [file_management.dart](file_management.dart)
File upload, download, and management for AI workflows.

### [chat_basics.dart](chat_basics.dart)
Foundation of AI interactions - messages, context, and responses.

### [streaming_chat.dart](streaming_chat.dart)
Real-time response streaming for better user experience.

### [stream_parts.dart](stream_parts.dart)
Vercel-style stream parts (`streamChatParts`) and metadata boundaries.

### [cancellation_demo.dart](cancellation_demo.dart)
Request cancellation support for chat, streaming, and API operations.

### [tool_calling.dart](tool_calling.dart)
Function calling - let AI execute custom functions.

### [enhanced_tool_calling.dart](enhanced_tool_calling.dart)
Advanced tool calling with validation, error handling, and complex nested object structures.

### [structured_output.dart](structured_output.dart)
JSON schema output with validation.

### [audio_processing.dart](audio_processing.dart)
Text-to-speech and speech-to-text capabilities.

### [image_generation.dart](image_generation.dart)
AI-powered image creation and editing.

### [error_handling.dart](error_handling.dart)
Production-ready error management patterns.

## Setup

```bash
# Set up environment variables
export OPENAI_API_KEY="your-openai-key"
export ANTHROPIC_API_KEY="your-anthropic-key"
export GOOGLE_API_KEY="your-google-key"

# Run core feature examples
dart run capability_factory_methods.dart
dart run assistants.dart
dart run embeddings.dart
dart run file_management.dart
dart run chat_basics.dart
dart run streaming_chat.dart
dart run tool_calling.dart
dart run enhanced_tool_calling.dart
```

## Key Concepts

### Capability-Based Architecture
- **Type Safety**: Use `build()` for chat, and specialized build methods (`buildAssistant()`, `buildEmbedding()`, etc.)
- **Provider Abstraction**: Unified interface across different AI providers
- **Capability Detection**: Automatic feature detection and validation

### Core Capabilities
- **Chat**: Messages, context, and response handling
- **Assistants**: Persistent AI assistants with tools and memory
- **Embeddings**: Vector representations for semantic search
- **File Management**: Upload, download, and organize files for AI workflows
- **Streaming**: Real-time response delivery
- **Tools**: Function calling and execution
- **Structured Output**: JSON schema validation
- **Error Handling**: Production-ready error management

## Usage Examples

### Basic Chat
```dart
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';

registerOpenAI();

final provider = await LLMBuilder()
    .provider(openaiProviderId)
    .apiKey('your-key')
    .build();

final result = await generateText(
  model: provider,
  promptIr: Prompt(
    messages: [
      PromptMessage.user('Hello, how are you?'),
    ],
  ),
);

print(result.text);
```

### Assistant with Tools
```dart
// Create assistant with tools
final assistant = await provider.createAssistant(CreateAssistantRequest(
  model: 'gpt-4',
  name: 'Code Helper',
  instructions: 'You are a helpful coding assistant.',
  tools: [CodeInterpreterTool(), FileSearchTool()],
));
```

### File Management
```dart
// Upload file for AI processing
final fileBytes = await File('document.pdf').readAsBytes();
final fileObject = await provider.uploadFile(FileUploadRequest(
  file: Uint8List.fromList(fileBytes),
  purpose: FilePurpose.assistants,
  filename: 'document.pdf',
));
```

### Embeddings for Search
```dart
// Generate embeddings for semantic search
final embeddings = await provider.embed([
  'Machine learning fundamentals',
  'Deep learning neural networks',
  'Natural language processing',
]);
```

### Anthropic Prompt Caching
**⚠️ ANTHROPIC ONLY**: Caching features are currently only supported by Anthropic providers.

```dart
final cacheControl = {
  'type': 'ephemeral',
  'ttl': '1h',
};

// Message-level caching (provider escape hatch)
final prompt = Prompt(
  messages: [
    PromptMessage.system(
      'You are a helpful AI assistant.',
      providerOptions: {
        'anthropic': {'cacheControl': cacheControl},
      },
    ),
    PromptMessage.system(
      'Here is a large document that will be cached...',
      providerOptions: {
        'anthropic': {'cacheControl': cacheControl},
      },
    ),
    PromptMessage.user('Summarize the document.'),
  ],
);

// Tool-level caching: set cacheControl on any message, and pass `tools`
final result = await generateText(
  model: anthropicProvider,
  promptIr: Prompt(
    messages: [
      PromptMessage.system(
        'Use the provided tools to help the user.',
        providerOptions: {
          'anthropic': {'cacheControl': cacheControl},
        },
      ),
      PromptMessage.user('Find the best approach and explain it.'),
    ],
  ),
  tools: [tool1, tool2, tool3],
);
```

## Best Practices

### Type Safety
- Use `build()` for chat, and specialized build methods (`buildAssistant()`, etc.)
- Handle null values properly with null-aware operators (`?.`, `!`)
- Use proper error handling with try-catch blocks

### Resource Management
- Dispose of streams and controllers when done
- Close file handles and network connections
- Use proper async/await patterns

### Performance
- Use streaming for long responses
- Implement proper caching for embeddings
- Handle rate limits gracefully

## Next Steps

- [Advanced Features](../03_advanced_features/) - Batch processing, real-time audio, semantic search
- [Provider Examples](../04_providers/) - Provider-specific features and optimizations
- [Use Cases](../05_use_cases/) - Complete applications and Flutter integration
- [Getting Started](../01_getting_started/) - Environment setup and configuration
