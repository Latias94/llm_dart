# Advanced Features

Sophisticated AI capabilities for production applications with LLM Dart.

This directory is now modern-first:

- stable model-based examples built on short provider factories such as
  `openai(...).chatModel(...)`
- stable transport recipes built on `TransportClient`,
  `DioHttpClientConfig`, and `CallOptions`
- explicit provider-owned appendices only where the capability is not honestly
  cross-provider, such as realtime audio

For new application logic, prefer short provider factories such as
`openai(...)`, the shared helpers from `package:llm_dart/core.dart`, and
transport-owned configuration through `package:llm_dart/transport.dart`.

## Examples

### [reasoning_models.dart](reasoning_models.dart)
AI reasoning with visible thinking processes using DeepSeek R1.

### [multi_modal.dart](multi_modal.dart)
Stable multimodal prompts plus shared image, audio, and file helpers for
composed media workflows.

### [custom_providers.dart](custom_providers.dart)
Stable custom `LanguageModel` implementations and wrapper composition for
testing, logging, caching, and proprietary backends.

### [performance_optimization.dart](performance_optimization.dart)
Stable app-owned caching, batching, streaming, and memory patterns around
shared text calls.

### [batch_processing.dart](batch_processing.dart)
Stable batch orchestration with concurrency, retry, rate limiting, and progress
tracking.

### [semantic_search.dart](semantic_search.dart)
Stable semantic retrieval engine built on shared embedding models.

### [realtime_audio.dart](realtime_audio.dart)
Provider-owned ElevenLabs realtime appendix plus app-owned session/event
orchestration patterns.

### [http_configuration.dart](http_configuration.dart)
Stable transport configuration recipes for proxy, SSL, custom headers, and
logging.

### [layered_http_config.dart](layered_http_config.dart)
Stable layered transport presets plus custom Dio injection patterns.

### [timeout_configuration.dart](timeout_configuration.dart)
Stable timeout layering with `DioHttpClientConfig` and per-call
`CallOptions.timeout`.

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
    llm.deepSeek(apiKey: 'your-key').chatModel('deepseek-reasoner');

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

final model = llm.openai(apiKey: 'your-key').chatModel('gpt-4o');

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
  model: llm.groq(apiKey: 'your-key').chatModel('llama-3.1-8b-instant'),
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

final embeddingModel = llm.openai(
  apiKey: 'your-key',
).embeddingModel('text-embedding-3-small');

final searchEngine = SemanticSearchEngine(embeddingModel);
await searchEngine.indexDocuments(documents);

final results = await searchEngine.search('machine learning');
for (final result in results) {
  print('${result.document.title}: ${result.score}');
}
```

### Stable Transport Recipe: HTTP Configuration

```dart
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/transport.dart' as transport;

final transportClient = transport.DioTransportClient(
  dio: transport.DioHttpClientFactory.createConfiguredDio(
    config: const transport.DioHttpClientConfig(
      baseUrl: 'https://api.openai.com/v1',
      defaultHeaders: <String, String>{},
      customHeaders: <String, String>{
        'X-Custom-Header': 'value',
      },
      connectionTimeout: Duration(seconds: 30),
      enableLogging: true,
    ),
  ),
);

final model = llm.openai(
  apiKey: 'your-key',
  transport: transportClient,
).chatModel('gpt-4.1-mini');
```

### Stable Transport Recipe: Custom Dio Client
```dart
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/transport.dart' as transport;
import 'package:llm_dart_transport/dio.dart' as dio;

// Create custom Dio with advanced features
final customDio = dio.Dio();
customDio.options.connectTimeout = Duration(seconds: 30);
customDio.options.headers['X-Custom-Client'] = 'MyApp/1.0';

// Add monitoring interceptor
customDio.interceptors.add(dio.InterceptorsWrapper(
  onRequest: (options, handler) {
    print('Request: ${options.method} ${options.uri}');
    handler.next(options);
  },
));

final model = llm.anthropic(
  apiKey: 'your-key',
  transport: transport.DioTransportClient(dio: customDio),
).chatModel('claude-3-5-haiku-20241022');
```

### Stable Transport Recipe: Timeout Configuration
```dart
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/transport.dart' as transport;

final transportClient = transport.DioTransportClient(
  dio: transport.DioHttpClientFactory.createConfiguredDio(
    config: const transport.DioHttpClientConfig(
      baseUrl: 'https://api.openai.com/v1',
      defaultHeaders: <String, String>{},
      timeout: Duration(minutes: 2),
      connectionTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(minutes: 5),
    ),
  ),
);

final model = llm.openai(
  apiKey: 'your-key',
  transport: transportClient,
).chatModel('gpt-4.1-mini');

final result = await core.generateTextCall(
  model: model,
  prompt: [
    core.UserPromptMessage.text('Explain timeout layering briefly.'),
  ],
  callOptions: const core.CallOptions(
    timeout: Duration(seconds: 45),
  ),
);

// Priority:
// CallOptions.timeout > transport receive/send timeouts > transport timeout
// Connection timeout stays on the transport client.
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
- Keep transport wiring in the transport layer with typed config objects or
  explicit custom transport clients
- Use `CallOptions` for request-scoped timeout and header overrides instead of
  smuggling them through provider construction
- Avoid forcing provider-native transport or realtime features into a fake
  shared abstraction

### HTTP Configuration
- Use `DioHttpClientConfig` factories for reusable transport presets
- Use a custom Dio client only when you need interceptors, monitoring, or
  specialized infrastructure hooks
- Disable SSL bypass in production environments
- Configure appropriate timeouts for your use case
- Enable logging only in development/debugging
- Validate proxy and certificate configurations
- Implement retry logic and error handling in custom interceptors

### Timeout Configuration
- Use transport timeout defaults for shared infrastructure policy
- Use transport-specific timeouts for fine-grained control
- Use `CallOptions.timeout` when one request needs a different SLA
- Set longer receive timeouts for complex LLM tasks
- Set shorter connection timeouts for quick failure detection
- Consider network conditions (enterprise vs. direct connection)
- Test timeout values under realistic conditions

## Next Steps

- [Provider Examples](../04_providers/) - Provider-specific features and optimizations
- [Use Cases](../05_use_cases/) - Complete applications and Flutter integration
- [Core Features](../02_core_features/) - Essential functionality
- [Getting Started](../01_getting_started/) - Environment setup and configuration
