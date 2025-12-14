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
final model = await ai()
    .groq()
    .apiKey('your-key')
    .model('llama-3.1-8b-instant')
    .buildLanguageModel();

final stopwatch = Stopwatch()..start();

await for (final event in streamTextWithModel(
  model,
  promptMessages: [
    ModelMessage.userText('Generate a quick story'),
  ],
)) {
  if (event is TextDeltaEvent) {
    print('Token: ${event.delta} (${stopwatch.elapsedMilliseconds}ms)');
  }
}
```

## Next Steps

- [Core Features](../../02_core_features/) - Basic chat and streaming
- [Advanced Features](../../03_advanced_features/) - Performance optimization
