# Use Cases

Complete application examples showing real-world usage patterns with LLM Dart.

## Examples

### [chatbot.dart](chatbot.dart)
Interactive chatbot with personality, context management, and streaming responses.

### [cli_tool.dart](cli_tool.dart)
Command-line AI assistant with multiple provider support and argument parsing.

### [web_service.dart](web_service.dart)
HTTP API service with authentication, rate limiting, and monitoring.

### [flutter_integration.dart](flutter_integration.dart)
Flutter app integration patterns with state management and UI components.

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
dart run flutter_integration.dart
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
final chatbot = Chatbot(
  provider: await ai().openai().apiKey('your-key').build(),
  personality: 'helpful and friendly assistant',
  maxContextLength: 4000,
);

await chatbot.start();
// Interactive conversation loop with streaming
```

### CLI Tool
```dart
final cliTool = CliTool(
  providers: {
    'openai': await ai().openai().apiKey('key').build(),
    'anthropic': await ai().anthropic().apiKey('key').build(),
  },
);

await cliTool.run(args);
// Command-line interface with provider selection
```

### Web Service
```dart
final webService = WebService(
  provider: await ai().groq().apiKey('your-key').build(),
  authMiddleware: JwtAuthMiddleware(),
  rateLimiter: RateLimiter(requestsPerMinute: 60),
);

await webService.start(port: 8080);
// RESTful API with authentication and rate limiting
```

### Flutter Integration
```dart
class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatProvider _chatProvider;

  @override
  void initState() {
    super.initState();
    _chatProvider = ChatProvider();
  }

  // Flutter UI with state management
}
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
