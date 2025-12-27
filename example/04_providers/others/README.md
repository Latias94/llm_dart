# Other Provider Integrations

OpenAI-compatible providers and specialized integrations.

## Examples

### [openai_compatible.dart](openai_compatible.dart)
Unified interface for multiple OpenAI-compatible providers.

### [xai_grok.dart](xai_grok.dart)
X.AI Grok integration and configuration.

## Setup

```bash
# Set up API keys for providers you want to use
export XAI_API_KEY="your-xai-api-key"
export DEEPSEEK_API_KEY="your-deepseek-key"
export GROQ_API_KEY="your-groq-key"
export OPENROUTER_API_KEY="your-openrouter-key"

# Run provider integration examples
dart run openai_compatible.dart
dart run xai_grok.dart
```

## Unique Capabilities

### OpenAI-Compatible Interface
- **Unified API**: Same interface across multiple providers
- **Provider Fallback**: Automatic failover between providers
- **Cost Optimization**: Choose providers based on cost and performance

### Specialized Integrations
- **OpenRouter**: Access to multiple models through one API
- **Google (OpenAI-compatible)**: Gemini models via OpenAI-compatible API

## Usage Examples

### Provider Fallback Strategy
```dart
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';

registerOpenAICompatibleProviders();

Future<ChatCapability?> tryBuild(
  String providerId,
  String envVar, {
  required String model,
}) async {
  final apiKey = Platform.environment[envVar];
  if (apiKey == null || apiKey.isEmpty) return null;
  return LLMBuilder().provider(providerId).apiKey(apiKey).model(model).build();
}

final providers = [
  () => tryBuild('groq-openai', 'GROQ_API_KEY', model: 'llama-3.3-70b-versatile'),
  () => tryBuild('deepseek-openai', 'DEEPSEEK_API_KEY', model: 'deepseek-chat'),
  () => tryBuild('openrouter', 'OPENROUTER_API_KEY', model: 'openai/gpt-3.5-turbo'),
];

for (final providerBuilder in providers) {
  try {
    final provider = await providerBuilder();
    if (provider == null) {
      print('Provider skipped (missing API key)');
      continue;
    }
    final result = await generateText(
      model: provider,
      messages: [ChatMessage.user('Test')],
    );
    print('Success: ${result.text}');
    break;
  } catch (e) {
    print('Provider failed, trying next...');
  }
}
```

## Next Steps

- [Core Features](../../02_core_features/) - Basic functionality
- [Advanced Features](../../03_advanced_features/) - Custom providers
