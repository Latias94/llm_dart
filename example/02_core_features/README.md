# Core Features

Essential functionality for building AI applications with LLM Dart.

This directory is intentionally split into:

- stable shared-model examples for new app code
- explicit boundary appendices for provider-owned or older compatibility flows

## Examples

### [web_search.dart](web_search.dart)
Stable web-search patterns using the shared `generateTextCall(...)` layer plus
provider-owned typed options for OpenAI, Anthropic, xAI, and OpenRouter.

### [capability_detection.dart](capability_detection.dart)
Registry-level capability inspection for provider selection and architecture
planning, with a stable `AI.*(...).chatModel(...)` execution appendix.

### [capability_profile_ui_gating.dart](capability_profile_ui_gating.dart)
Modern model-centric capability profile inspection for shared UI affordances,
provider-native panels, and graceful fallback suggestions.
The example now also includes a community-provider Ollama preset and shows why
Ollama image-input or reasoning affordances should be treated as inferred
family hints rather than hard runtime guarantees.

### [capability_factory_methods.dart](capability_factory_methods.dart)
Compatibility-oriented specialized `build*()` helpers for capability families
that still live on the older root builder surface.

### [provider_specific_builders.dart](provider_specific_builders.dart)
Compatibility-oriented provider callback builders that still demonstrate the
older root builder shell for provider-specific tuning.

### [assistants.dart](assistants.dart)
Stable assistant-like chat guidance first, followed by the explicit OpenAI
boundary for persisted assistant lifecycle APIs.

### [embeddings.dart](embeddings.dart)
Stable multi-provider embeddings example using shared `embed(...)` and
`embedMany(...)` helpers across OpenAI, Google, and Ollama models.

### [embeddings_stable.dart](embeddings_stable.dart)
Stable shared `embed(...)` and `embedMany(...)` helpers with
`AI.openai(...).embeddingModel(...)`.

### [file_management.dart](file_management.dart)
Stable local `FilePromptPart` usage first, followed by explicit provider-owned
remote file lifecycle examples for OpenAI and Anthropic.

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
Stable advanced tool calling with local validation, nested schemas, tool-call
replay, structured final answers, and provider-owned OpenAI tool controls.

### [structured_output.dart](structured_output.dart)
Shared `OutputSpec` examples for object, array, choice, and text result flows.

### [audio_processing.dart](audio_processing.dart)
Stable speech and transcription example using shared `generateSpeech(...)` and
`transcribe(...)` helpers across OpenAI and ElevenLabs models.

### [image_generation.dart](image_generation.dart)
Stable multi-provider image generation example using shared `generateImage(...)`
plus provider-native image options for OpenAI and Google.

### [content_moderation.dart](content_moderation.dart)
Provider-owned moderation signals translated into app-owned policy decisions
through the focused OpenAI moderation client instead of pretending a shared
moderation contract exists.

### [model_listing.dart](model_listing.dart)
Stable concrete-model capability inspection first, then provider-owned remote
catalog listing for admin, diagnostics, or model-browser workflows.

### [message_builder_cache.dart](message_builder_cache.dart)
Anthropic-specific prompt-caching appendix using `MessageBuilder` with narrow
typed imports instead of the broad compatibility barrel.

### [error_handling.dart](error_handling.dart)
Stable `ModelError` normalization plus retry, fallback, and circuit-breaker
patterns around shared text-call closures.

## Setup

```bash
# Set up environment variables
export OPENAI_API_KEY="your-openai-key"
export ANTHROPIC_API_KEY="your-anthropic-key"
export GOOGLE_API_KEY="your-google-key"

# Run core feature examples
dart run web_search.dart
dart run capability_detection.dart
dart run capability_profile_ui_gating.dart
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

## Suggested Reading Order

- Start with [chat_basics.dart](chat_basics.dart),
  [streaming_chat.dart](streaming_chat.dart),
  [tool_calling.dart](tool_calling.dart),
  [structured_output.dart](structured_output.dart), and
  [error_handling.dart](error_handling.dart) for the stable app path.
- Add [capability_profile_ui_gating.dart](capability_profile_ui_gating.dart),
  [embeddings.dart](embeddings.dart),
  [audio_processing.dart](audio_processing.dart), and
  [image_generation.dart](image_generation.dart) when product requirements need
  model-aware UI or multimodal support.
- Treat [assistants.dart](assistants.dart),
  [file_management.dart](file_management.dart),
  [content_moderation.dart](content_moderation.dart),
  [model_listing.dart](model_listing.dart),
  [message_builder_cache.dart](message_builder_cache.dart), and the older
  builder demos as explicit boundary appendices rather than the default entry
  path for new application code.

## Key Concepts

This directory intentionally mixes:

- stable shared-model examples centered on `AI.*(...).chatModel(...)`,
  `embeddingModel(...)`, `imageModel(...)`, `speechModel(...)`, and
  `transcriptionModel(...)`
- explicit boundary appendices for capability families that still depend on
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

### UI Projection Boundary

- Keep `ChatMessageMapper` in the shared `package:llm_dart/core.dart` layer for
  stable cross-provider summaries.
- Keep provider-owned metadata inspection in provider packages.
- When the UI needs both layers together, prefer provider-owned composed
  helpers such as `OpenAIMessageMapper().mapComposed(...)` and
  `GoogleMessageMapper().mapComposed(...)`.

```dart
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/openai.dart' as openai;

void inspectMessage(core.ChatUiMessage message) {
  final mapped = const openai.OpenAIMessageMapper().mapComposed(message);

  print(mapped.shared.text);
  print(mapped.provider.partDetails.length);
  print(mapped.provider.hasOpenAIMetadata);
}
```

### Capability Metadata vs Stable App Code

- **Stable app path**: Create models through `AI.*(...)` and keep application
  code on the shared call layer.
- **Modern model-centric discovery**: Use `CapabilityDescribedModel` and
  `ModelCapabilityProfile` when a concrete model should gate app or Flutter UI
  affordances.
- **Community confidence rule**: For `llm_dart_community`, use
  `CapabilityDescriptor.confidence` when the UI should distinguish strong
  hosted-API descriptors from model-family inference, especially for Ollama.
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

- [Message Builder Cache Appendix](message_builder_cache.dart)
- [Anthropic Provider README](../04_providers/anthropic/README.md)

## Best Practices

- Start new app-facing code from stable model constructors and shared helpers.
- For Flutter chat apps, keep conversation history, attachments, retries, and
  UI state app-owned before introducing provider-managed persistence.
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
