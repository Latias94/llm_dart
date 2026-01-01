library;

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import 'defaults.dart';
import 'config.dart';
import 'provider.dart';

const String googleProviderId = 'google';

void registerGoogle({bool replace = false}) {
  if (!replace && LLMProviderRegistry.isRegistered(googleProviderId)) return;
  final factory = GoogleProviderFactory();
  if (replace) {
    LLMProviderRegistry.registerOrReplace(factory);
    return;
  }
  LLMProviderRegistry.register(factory);
}

class GoogleProviderFactory extends BaseProviderFactory<ChatCapability> {
  @override
  String get providerId => googleProviderId;

  @override
  String get displayName => 'Google';

  @override
  String get description =>
      'Google Gemini models including Gemini 1.5 Flash and Pro';

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.toolCalling,
        // Intentionally optimistic: do not maintain a model capability matrix.
        LLMCapability.embedding,
        LLMCapability.reasoning,
        LLMCapability.vision,
        LLMCapability.imageGeneration,
        LLMCapability.textToSpeech,
        LLMCapability.streamingTextToSpeech,
      };

  @override
  ChatCapability create(LLMConfig config) {
    return createProviderSafely<GoogleConfig>(
      config,
      () => _transformConfig(config),
      (googleConfig) => GoogleProvider(googleConfig),
    );
  }

  @override
  Map<String, dynamic> getProviderDefaults() {
    return {
      'baseUrl': googleBaseUrl,
      'model': googleDefaultModel,
    };
  }

  GoogleConfig _transformConfig(LLMConfig config) {
    return GoogleConfig.fromLLMConfig(config);
  }
}
