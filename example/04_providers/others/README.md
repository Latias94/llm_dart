# Other Provider Integrations

This directory focuses on providers that ride the shared OpenAI-family contract
through stable profiles such as OpenRouter, DeepSeek, Groq, and xAI, plus
explicit custom endpoint wiring when an audited provider does not justify a new
top-level facade.

For new code, prefer stable profile facades:

- `openRouter(...)`
- `deepSeek(...)`
- `groq(...)`
- `xai(...)`

The default modern root import for those profile facades is
`package:llm_dart/llm_dart.dart`.

## Examples

### [openai_compatible.dart](openai_compatible.dart)
Stable OpenAI-family profile showcase plus an explicit custom Together-style
endpoint example.

### [xai_grok.dart](xai_grok.dart)
Stable xAI example built on the `xai(...).chatModel(...)` facade.

## Setup

```bash
export XAI_API_KEY="your-xai-api-key"
export DEEPSEEK_API_KEY="your-deepseek-key"
export GROQ_API_KEY="your-groq-key"
export OPENROUTER_API_KEY="your-openrouter-key"
export TOGETHER_API_KEY="your-together-key"

dart run openai_compatible.dart
dart run xai_grok.dart
```

## Stable Usage Example

### Provider Fallback Strategy

```dart
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;

final providers = <core.LanguageModel>[
  llm.groq(apiKey: 'groq-key').chatModel('llama-3.3-70b-versatile'),
  llm.deepSeek(apiKey: 'deepseek-key').chatModel('deepseek-chat'),
  llm.openRouter(
    apiKey: 'openrouter-key',
    appReferer: 'https://example.com',
    appTitle: 'Example App',
  ).chatModel('openai/gpt-4o-mini'),
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

### Explicit Custom OpenAI-Family Endpoint

```dart
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/openai.dart' as openai;

const togetherProfile = openai.OpenAIProfile(
  providerId: 'together-ai',
  defaultBaseUrl: 'https://api.together.xyz/v1',
  supportsResponsesApi: false,
);

final model = openai.openai(
  apiKey: 'together-key',
  profile: togetherProfile,
).chatModel('meta-llama/Llama-3-70b-chat-hf');

final result = await core.generateTextCall(
  model: model,
  prompt: [
    core.UserPromptMessage.text('Explain why explicit compatible endpoints matter.'),
  ],
);

print(result.text);
```

## Boundary Notes

- OpenAI-compatible does not mean generic shared extensions. Provider-specific
  features should still stay provider owned.
- If a provider shares the OpenAI-family transport/request shape but does not
  deserve a dedicated root facade yet, keep it explicit through
  `openai(..., profile: ...)` or `openai(..., baseUrl: ...)` instead of
  creating another global shortcut immediately.
- For example, OpenRouter online search belongs on
  `OpenRouterChatModelSettings`, and xAI live search belongs on
  `XAIGenerateTextOptions`.
- Broader OpenRouter search mapping and any xAI expansion beyond the current
  audited live-search subset remain deferred provider-owned policy work, not
  shared-contract debt.
- This is why the architecture keeps profiles under the shared model contract
  instead of adding more global builder flags.

## Next Steps

- [xai/](../xai/) - Stable xAI live-search examples
- [Core Features](../../02_core_features/) - Shared text call patterns
- [Advanced Features](../../03_advanced_features/) - Cross-provider workflows
