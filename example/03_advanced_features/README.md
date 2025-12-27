# Advanced Features

Sophisticated AI capabilities for production applications with LLM Dart.

## Examples

### [reasoning_models.dart](reasoning_models.dart)
AI reasoning with visible thinking processes using DeepSeek R1.

### [multi_modal.dart](multi_modal.dart)
Image, audio, and document processing with AI models.

### [custom_providers.dart](custom_providers.dart)
Build custom AI providers with specialized functionality.

### [performance_optimization.dart](performance_optimization.dart)
Caching, batching, and optimization for production workloads.

### [batch_processing.dart](batch_processing.dart)
Concurrent processing with rate limiting and error handling.

### [semantic_search.dart](semantic_search.dart)
Embedding-based search engine with hybrid ranking.

### [realtime_audio.dart](realtime_audio.dart)
Real-time audio streaming and voice activity detection.

### [http_configuration.dart](http_configuration.dart)
Comprehensive HTTP configuration with proxy, SSL, and custom headers.

### [layered_http_config.dart](layered_http_config.dart)
New layered HTTP configuration approach with custom Dio client support for advanced HTTP control.

### [timeout_configuration.dart](timeout_configuration.dart)
Comprehensive timeout configuration with priority hierarchy and best practices.

## Setup

```bash
# Set up environment variables
export OPENAI_API_KEY="your-openai-key"
export ANTHROPIC_API_KEY="your-anthropic-key"
export DEEPSEEK_API_KEY="your-deepseek-key"
export ELEVENLABS_API_KEY="your-elevenlabs-key"

# Run advanced feature examples
dart run reasoning_models.dart
dart run multi_modal.dart
dart run custom_providers.dart
dart run performance_optimization.dart
```

## Key Concepts

### Reasoning Models
- **Thinking Process**: Access to AI's internal reasoning steps
- **Complex Problems**: Better performance on multi-step tasks
- **DeepSeek R1**: Visible thinking process for learning and debugging
- **Streaming**: Real-time reasoning with progressive thinking

### Multi-modal Processing
- **Vision**: Image analysis and understanding
- **Audio**: Speech-to-text and text-to-speech
- **Documents**: PDF and file processing
- **Integration**: Combining different input modalities

### Performance Optimization
- **Batch Processing**: Concurrent request handling with rate limits
- **Semantic Search**: Vector-based search with embeddings
- **Real-time Audio**: Low-latency streaming and voice detection
- **Custom Providers**: Specialized implementations for specific needs

### HTTP Configuration
- **Layered Configuration**: Clean, organized HTTP settings
- **Custom Dio Client**: Complete HTTP control with custom interceptors
- **Proxy Support**: Corporate proxy and network configuration
- **SSL Configuration**: Custom certificates and security settings
- **Request Customization**: Headers, timeouts, and logging
- **Timeout Hierarchy**: Global and HTTP-specific timeout configuration

## Usage Examples

### Reasoning with DeepSeek R1
```dart
// Access AI thinking process
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_deepseek/llm_dart_deepseek.dart';

registerDeepSeek();

final provider = await LLMBuilder()
    .provider(deepseekProviderId)
    .apiKey('your-key')
    .model('deepseek-reasoner')
    .build();

final result = await generateText(
  model: provider,
  messages: [ChatMessage.user('Solve this step by step: 15 + 27 * 3')],
);

// Access thinking process
if (result.thinking != null) {
  print('AI Thinking: ${result.thinking}');
}
print('Answer: ${result.text}');
```

### Multi-modal Processing
```dart
// Process image with text
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';

registerOpenAI();

final provider = await LLMBuilder()
    .provider(openaiProviderId)
    .apiKey('your-key')
    .build();

final result = await generateText(
  model: provider,
  messages: [
    ChatMessage.imageUrl(
      role: ChatRole.user,
      url: 'https://example.com/image.jpg',
      content: 'What do you see in this image?',
    ),
  ],
);

print(result.text);
```

### Batch Processing
```dart
// Process multiple requests concurrently
final batchProcessor = BatchProcessor(provider);
final tasks = List.generate(10, (i) =>
  BatchTask(id: 'task_$i', prompt: 'Analyze item $i'));

final results = await batchProcessor.processBatch(tasks);
print('Completed: ${results.where((r) => r.isSuccess).length}');
```

### Semantic Search
```dart
// Build search engine with embeddings
final searchEngine = SemanticSearchEngine(embeddingProvider);
await searchEngine.indexDocuments(documents);

final results = await searchEngine.search('machine learning');
for (final result in results) {
  print('${result.document.title}: ${result.score}');
}
```

### HTTP Configuration (Layered Approach)
```dart
// Clean, organized HTTP configuration
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';

registerOpenAI();

final provider = await LLMBuilder()
    .provider(openaiProviderId)
    .apiKey('your-key')
    .http((http) => http
        .proxy('http://proxy.company.com:8080')
        .headers({'X-Custom-Header': 'value'})
        .connectionTimeout(Duration(seconds: 30))
        .enableLogging(true))
    .build();
```

### Custom Dio Client (Advanced HTTP Control)
```dart
// Create custom Dio with advanced features
final customDio = Dio();
customDio.options.connectTimeout = Duration(seconds: 30);
customDio.options.headers['X-Custom-Client'] = 'MyApp/1.0';

// Add monitoring interceptor
customDio.interceptors.add(InterceptorsWrapper(
  onRequest: (options, handler) {
    print('Request: ${options.method} ${options.uri}');
    handler.next(options);
  },
));

// Use custom Dio (highest priority)
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';

registerAnthropic();

final provider = await LLMBuilder()
    .provider(anthropicProviderId)
    .apiKey('your-key')
    .http((http) => http
        .dioClient(customDio)  // Takes priority over other HTTP settings
        .enableLogging(true))  // This will be ignored
    .build();
```

### Timeout Configuration (Priority Hierarchy)
```dart
// Global timeout with HTTP-specific overrides
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';

registerOpenAI();

final provider = await LLMBuilder()
    .provider(openaiProviderId)
    .apiKey('your-key')
    .timeout(Duration(minutes: 2))     // Global default: 2 minutes
    .http((http) => http
        .connectionTimeout(Duration(seconds: 30))  // Override connection: 30s
        .receiveTimeout(Duration(minutes: 5)))     // Override receive: 5min
        // sendTimeout will use global timeout (2 minutes)
    .build();

// Priority: HTTP-specific > Global > Provider defaults > System defaults
```

## Best Practices

### Reasoning Models
- Use DeepSeek R1 when you need to see thinking process
- Allow extra time for reasoning (slower but more accurate)
- Analyze thinking patterns for insights and debugging
- Compare with standard models for cost/accuracy trade-offs

### Performance Optimization
- Implement proper batch sizes for your use case
- Use rate limiting to avoid API throttling
- Cache embeddings and frequent responses
- Monitor costs and optimize accordingly

### Multi-modal Processing
- Validate input formats before processing
- Handle different modalities gracefully
- Optimize image sizes for faster processing
- Use appropriate models for each modality

### HTTP Configuration
- Use layered configuration for better organization
- Use custom Dio client for advanced HTTP control and monitoring
- Disable SSL bypass in production environments
- Configure appropriate timeouts for your use case
- Enable logging only in development/debugging
- Validate proxy and certificate configurations
- Implement retry logic and error handling in custom interceptors

### Timeout Configuration
- Use global timeout for simple scenarios
- Use HTTP-specific timeouts for fine-grained control
- Set longer receive timeouts for complex LLM tasks
- Set shorter connection timeouts for quick failure detection
- Consider network conditions (enterprise vs. direct connection)
- Test timeout values under realistic conditions

## Next Steps

- [Provider Examples](../04_providers/) - Provider-specific features and optimizations
- [Use Cases](../05_use_cases/) - Complete applications and Flutter integration
- [Core Features](../02_core_features/) - Essential functionality
- [Getting Started](../01_getting_started/) - Environment setup and configuration
