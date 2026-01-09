library;

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import 'defaults.dart';
import 'config.dart';
import 'provider.dart';

void registerElevenLabs({bool replace = false}) {
  if (!replace && LLMProviderRegistry.isRegistered(elevenLabsProviderId)) {
    return;
  }
  final factory = ElevenLabsProviderFactory();
  if (replace) {
    LLMProviderRegistry.registerOrReplace(factory);
    return;
  }
  LLMProviderRegistry.register(factory);
}

class ElevenLabsProviderFactory
    extends BaseProviderFactory<ElevenLabsProvider> {
  @override
  String get providerId => elevenLabsProviderId;

  @override
  String get displayName => 'ElevenLabs';

  @override
  String get description =>
      'ElevenLabs text-to-speech and speech recognition services';

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.textToSpeech,
        LLMCapability.streamingTextToSpeech,
        LLMCapability.speechToText,
      };

  @override
  ElevenLabsProvider create(LLMConfig config) {
    return createProviderSafely<ElevenLabsConfig>(
      config,
      () => _transformConfig(config),
      (elevenLabsConfig) => ElevenLabsProvider(elevenLabsConfig),
    );
  }

  @override
  Map<String, dynamic> getProviderDefaults() {
    return {
      'baseUrl': elevenLabsBaseUrl,
      'model': elevenLabsDefaultTTSModel, // Use TTS model as default model
      'voiceId': elevenLabsDefaultVoiceId,
      'ttsModel': elevenLabsDefaultTTSModel,
      'sttModel': elevenLabsDefaultSTTModel,
      'supportedAudioFormats': elevenLabsSupportedAudioFormats,
    };
  }

  ElevenLabsConfig _transformConfig(LLMConfig config) {
    return ElevenLabsConfig.fromLLMConfig(config);
  }
}
