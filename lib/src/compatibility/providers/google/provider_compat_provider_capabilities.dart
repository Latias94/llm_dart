part of 'provider_compat.dart';

mixin _GoogleProviderCapabilities implements ProviderCapabilities {
  GoogleConfig get config;

  String get providerName => 'Google';

  bool get _supportsTTS => config.supportsTTS;

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.toolCalling,
        if (config.supportsVision) LLMCapability.vision,
        if (config.supportsReasoning) LLMCapability.reasoning,
        if (config.supportsImageGeneration) LLMCapability.imageGeneration,
        if (config.supportsEmbeddings) LLMCapability.embedding,
        if (_supportsTTS) LLMCapability.textToSpeech,
        if (_supportsTTS) LLMCapability.streamingTextToSpeech,
      };

  @override
  bool supports(LLMCapability capability) {
    return supportedCapabilities.contains(capability);
  }
}
