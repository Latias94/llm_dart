# Core Features

Essential functionality for building AI applications with LLM Dart.

## Examples

### [web_search.dart](web_search.dart)
Stable web-search patterns using the shared `generateTextCall(...)` layer plus
provider-owned typed options for OpenAI, Anthropic, xAI, and OpenRouter.

### [capability_detection.dart](capability_detection.dart)
Registry-level capability inspection for provider selection and architecture
planning, with a stable `AI.*(...).chatModel(...)` execution appendix.

### [capability_factory_methods.dart](capability_factory_methods.dart)
Compatibility-oriented specialized `build*()` helpers for capability families
that still live on the older root builder surface.

### [assistants.dart](assistants.dart)
Provider-owned assistant lifecycle management and tool integration.

### [embeddings.dart](embeddings.dart)
Legacy/provider-oriented embeddings example kept during migration.

### [embeddings_stable.dart](embeddings_stable.dart)
Stable shared `embed(...)` and `embedMany(...)` helpers with
`AI.openai(...).embeddingModel(...)`.

### [file_management.dart](file_management.dart)
Provider-owned file upload, download, and management workflows.

### [chat_basics.dart](chat_basics.dart)
Stable foundational chat patterns with prompt messages, conversation history,
and response metadata.

### [streaming_chat.dart](streaming_chat.dart)
Stable streaming chat patterns for responsive UX.

### [cancellation_demo.dart](cancellation_demo.dart)
Stable cancellation for shared text calls, with model listing kept as an
explicit compatibility boundary appendix. Streaming cancellation now surfaces
`AbortEvent` explicitly when available while preserving the older
`transport-cancelled` error path as a fallback boundary.

### [tool_calling.dart](tool_calling.dart)
Stable shared tool-calling flow with `FunctionToolDefinition` and
tool-call replay parts.

### [enhanced_tool_calling.dart](enhanced_tool_calling.dart)
Advanced tool calling with validation, error handling, and richer schemas.

### [structured_output.dart](structured_output.dart)
Shared `OutputSpec` examples for object, array, choice, and text result flows.

### [audio_processing.dart](audio_processing.dart)
Speech capability examples for text-to-speech and speech-to-text workflows.

### [image_generation.dart](image_generation.dart)
AI-powered image creation and editing workflows.

### [error_handling.dart](error_handling.dart)
Production-ready error management patterns.

## Setup

```bash
# Set up environment variables
export OPENAI_API_KEY="your-openai-key"
export ANTHROPIC_API_KEY="your-anthropic-key"
export GOOGLE_API_KEY="your-google-key"

# Run core feature examples
dart run web_search.dart
dart run capability_detection.dart
dart run capability_factory_methods.dart
dart run assistants.dart
dart run embeddings.dart
dart run embeddings_stable.dart
dart run file_management.dart
dart run chat_basics.dart
dart run streaming_chat.dart
dart run tool_calling.dart
dart run enhanced_tool_calling.dart
```

## Key Concepts

This directory intentionally mixes:

- stable shared-model examples centered on `AI.*(...).chatModel(...)`,
  `embeddingModel(...)`, `imageModel(...)`, `speechModel(...)`, and
  `transcriptionModel(...)`
- compatibility/provider examples for capability families that still depend on
  builder-owned or provider-owned APIs during migration

When starting new application code, prefer the stable facade and shared
helpers:

- `generateTextCall(...)`
- `streamTextCall(...)`
- `embed(...)`
- `embedMany(...)`
- `generateImage(...)`
- `generateSpeech(...)`
- `transcribe(...)`

### Capability Metadata vs Stable App Code

- **Stable app path**: Create models through `AI.*(...)` and keep application
  code on the shared call layer.
- **Capability metadata**: Use `LLMProviderRegistry` and `ProviderInfo` to
  shortlist providers and document boundaries before you bind models.
- **Boundary APIs**: Some families, such as assistants, raw response
  lifecycle APIs, and certain file-management workflows, still remain
  provider-owned.

### Core Capability Areas

- **Chat**: Messages, context, response generation, and streaming
- **Tools**: Function calling and tool-result replay
- **Structured Output**: Shared `OutputSpec`-driven result shaping
- **Embeddings**: Vector representations for semantic search and retrieval
- **Audio**: Text-to-speech and speech-to-text workflows
- **Images**: Prompt-based generation and editing
- **Assistants / Files**: Provider-specific lifecycle and storage surfaces
- **Error Handling**: Production-ready failure patterns and fallbacks

## Usage Examples

The snippets below are ordered intentionally:

- stable shared-model flows first
- compatibility/provider-owned boundaries second

### Stable Basic Chat

```dart
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/core.dart' as core;

final model = llm.AI.openai(apiKey: 'your-key').chatModel('gpt-4.1-mini');

final result = await core.generateTextCall(
  model: model,
  prompt: [
    core.UserPromptMessage.text('Hello, how are you?'),
  ],
);

print(result.text);
```

### Stable Embeddings for Search

```dart
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/core.dart' as core;

final model = llm.AI.openai(
  apiKey: 'your-key',
).embeddingModel('text-embedding-3-small');

final batch = await core.embedMany(
  model: model,
  values: const [
    'Machine learning fundamentals',
    'Deep learning neural networks',
    'Natural language processing',
  ],
);

print(batch.embeddings.length);
```

### Compatibility Boundary: Assistants

Assistant lifecycle APIs are still provider-owned and are not yet part of the
stable shared model facade.

```dart
final assistant = await provider.createAssistant(CreateAssistantRequest(
  model: 'gpt-4',
  name: 'Code Helper',
  instructions: 'You are a helpful coding assistant.',
  tools: [CodeInterpreterTool(), FileSearchTool()],
));
```

### Compatibility Boundary: File Management

File upload and file lifecycle APIs also remain provider-owned.

```dart
final fileBytes = await File('document.pdf').readAsBytes();
final fileObject = await provider.uploadFile(FileUploadRequest(
  file: Uint8List.fromList(fileBytes),
  purpose: FilePurpose.assistants,
  filename: 'document.pdf',
));
```

### Provider-Specific Boundary: Anthropic Prompt Caching

Anthropic prompt caching is provider-specific. See the Anthropic provider
examples and README for the current typed guidance and migration notes:

- [Anthropic Provider README](../04_providers/anthropic/README.md)

## Best Practices

- Start new app-facing code from stable model constructors and shared helpers.
- Use capability metadata for provider selection and documentation, not as a
  strict runtime guarantee.
- Treat provider-specific lifecycle surfaces as boundaries until a stable
  shared contract exists.
- Validate critical model behavior with real calls and graceful error handling.
- Dispose streams, controllers, and file handles correctly.
- Use streaming for long responses and apply caching only where the provider
  and model explicitly support it.

## Next Steps

- [Advanced Features](../03_advanced_features/) - Batch processing, real-time
  audio, semantic search
- [Provider Examples](../04_providers/) - Provider-specific features and
  optimizations
- [Use Cases](../05_use_cases/) - Complete applications and Flutter
  integration
- [Getting Started](../01_getting_started/) - Environment setup and
  configuration
