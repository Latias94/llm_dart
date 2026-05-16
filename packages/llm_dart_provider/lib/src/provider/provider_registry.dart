import '../model/embedding_model.dart';
import '../model/image_model.dart';
import '../model/language_model.dart';
import '../model/model_reference.dart';
import '../model/speech_model.dart';
import '../model/transcription_model.dart';
import 'provider.dart';

final class ProviderRegistry {
  final Map<String, Provider> _providers;

  ProviderRegistry({
    Map<String, Provider> providers = const {},
  }) : _providers = _normalizeProviders(providers);

  List<String> get providerIds => _sortedProviderIds(_providers);

  List<String> get languageProviderIds =>
      _sortedProviderIds(_providersByKind<LanguageModelProvider>());

  List<String> get embeddingProviderIds =>
      _sortedProviderIds(_providersByKind<EmbeddingModelProvider>());

  List<String> get imageProviderIds =>
      _sortedProviderIds(_providersByKind<ImageModelProvider>());

  List<String> get speechProviderIds =>
      _sortedProviderIds(_providersByKind<SpeechModelProvider>());

  List<String> get transcriptionProviderIds =>
      _sortedProviderIds(_providersByKind<TranscriptionModelProvider>());

  bool hasProvider(String providerId) => _providers.containsKey(providerId);

  bool hasLanguageProvider(String providerId) =>
      _providers[providerId] is LanguageModelProvider;

  bool hasEmbeddingProvider(String providerId) =>
      _providers[providerId] is EmbeddingModelProvider;

  bool hasImageProvider(String providerId) =>
      _providers[providerId] is ImageModelProvider;

  bool hasSpeechProvider(String providerId) =>
      _providers[providerId] is SpeechModelProvider;

  bool hasTranscriptionProvider(String providerId) =>
      _providers[providerId] is TranscriptionModelProvider;

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

  LanguageModel languageModel(String reference) {
    final parsed = ModelReference.parse(reference);
    final provider = _providerForReference(parsed);
    if (provider is LanguageModelProvider) {
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
    if (provider is EmbeddingModelProvider) {
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
    if (provider is ImageModelProvider) {
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
    if (provider is SpeechModelProvider) {
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
    if (provider is TranscriptionModelProvider) {
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
      if (entry.value.providerId != providerId) {
        throw ArgumentError.value(
          entry.value.providerId,
          'providers',
          'Expected provider.providerId to match the registry key '
              '"$providerId".',
        );
      }
      normalized[providerId] = entry.value;
    }

    return Map.unmodifiable(normalized);
  }

  static Map<String, TProvider>
      _filterProvidersByKind<TProvider extends Provider>(
          Map<String, Provider> providers) {
    return Map.unmodifiable(
      Map.fromEntries(
        providers.entries
            .where((entry) => entry.value is TProvider)
            .map((entry) => MapEntry(entry.key, entry.value as TProvider)),
      ),
    );
  }

  Map<String, TProvider> _providersByKind<TProvider extends Provider>() =>
      _filterProvidersByKind<TProvider>(_providers);

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
