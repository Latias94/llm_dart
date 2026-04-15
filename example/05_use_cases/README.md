# Use Cases

Complete application examples showing real-world usage patterns with LLM Dart.

These end-to-end examples are being migrated incrementally.

For new applications, prefer injecting stable `LanguageModel` instances created
through `AI.*(...).chatModel(...)`, or `ChatSession` abstractions from
`llm_dart_chat`, adding `llm_dart_flutter` only when you need a widget-facing
`ChatController`, instead of centering new code on the legacy root builder.

Keep shared chat UI projection in `package:llm_dart/core.dart`. When a Flutter
screen also needs provider-specific metadata, keep that extra inspection in the
provider package through `mapComposed(...)` rather than widening the shared UI
layer.

## Examples

### [chatbot.dart](chatbot.dart)
Interactive chatbot with personality, context management, and streaming responses.

### [cli_tool.dart](cli_tool.dart)
Command-line AI assistant with multiple provider support and argument parsing.

### [web_service.dart](web_service.dart)
HTTP API service with authentication, rate limiting, and monitoring.

### [packages/llm_dart_chat/example/chat_runtime.dart](../../packages/llm_dart_chat/example/chat_runtime.dart)
Framework-neutral chat session patterns now live with the dedicated `llm_dart_chat` package.

### [packages/llm_dart_chat/example/http_backend_hint_mapping.dart](../../packages/llm_dart_chat/example/http_backend_hint_mapping.dart)
HTTP chat transport pattern for sending app-owned metadata to a backend that
maps those hints into provider-specific invocation options.

### [packages/llm_dart_flutter/example/flutter_integration.dart](../../packages/llm_dart_flutter/example/flutter_integration.dart)
Flutter app integration patterns now live with the dedicated `llm_dart_flutter` package.

### [packages/llm_dart_flutter/example/flutter_http_backend_integration.dart](../../packages/llm_dart_flutter/example/flutter_http_backend_integration.dart)
Flutter `ChatController` example that keeps provider-specific routing and
invocation shaping on the backend while still using `HttpChatTransport`.

### [packages/llm_dart_flutter/example/flutter_material_chat_demo.dart](../../packages/llm_dart_flutter/example/flutter_material_chat_demo.dart)
Minimal `MaterialApp` chat screen that uses `ChatController` plus backend-owned
provider routing so Flutter applications have a widget-level integration
reference.

### [packages/llm_dart_flutter/example/flutter_tool_approval_demo.dart](../../packages/llm_dart_flutter/example/flutter_tool_approval_demo.dart)
Minimal `MaterialApp` chat screen that demonstrates the manual UI flow for
provider approval plus local tool execution using the existing chat session
surface.

### [batch_processor.dart](batch_processor.dart)
Large-scale data processing with concurrent workers, rate limiting, and progress tracking.

### [multimodal_app.dart](multimodal_app.dart)
Comprehensive multimodal AI application combining text, image, and audio processing.

## Setup

```bash
# Set up environment variables
export OPENAI_API_KEY="your-openai-key"
export ANTHROPIC_API_KEY="your-anthropic-key"
export GROQ_API_KEY="your-groq-key"

# Run use case examples
dart run chatbot.dart
dart run cli_tool.dart --help
dart run web_service.dart
dart run ../../packages/llm_dart_chat/example/chat_runtime.dart
dart run ../../packages/llm_dart_chat/example/http_backend_hint_mapping.dart
dart run ../../packages/llm_dart_flutter/example/flutter_integration.dart
flutter run ../../packages/llm_dart_flutter/example/flutter_material_chat_demo.dart
dart run batch_processor.dart --help
dart run multimodal_app.dart --demo
```

## Key Concepts

### Application Architecture
- **Separation of Concerns**: Clean architecture with distinct layers
- **Configuration Management**: Environment-based settings
- **Error Handling**: Graceful degradation and user feedback
- **State Management**: Proper handling of async operations

### User Experience
- **Progressive Enhancement**: Incremental feature loading
- **Real-time Feedback**: Streaming responses and progress indicators
- **Responsive Design**: Adaptive UI for different screen sizes
- **Accessibility**: Screen reader support and keyboard navigation

### Production Readiness
- **Monitoring**: Logging, metrics, and health checks
- **Security**: Authentication, authorization, and input validation
- **Scalability**: Load balancing and resource optimization
- **Reliability**: Retry logic, circuit breakers, and fallbacks

## Usage Examples

### Interactive Chatbot
```dart
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/core.dart' as core;

final model = llm.AI.openai(apiKey: 'your-key').chatModel('gpt-4.1-mini');

final result = await core.generateTextCall(
  model: model,
  prompt: [
    core.UserPromptMessage.text('Introduce yourself like a helpful chatbot.'),
  ],
);

print(result.text);
```

### CLI Tool
```dart
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/core.dart' as core;

final models = <String, core.LanguageModel>{
  'openai': llm.AI.openai(apiKey: 'key').chatModel('gpt-4.1-mini'),
  'anthropic': llm.AI.anthropic(apiKey: 'key').chatModel('claude-sonnet-4-5'),
};

final result = await core.generateTextCall(
  model: models['openai']!,
  prompt: [
    core.UserPromptMessage.text('Explain what this CLI command should do.'),
  ],
);

print(result.text);
```

### Web Service
```dart
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/core.dart' as core;

final model =
    llm.AI.groq(apiKey: 'your-key').chatModel('llama-3.3-70b-versatile');

Future<Map<String, Object?>> handleChat(String message) async {
  final result = await core.generateTextCall(
    model: model,
    prompt: [
      core.UserPromptMessage.text(message),
    ],
  );

  return {'text': result.text};
}
```

### Flutter Integration
```dart
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/openai.dart' as openai;
import 'package:llm_dart_flutter/llm_dart_flutter.dart';

final controller = ChatController(
  session: DefaultChatSession(
    transport: DirectChatTransport(
      model: llm.AI.openai(
        apiKey: 'your-key',
      ).chatModel('gpt-4.1-mini'),
    ),
  ),
);

controller.addListener(() {
  final state = controller.state;
  if (state.messages.isEmpty) {
    return;
  }

  final mapped =
      const openai.OpenAIMessageMapper().mapComposed(state.messages.last);
  print(mapped.shared.text);
  print(mapped.provider.hasOpenAIMetadata);
});
```

### Batch Processing
```dart
final processor = BatchProcessor();
await processor.processFile(
  inputFile: 'data.jsonl',
  outputFile: 'results.jsonl',
  operation: 'analyze',
  concurrency: 5,
);
// Process thousands of items with rate limiting
```

### Multimodal Application
```dart
final app = MultimodalApp();
await app.initializeProviders();

// Process text, images, and audio together
final analysis = await app.analyzeText(content);
await app.generateImage(prompt);
final audioScript = await app.createAudioScript(text);
```

## Best Practices

### Architecture
- Use dependency injection for testability
- Implement proper error boundaries
- Separate business logic from UI components
- Use configuration objects for settings

### Performance
- Implement response caching where appropriate
- Use streaming for better perceived performance
- Optimize for mobile and web platforms
- Monitor memory usage and cleanup resources

### Security
- Validate all user inputs
- Implement proper authentication
- Use HTTPS for all communications
- Store API keys securely

### User Experience
- Provide clear loading states
- Handle errors gracefully with user-friendly messages
- Implement offline capabilities where possible
- Use progressive disclosure for complex features

### Batch Processing
- Implement proper rate limiting to avoid API limits
- Use concurrent processing with semaphores for control
- Provide progress tracking and error reporting
- Handle partial failures gracefully with retry logic

### Multimodal Integration
- Design unified interfaces across different media types
- Implement proper error handling for each modality
- Use appropriate models for each content type
- Consider cross-modal validation and consistency

## Production Example

[Yumcha](https://github.com/Latias94/yumcha) - A production Flutter app built with LLM Dart, showcasing real-world integration patterns, multi-provider support, and advanced features.

## Next Steps

- [Provider Examples](../04_providers/) - Provider-specific features and optimizations
- [Advanced Features](../03_advanced_features/) - Batch processing, real-time audio, semantic search
- [Core Features](../02_core_features/) - Essential functionality
- [Getting Started](../01_getting_started/) - Environment setup and configuration
