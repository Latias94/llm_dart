import 'provider.dart';
import 'provider_specification.dart';

final class ProviderModelFacetSupportResolver {
  const ProviderModelFacetSupportResolver();

  bool supportsLanguageModels(Provider? provider) {
    return provider is LanguageModelProvider &&
        _declaresSupport(
          provider,
          ProviderModelFacet.language,
          (support) => support.supportsLanguageModels,
        );
  }

  bool supportsEmbeddingModels(Provider? provider) {
    return provider is EmbeddingModelProvider &&
        _declaresSupport(
          provider,
          ProviderModelFacet.embedding,
          (support) => support.supportsEmbeddingModels,
        );
  }

  bool supportsImageModels(Provider? provider) {
    return provider is ImageModelProvider &&
        _declaresSupport(
          provider,
          ProviderModelFacet.image,
          (support) => support.supportsImageModels,
        );
  }

  bool supportsSpeechModels(Provider? provider) {
    return provider is SpeechModelProvider &&
        _declaresSupport(
          provider,
          ProviderModelFacet.speech,
          (support) => support.supportsSpeechModels,
        );
  }

  bool supportsTranscriptionModels(Provider? provider) {
    return provider is TranscriptionModelProvider &&
        _declaresSupport(
          provider,
          ProviderModelFacet.transcription,
          (support) => support.supportsTranscriptionModels,
        );
  }

  static bool _declaresSupport(
    Provider provider,
    ProviderModelFacet facet,
    bool Function(ProviderModelFacetSupport support) readSupport,
  ) {
    if (!provider.specification.supportsModelFacet(facet)) {
      return false;
    }
    if (provider is ProviderModelFacetSupport) {
      return readSupport(provider);
    }
    return true;
  }
}
