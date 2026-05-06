import '../../core/capability.dart';
import '../../core/config.dart';
import 'compat_providers.dart';

ChatCapability? tryCreateCompatProvider({
  required String providerId,
  required LLMConfig config,
}) {
  if (!_hasRequiredCoreConfig(config)) {
    return null;
  }

  return switch (providerId) {
    'openai' => buildCompatOpenAIProvider(config),
    'deepseek' => buildCompatDeepSeekProvider(config),
    'openrouter' => buildCompatOpenRouterProvider(config),
    'groq' => buildCompatGroqProvider(config),
    'xai' => buildCompatXAIProvider(config),
    'phind' => buildCompatPhindProvider(config),
    'google' => buildCompatGoogleProvider(config),
    'anthropic' => buildCompatAnthropicProvider(config),
    _ => null,
  };
}

bool _hasRequiredCoreConfig(LLMConfig config) {
  return config.apiKey != null &&
      config.apiKey!.isNotEmpty &&
      config.baseUrl.isNotEmpty &&
      config.model.isNotEmpty;
}
