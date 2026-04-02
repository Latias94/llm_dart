# Other Provider Integrations

This directory focuses on providers that ride the shared OpenAI-family contract
through profiles such as OpenRouter, DeepSeek, Groq, and xAI.

For new code, prefer stable profile facades:

- `AI.openRouter(...)`
- `AI.deepSeek(...)`
- `AI.groq(...)`
- `AI.xai(...)`

## Examples

### [openai_compatible.dart](openai_compatible.dart)
Transitional OpenAI-compatible provider showcase.

### [xai_grok.dart](xai_grok.dart)
Stable xAI example built on the `AI.xai(...).chatModel(...)` facade.

## Setup

```bash
export XAI_API_KEY="your-xai-api-key"
export DEEPSEEK_API_KEY="your-deepseek-key"
export GROQ_API_KEY="your-groq-key"
export OPENROUTER_API_KEY="your-openrouter-key"

dart run openai_compatible.dart
dart run xai_grok.dart
```

## Stable Usage Example

### Provider Fallback Strategy

```dart
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/ai.dart' as llm;

final providers = <core.LanguageModel>[
  llm.AI.groq(apiKey: 'groq-key').chatModel('llama-3.3-70b-versatile'),
  llm.AI.deepSeek(apiKey: 'deepseek-key').chatModel('deepseek-chat'),
  llm.AI.openRouter(apiKey: 'openrouter-key').chatModel('openai/gpt-4o-mini'),
];

for (final model in providers) {
  try {
    final response = await core.generateTextCall(
      model: model,
      prompt: [
        core.UserPromptMessage.text('Test'),
      ],
      options: const core.GenerateTextOptions(
        maxOutputTokens: 120,
      ),
    );
    print('Success via ${model.providerId}: ${response.text}');
    break;
  } catch (_) {
    print('Provider failed, trying next...');
  }
}
```

## Boundary Notes

- OpenAI-compatible does not mean generic shared extensions. Provider-specific
  features should still stay provider owned.
- For example, OpenRouter online search belongs on
  `OpenRouterChatModelSettings`, and xAI live search belongs on
  `XAIGenerateTextOptions`.
- This is why the architecture keeps profiles under the shared model contract
  instead of adding more global builder flags.

## Next Steps

- [xai/](../xai/) - Stable xAI live-search examples
- [Core Features](../../02_core_features/) - Shared text call patterns
- [Advanced Features](../../03_advanced_features/) - Cross-provider workflows
