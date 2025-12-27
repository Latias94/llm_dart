# Groq Unique Features

Ultra-fast AI inference with custom hardware acceleration.

## Examples

### [fast_inference.dart](fast_inference.dart)
High-speed inference optimization and performance benchmarking.

## Setup

```bash
export GROQ_API_KEY="your-groq-api-key"

# Run Groq speed optimization example
dart run fast_inference.dart
```

## Unique Capabilities

### Ultra-Fast Inference
- **Custom Hardware**: Specialized chips for AI acceleration
- **Low Latency**: 50-100ms time to first token
- **High Throughput**: 500-1000+ tokens per second

## Usage Examples

### Speed-Optimized Streaming
```dart
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_groq/llm_dart_groq.dart';

registerGroq();

final provider = await LLMBuilder()
    .provider(groqProviderId)
    .apiKey('your-key')
    .model('llama-3.1-8b-instant')
    .build();

final stopwatch = Stopwatch()..start();

await for (final part in streamText(
  model: provider,
  messages: [
    ChatMessage.user('Generate a quick story'),
  ],
)) {
  switch (part) {
    case TextDeltaPart(delta: final delta):
      print('Token: $delta (${stopwatch.elapsedMilliseconds}ms)');
      break;
    case FinishPart():
      break;
    case ErrorPart(error: final error):
      print('Error: $error');
      break;
    default:
      break;
  }
}
```

## Next Steps

- [Core Features](../../02_core_features/) - Basic chat and streaming
- [Advanced Features](../../03_advanced_features/) - Performance optimization
