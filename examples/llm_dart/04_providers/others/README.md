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
- **GitHub Copilot**: Coding assistance integration
- **Together AI**: Open source model access

## Usage Examples

### Provider Fallback Strategy
```dart
final modelBuilders = [
  () => ai().groqOpenAI().apiKey('groq-key').model('llama-3.3-70b-versatile'),
  () => ai().deepseekOpenAI().apiKey('deepseek-key').model('deepseek-chat'),
  () => ai().openRouter().apiKey('openrouter-key').model('openai/gpt-3.5-turbo'),
];

for (final builder in modelBuilders) {
  try {
    final model = await builder().buildLanguageModel();
    final result = await generateTextPromptWithModel(
      model,
      messages: [
        ModelMessage.userText('Test'),
      ],
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
