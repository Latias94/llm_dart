import 'provider.dart';
import 'provider_capability_gate.dart';
import 'provider_specification.dart';

final class ProviderModelFacetSupportResolver {
  const ProviderModelFacetSupportResolver();

  bool supportsLanguageModels(Provider? provider) {
    return _allowsModelFacet(provider, ProviderModelFacet.language);
  }

  bool supportsEmbeddingModels(Provider? provider) {
    return _allowsModelFacet(provider, ProviderModelFacet.embedding);
  }

  bool supportsImageModels(Provider? provider) {
    return _allowsModelFacet(provider, ProviderModelFacet.image);
  }

  bool supportsSpeechModels(Provider? provider) {
    return _allowsModelFacet(provider, ProviderModelFacet.speech);
  }

  bool supportsTranscriptionModels(Provider? provider) {
    return _allowsModelFacet(provider, ProviderModelFacet.transcription);
  }

  static bool _allowsModelFacet(
    Provider? provider,
    ProviderModelFacet facet,
  ) {
    if (provider == null) {
      return false;
    }
    return ProviderCapabilityGate.forProvider(provider)
        .modelFacet(facet)
        .allowed;
  }
}
