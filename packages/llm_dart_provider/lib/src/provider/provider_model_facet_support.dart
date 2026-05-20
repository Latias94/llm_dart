import 'provider.dart';

final class ProviderModelFacetSupportResolver {
  const ProviderModelFacetSupportResolver();

  bool supportsLanguageModels(Provider? provider) {
    return provider is LanguageModelProvider &&
        _declaresSupport(
          provider,
          (support) => support.supportsLanguageModels,
        );
  }

  bool supportsEmbeddingModels(Provider? provider) {
    return provider is EmbeddingModelProvider &&
        _declaresSupport(
          provider,
          (support) => support.supportsEmbeddingModels,
        );
  }

  bool supportsImageModels(Provider? provider) {
    return provider is ImageModelProvider &&
        _declaresSupport(
          provider,
          (support) => support.supportsImageModels,
        );
  }

  bool supportsSpeechModels(Provider? provider) {
    return provider is SpeechModelProvider &&
        _declaresSupport(
          provider,
          (support) => support.supportsSpeechModels,
        );
  }

  bool supportsTranscriptionModels(Provider? provider) {
    return provider is TranscriptionModelProvider &&
        _declaresSupport(
          provider,
          (support) => support.supportsTranscriptionModels,
        );
  }

  static bool _declaresSupport(
    Provider provider,
    bool Function(ProviderModelFacetSupport support) readSupport,
  ) {
    if (provider is ProviderModelFacetSupport) {
      return readSupport(provider);
    }
    return true;
  }
}
