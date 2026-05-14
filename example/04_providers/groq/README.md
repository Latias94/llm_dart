# Groq Provider Features

Groq already fits cleanly into the stable OpenAI-family chat facade.

For new code, prefer:

- `groq(...).chatModel(...)`
- shared `generateTextCall(...)` and `streamTextCall(...)`
- provider-owned Groq profile routing instead of legacy builder setup

## Examples

### [fast_inference.dart](fast_inference.dart)
Stable low-latency benchmark and streaming example.

## Setup

```bash
export GROQ_API_KEY="your-groq-api-key"

dart run fast_inference.dart
```

## Stable Usage Example

```dart
import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/groq.dart' as groq;

final model =
    groq.groq(apiKey: 'your-key').chatModel('llama-3.1-8b-instant');
final stopwatch = Stopwatch()..start();

final stream = core.streamTextCall(
  model: model,
  messages: [
    core.UserModelMessage.text('Generate a quick story.'),
  ],
  options: const core.GenerateTextOptions(
    temperature: 0.7,
    maxOutputTokens: 300,
  ),
);

await for (final event in stream) {
  switch (event) {
    case core.TextDeltaEvent(:final delta):
      stdout.write('${stopwatch.elapsedMilliseconds}ms: $delta');
    default:
      break;
  }
}
```

## Capability Notes

- Groq's differentiation is mostly transport, latency, and throughput, not a
  separate shared abstraction.
- The stable architecture therefore keeps Groq on the shared `LanguageModel`
  contract instead of inventing a Groq-specific app-facing interface.
- The design direction is a shared model contract with provider-owned
  transport and request shaping.

## Next Steps

- [Core Features](../../02_core_features/) - Stable text and streaming patterns
- [Advanced Features](../../03_advanced_features/) - Shared performance examples
