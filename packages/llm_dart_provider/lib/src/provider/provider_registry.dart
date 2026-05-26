import '../model/embedding_model.dart';
import '../model/image_model.dart';
import '../model/language_model.dart';
import '../model/model_reference.dart';
import '../model/speech_model.dart';
import '../model/transcription_model.dart';
import 'provider.dart';
import 'provider_capability_gate.dart';
import 'provider_model_facet_support.dart';
import 'provider_specification.dart';

final class ProviderRegistry {
  static const _facetSupport = ProviderModelFacetSupportResolver();

  final Map<String, Provider> _providers;

  ProviderRegistry({
    Map<String, Provider> providers = const {},
  }) : _providers = _normalizeProviders(providers);

  List<String> get providerIds => _sortedProviderIds(_providers);

  List<ProviderSpecification> get providerSpecifications =>
      List<ProviderSpecification>.unmodifiable(
        providerIds.map((providerId) => _providers[providerId]!.specification),
      );

  List<String> get languageProviderIds => _sortedProviderIds(
        _providersBySupport(_facetSupport.supportsLanguageModels),
      );

  List<String> get embeddingProviderIds => _sortedProviderIds(
        _providersBySupport(_facetSupport.supportsEmbeddingModels),
      );

  List<String> get imageProviderIds => _sortedProviderIds(
        _providersBySupport(_facetSupport.supportsImageModels),
      );

  List<String> get speechProviderIds => _sortedProviderIds(
        _providersBySupport(_facetSupport.supportsSpeechModels),
      );

  List<String> get transcriptionProviderIds => _sortedProviderIds(
        _providersBySupport(_facetSupport.supportsTranscriptionModels),
      );

  bool hasProvider(String providerId) => _providers.containsKey(providerId);

  bool hasLanguageProvider(String providerId) =>
      _facetSupport.supportsLanguageModels(_providers[providerId]);

  bool hasEmbeddingProvider(String providerId) =>
      _facetSupport.supportsEmbeddingModels(_providers[providerId]);

  bool hasImageProvider(String providerId) =>
      _facetSupport.supportsImageModels(_providers[providerId]);

  bool hasSpeechProvider(String providerId) =>
      _facetSupport.supportsSpeechModels(_providers[providerId]);

  bool hasTranscriptionProvider(String providerId) =>
      _facetSupport.supportsTranscriptionModels(_providers[providerId]);

  Provider provider(String providerId) {
    ModelReference.validateProviderId(
      providerId,
      parameterName: 'providerId',
    );

    final provider = _providers[providerId];
    if (provider != null) {
      return provider;
    }

    throw _unsupportedProvider(
      providerId: providerId,
      availableProviderIds: providerIds,
    );
  }

  ProviderSpecification providerSpecification(String providerId) {
    return provider(providerId).specification;
  }

  ProviderCapabilityGate providerCapabilityGate(String providerId) {
    return ProviderCapabilityGate.forProvider(provider(providerId));
  }

  LanguageModel languageModel(String reference) {
    final parsed = ModelReference.parse(reference);
    final provider = _providerForReference(parsed);
    if (_facetSupport.supportsLanguageModels(provider) &&
        provider is LanguageModelProvider) {
      return provider.languageModel(parsed.modelId);
    }

    throw _unsupportedModelKind(
      kind: 'language model',
      providerId: parsed.providerId,
      availableProviderIds: languageProviderIds,
    );
  }

  EmbeddingModel embeddingModel(String reference) {
    final parsed = ModelReference.parse(reference);
    final provider = _providerForReference(parsed);
    if (_facetSupport.supportsEmbeddingModels(provider) &&
        provider is EmbeddingModelProvider) {
      return provider.embeddingModel(parsed.modelId);
    }

    throw _unsupportedModelKind(
      kind: 'embedding model',
      providerId: parsed.providerId,
      availableProviderIds: embeddingProviderIds,
    );
  }

  ImageModel imageModel(String reference) {
    final parsed = ModelReference.parse(reference);
    final provider = _providerForReference(parsed);
    if (_facetSupport.supportsImageModels(provider) &&
        provider is ImageModelProvider) {
      return provider.imageModel(parsed.modelId);
    }

    throw _unsupportedModelKind(
      kind: 'image model',
      providerId: parsed.providerId,
      availableProviderIds: imageProviderIds,
    );
  }

  SpeechModel speechModel(String reference) {
    final parsed = ModelReference.parse(reference);
    final provider = _providerForReference(parsed);
    if (_facetSupport.supportsSpeechModels(provider) &&
        provider is SpeechModelProvider) {
      return provider.speechModel(parsed.modelId);
    }

    throw _unsupportedModelKind(
      kind: 'speech model',
      providerId: parsed.providerId,
      availableProviderIds: speechProviderIds,
    );
  }

  TranscriptionModel transcriptionModel(String reference) {
    final parsed = ModelReference.parse(reference);
    final provider = _providerForReference(parsed);
    if (_facetSupport.supportsTranscriptionModels(provider) &&
        provider is TranscriptionModelProvider) {
      return provider.transcriptionModel(parsed.modelId);
    }

    throw _unsupportedModelKind(
      kind: 'transcription model',
      providerId: parsed.providerId,
      availableProviderIds: transcriptionProviderIds,
    );
  }

  Provider _providerForReference(ModelReference reference) {
    final provider = _providers[reference.providerId];
    if (provider != null) {
      return provider;
    }

    throw _unsupportedProvider(
      providerId: reference.providerId,
      availableProviderIds: providerIds,
    );
  }

  static Map<String, Provider> _normalizeProviders(
    Map<String, Provider> providers,
  ) {
    final normalized = <String, Provider>{};

    for (final entry in providers.entries) {
      final providerId = entry.key.trim();
      ModelReference.validateProviderId(
        providerId,
        parameterName: 'providers',
      );
      ModelReference.validateProviderId(
        entry.value.providerId,
        parameterName: 'provider.providerId',
      );
      ModelReference.validateProviderId(
        entry.value.specification.providerId,
        parameterName: 'provider.specification.providerId',
      );
      if (entry.value.providerId != providerId) {
        throw ArgumentError.value(
          entry.value.providerId,
          'providers',
          'Expected provider.providerId to match the registry key '
              '"$providerId".',
        );
      }
      if (entry.value.specification.providerId != providerId) {
        throw ArgumentError.value(
          entry.value.specification.providerId,
          'providers',
          'Expected provider.specification.providerId to match the registry '
              'key "$providerId".',
        );
      }
      normalized[providerId] = entry.value;
    }

    return Map.unmodifiable(normalized);
  }

  Map<String, Provider> _providersBySupport(
    bool Function(Provider? provider) supports,
  ) {
    return Map.unmodifiable(
      Map.fromEntries(
        _providers.entries.where((entry) => supports(entry.value)),
      ),
    );
  }

  static List<String> _sortedProviderIds<TProvider extends Provider>(
    Map<String, TProvider> providers,
  ) {
    return List<String>.unmodifiable(providers.keys.toList()..sort());
  }

  static UnsupportedError _unsupportedProvider({
    required String providerId,
    required List<String> availableProviderIds,
  }) {
    final available =
        availableProviderIds.isEmpty ? 'none' : availableProviderIds.join(', ');
    return UnsupportedError(
      'No provider registered for "$providerId". '
      'Available providers: $available.',
    );
  }

  static UnsupportedError _unsupportedModelKind({
    required String kind,
    required String providerId,
    required List<String> availableProviderIds,
  }) {
    final available =
        availableProviderIds.isEmpty ? 'none' : availableProviderIds.join(', ');
    return UnsupportedError(
      'Provider "$providerId" does not support $kind lookup. '
      'Available $kind providers: $available.',
    );
  }
}
