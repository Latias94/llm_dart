# Advanced Features

Sophisticated AI capabilities for production applications with LLM Dart.

This directory currently mixes two surfaces:

- stable model-based examples built on `AI.*(...).chatModel(...)`
- compatibility-oriented builder/configuration examples that still document
  legacy HTTP and provider wiring while the migration is ongoing

For new application logic, prefer the stable `AI` facade and the shared helpers
from `package:llm_dart/core.dart`. Builder-heavy infrastructure examples in this
directory should be read as compatibility or transitional material unless they
already use the stable facade explicitly.

## Examples

### [reasoning_models.dart](reasoning_models.dart)
AI reasoning with visible thinking processes using DeepSeek R1.

### [multi_modal.dart](multi_modal.dart)
Stable multimodal prompts plus shared image, audio, and file helpers for
composed media workflows.

### [custom_providers.dart](custom_providers.dart)
Compatibility-oriented custom provider/capability example for testing and
specialized integrations.

### [performance_optimization.dart](performance_optimization.dart)
Stable app-owned caching, batching, streaming, and memory patterns around
shared text calls.

### [batch_processing.dart](batch_processing.dart)
Stable batch orchestration with concurrency, retry, rate limiting, and progress
tracking.

### [semantic_search.dart](semantic_search.dart)
Stable semantic retrieval engine built on shared embedding models.

### [realtime_audio.dart](realtime_audio.dart)
Compatibility-oriented real-time audio capability appendix.

### [http_configuration.dart](http_configuration.dart)
Compatibility-oriented HTTP builder appendix for proxy, SSL, and custom
headers.

### [layered_http_config.dart](layered_http_config.dart)
Compatibility-oriented layered HTTP appendix with custom Dio transport wiring.

### [timeout_configuration.dart](timeout_configuration.dart)
Compatibility-oriented timeout hierarchy appendix on the older builder shell.

## Setup

```bash
# Set up environment variables
export OPENAI_API_KEY="your-openai-key"
export ANTHROPIC_API_KEY="your-anthropic-key"
export DEEPSEEK_API_KEY="your-deepseek-key"
export ELEVENLABS_API_KEY="your-elevenlabs-key"

# Run advanced feature examples
dart run reasoning_models.dart
dart run batch_processing.dart
dart run semantic_search.dart
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
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/core.dart' as core;

final model =
    llm.AI.deepSeek(apiKey: 'your-key').chatModel('deepseek-reasoner');

final result = await core.generateTextCall(
  model: model,
  prompt: [
    core.UserPromptMessage.text('Solve this step by step: 15 + 27 * 3'),
  ],
);

if (result.reasoningText case final reasoning?) {
  print('AI Thinking: $reasoning');
}
print('Answer: ${result.text}');
```

### Multi-modal Processing
```dart
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;

final model = llm.AI.openai(apiKey: 'your-key').chatModel('gpt-4o');

final response = await core.generateTextCall(
  model: model,
  prompt: [
    core.UserPromptMessage(
      parts: [
        const core.TextPromptPart('What do you see in this image?'),
        core.ImagePromptPart(
          mediaType: 'image/jpeg',
          uri: Uri.parse('https://example.com/cat.jpg'),
        ),
      ],
    ),
  ],
);
```

### Batch Processing
```dart
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;

final batchProcessor = BatchProcessor(
  model: llm.AI.groq(apiKey: 'your-key').chatModel('llama-3.1-8b-instant'),
  defaultOptions: const core.GenerateTextOptions(maxOutputTokens: 120),
);
final tasks = List.generate(
  10,
  (i) => BatchTask(id: 'task_$i', prompt: 'Analyze item $i'),
);

final results = await batchProcessor.processBatch(tasks);
print('Completed: ${results.where((r) => r.isSuccess).length}');
```

### Semantic Search
```dart
import 'package:llm_dart/llm_dart.dart' as llm;

final embeddingModel = llm.AI.openai(
  apiKey: 'your-key',
).embeddingModel('text-embedding-3-small');

final searchEngine = SemanticSearchEngine(embeddingModel);
await searchEngine.indexDocuments(documents);

final results = await searchEngine.search('machine learning');
for (final result in results) {
  print('${result.document.title}: ${result.score}');
}
```

### Compatibility Boundary: HTTP Configuration
These transport-wiring examples still live on the compatibility builder shell.

```dart
import 'package:llm_dart/legacy.dart';

// Clean, organized HTTP configuration
final provider = await ai()
    .openai()
    .apiKey('your-key')
    .http((http) => http
        .proxy('http://proxy.company.com:8080')
        .headers({'X-Custom-Header': 'value'})
        .connectionTimeout(Duration(seconds: 30))
        .enableLogging(true))
    .build();
```

### Compatibility Boundary: Custom Dio Client
```dart
import 'package:llm_dart/legacy.dart';

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
final provider = await ai()
    .anthropic()
    .apiKey('your-key')
    .http((http) => http
        .dioClient(customDio)  // Takes priority over other HTTP settings
        .enableLogging(true))  // This will be ignored
    .build();
```

### Compatibility Boundary: Timeout Configuration
```dart
import 'package:llm_dart/legacy.dart';

// Global timeout with HTTP-specific overrides
final provider = await ai()
    .openai()
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

### Architecture Boundary
- Keep batch, retrieval, caching, and memory policies in app-owned code built
  on shared models and helpers
- Treat HTTP wiring and timeout layering as explicit compatibility boundaries
  until the transport migration recipe is simpler
- Avoid forcing provider-native transport or realtime features into a fake
  shared abstraction

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
