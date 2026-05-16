import 'embedding_model.dart';
import 'image_model.dart';
import 'language_model.dart';
import 'model_reference.dart';
import 'speech_model.dart';
import 'transcription_model.dart';

typedef ModelFactory<TModel> = TModel Function(String modelId);

typedef LanguageModelFactory = ModelFactory<LanguageModel>;

typedef EmbeddingModelFactory = ModelFactory<EmbeddingModel>;

typedef ImageModelFactory = ModelFactory<ImageModel>;

typedef SpeechModelFactory = ModelFactory<SpeechModel>;

typedef TranscriptionModelFactory = ModelFactory<TranscriptionModel>;

/// Factory-map registry kept for low-level adapters and migration code.
///
/// New application and root-facade code should prefer `ProviderRegistry`, which
/// registers provider objects and discovers their supported model facets. This
/// registry remains useful when a custom integration already owns independent
/// per-kind model factories, but it should not shape new provider architecture.
final class ModelRegistry {
  final Map<String, LanguageModelFactory> _languageModels;
  final Map<String, EmbeddingModelFactory> _embeddingModels;
  final Map<String, ImageModelFactory> _imageModels;
  final Map<String, SpeechModelFactory> _speechModels;
  final Map<String, TranscriptionModelFactory> _transcriptionModels;

  ModelRegistry({
    Map<String, LanguageModelFactory> languageModels = const {},
    Map<String, EmbeddingModelFactory> embeddingModels = const {},
    Map<String, ImageModelFactory> imageModels = const {},
    Map<String, SpeechModelFactory> speechModels = const {},
    Map<String, TranscriptionModelFactory> transcriptionModels = const {},
  })  : _languageModels = _normalizeFactories(languageModels,
            parameterName: 'languageModels'),
        _embeddingModels = _normalizeFactories(
          embeddingModels,
          parameterName: 'embeddingModels',
        ),
        _imageModels =
            _normalizeFactories(imageModels, parameterName: 'imageModels'),
        _speechModels =
            _normalizeFactories(speechModels, parameterName: 'speechModels'),
        _transcriptionModels = _normalizeFactories(
          transcriptionModels,
          parameterName: 'transcriptionModels',
        );

  List<String> get languageProviderIds => _sortedProviderIds(_languageModels);

  List<String> get embeddingProviderIds => _sortedProviderIds(_embeddingModels);

  List<String> get imageProviderIds => _sortedProviderIds(_imageModels);

  List<String> get speechProviderIds => _sortedProviderIds(_speechModels);

  List<String> get transcriptionProviderIds =>
      _sortedProviderIds(_transcriptionModels);

  bool hasLanguageProvider(String providerId) =>
      _languageModels.containsKey(providerId);

  bool hasEmbeddingProvider(String providerId) =>
      _embeddingModels.containsKey(providerId);

  bool hasImageProvider(String providerId) =>
      _imageModels.containsKey(providerId);

  bool hasSpeechProvider(String providerId) =>
      _speechModels.containsKey(providerId);

  bool hasTranscriptionProvider(String providerId) =>
      _transcriptionModels.containsKey(providerId);

  LanguageModel languageModel(String reference) {
    final parsed = ModelReference.parse(reference);
    final factory = _languageModels[parsed.providerId];
    if (factory == null) {
      throw _unsupportedProvider(
        kind: 'language model',
        providerId: parsed.providerId,
        availableProviderIds: languageProviderIds,
      );
    }
    return factory(parsed.modelId);
  }

  EmbeddingModel embeddingModel(String reference) {
    final parsed = ModelReference.parse(reference);
    final factory = _embeddingModels[parsed.providerId];
    if (factory == null) {
      throw _unsupportedProvider(
        kind: 'embedding model',
        providerId: parsed.providerId,
        availableProviderIds: embeddingProviderIds,
      );
    }
    return factory(parsed.modelId);
  }

  ImageModel imageModel(String reference) {
    final parsed = ModelReference.parse(reference);
    final factory = _imageModels[parsed.providerId];
    if (factory == null) {
      throw _unsupportedProvider(
        kind: 'image model',
        providerId: parsed.providerId,
        availableProviderIds: imageProviderIds,
      );
    }
    return factory(parsed.modelId);
  }

  SpeechModel speechModel(String reference) {
    final parsed = ModelReference.parse(reference);
    final factory = _speechModels[parsed.providerId];
    if (factory == null) {
      throw _unsupportedProvider(
        kind: 'speech model',
        providerId: parsed.providerId,
        availableProviderIds: speechProviderIds,
      );
    }
    return factory(parsed.modelId);
  }

  TranscriptionModel transcriptionModel(String reference) {
    final parsed = ModelReference.parse(reference);
    final factory = _transcriptionModels[parsed.providerId];
    if (factory == null) {
      throw _unsupportedProvider(
        kind: 'transcription model',
        providerId: parsed.providerId,
        availableProviderIds: transcriptionProviderIds,
      );
    }
    return factory(parsed.modelId);
  }

  static Map<String, TFactory> _normalizeFactories<TFactory>(
    Map<String, TFactory> factories, {
    required String parameterName,
  }) {
    final normalized = <String, TFactory>{};

    for (final entry in factories.entries) {
      final providerId = entry.key.trim();
      ModelReference.validateProviderId(
        providerId,
        parameterName: parameterName,
      );
      normalized[providerId] = entry.value;
    }

    return Map.unmodifiable(normalized);
  }

  static List<String> _sortedProviderIds<TFactory>(
    Map<String, TFactory> factories,
  ) {
    return List<String>.unmodifiable(factories.keys.toList()..sort());
  }

  static UnsupportedError _unsupportedProvider({
    required String kind,
    required String providerId,
    required List<String> availableProviderIds,
  }) {
    final available =
        availableProviderIds.isEmpty ? 'none' : availableProviderIds.join(', ');
    return UnsupportedError(
      'No $kind provider registered for "$providerId". '
      'Available providers: $available.',
    );
  }
}
