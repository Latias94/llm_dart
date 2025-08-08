# OpenAI Unique Features

OpenAI-specific capabilities not available in other providers.

## Examples

### [image_generation.dart](image_generation.dart)
DALL-E image generation with advanced configuration options.

### [audio_capabilities.dart](audio_capabilities.dart)
Whisper speech-to-text and TTS voice synthesis.

### [advanced_features.dart](advanced_features.dart)
Assistants API and specialized model features.

### [responses_api.dart](responses_api.dart)
OpenAI's new Responses API with built-in tools like web search, file search, and computer use.

### [build_openai_responses_demo.dart](build_openai_responses_demo.dart)
Type-safe `buildOpenAIResponses()` convenience method for automatic Responses API configuration.

### [gpt5_features.dart](gpt5_features.dart)
GPT-5 specific features including verbosity control, minimal reasoning, and model variants.

## Setup

```bash
export OPENAI_API_KEY="your-openai-api-key"

# Run OpenAI-specific examples
dart run image_generation.dart
dart run audio_capabilities.dart
dart run advanced_features.dart
dart run responses_api.dart
dart run build_openai_responses_demo.dart
dart run gpt5_features.dart
```

## Unique Capabilities

### DALL-E Image Generation
- **DALL-E 3**: High-quality single images with prompt enhancement
- **DALL-E 2**: Multiple variations and image editing
- **Advanced controls**: Style, quality, size options

### Whisper Audio Processing
- **Speech-to-text**: Professional transcription accuracy
- **Audio translation**: Translate speech to English
- **Multiple formats**: Support for various audio formats

### Assistants API

- **Persistent assistants**: Stateful conversations
- **Tool integration**: Code interpreter and file search
- **File management**: Upload and process documents

### Responses API

- **Built-in tools**: Web search, file search, computer use
- **Unified interface**: Combines Chat Completions and Assistants API
- **Multi-turn workflows**: Single API call with multiple tool uses
- **Response chaining**: Link responses for complex workflows

### GPT-5 Features

- **Verbosity Control**: Adjust output detail with `low`, `medium`, `high` settings
- **Minimal Reasoning**: Use `ReasoningEffort.minimal` for faster responses
- **Model Variants**: Support for `gpt-5`, `gpt-5-mini`, `gpt-5-nano`

## Usage Examples

### Image Generation
```dart
final imageProvider = await ai().openai().apiKey('your-key')
    .model('dall-e-3').buildImageGeneration();

final images = await imageProvider.generateImage(
  prompt: 'A futuristic cityscape',
  imageSize: '1024x1024',
);
```

### Audio Processing
```dart
final audioProvider = await ai().openai().apiKey('your-key')
    .buildAudio();

// Speech-to-text
final transcription = await audioProvider.transcribeFile('audio.mp3');

// Text-to-speech
final audioData = await audioProvider.speech('Hello world');
```

### Assistants
```dart
final assistantProvider = await ai().openai().apiKey('your-key')
    .buildAssistant();

final assistant = await assistantProvider.createAssistant(
  CreateAssistantRequest(
    model: 'gpt-4',
    name: 'Code Helper',
    tools: [CodeInterpreterTool()],
  ),
);
```

### GPT-5 Features
```dart
// Verbosity control
final provider = await ai()
    .openai((openai) => openai.verbosity(Verbosity.high))
    .apiKey('your-key')
    .model('gpt-5')
    .build();

// Minimal reasoning for faster responses
final fastProvider = await ai()
    .apiKey('your-key')
    .model('gpt-5')
    .reasoningEffort(ReasoningEffort.minimal)
    .build();
```

### Responses API

The Responses API is OpenAI's new stateful API that combines the simplicity of Chat Completions with advanced capabilities:

#### Basic Usage

```dart
// Traditional approach
final provider = await ai()
    .openai((openai) => openai
        .useResponsesAPI()
        .webSearchTool()
        .fileSearchTool(vectorStoreIds: ['vs_123']))
    .apiKey('your-key')
    .model('gpt-4o')
    .build();

// New convenience method (recommended)
final provider = await ai()
    .openai((openai) => openai
        .webSearchTool()
        .fileSearchTool(vectorStoreIds: ['vs_123']))
    .apiKey('your-key')
    .model('gpt-4o')
    .buildOpenAIResponses(); // Automatically enables Responses API
```

#### Stateful Conversations

```dart
// Using buildOpenAIResponses() - no casting needed!
final provider = await ai().openai().apiKey('your-key')
    .model('gpt-4o').buildOpenAIResponses();

// Direct access to Responses API
final responses = provider.responses!;

// Create initial response
final response1 = await responses.chat([
  ChatMessage.user('My name is Alice. Tell me about AI'),
]);

// Continue conversation with state preservation
final responseId = (response1 as OpenAIResponsesResponse).responseId;
final response2 = await responses.continueConversation(responseId!, [
  ChatMessage.user('Remember my name and explain machine learning'),
]);
```

#### Background Processing

```dart
// Start long-running task in background
final backgroundResponse = await responses.chatWithToolsBackground([
  ChatMessage.user('Write a detailed research report'),
], null);

// Check status later
final responseId = (backgroundResponse as OpenAIResponsesResponse).responseId;
final result = await responses.getResponse(responseId!);
```

#### Response Lifecycle Management

```dart
// Retrieve response by ID
final response = await responses.getResponse('resp_123');

// List input items
final inputItems = await responses.listInputItems('resp_123');

// Delete response
await responses.deleteResponse('resp_123');

// Cancel background response
await responses.cancelResponse('resp_123');

final response = await provider.chat([
  ChatMessage.user('Search for recent AI developments'),
]);
```

## Next Steps

- [Core Features](../../02_core_features/) - Basic chat and streaming
- [Advanced Features](../../03_advanced_features/) - Cross-provider capabilities
