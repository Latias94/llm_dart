import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('ProviderRegistry', () {
    test('resolves language models from provider objects', () {
      final provider = _AllModelProvider('openai');
      final registry = ProviderRegistry(
        providers: {
          'openai': provider,
        },
      );

      final model = registry.languageModel('openai:gpt-4.1-mini');

      expect(model.providerId, 'openai');
      expect(model.modelId, 'gpt-4.1-mini');
    });

    test('keeps colons that belong to the provider model id', () {
      final registry = ProviderRegistry(
        providers: {
          'openai': _AllModelProvider('openai'),
        },
      );

      final model = registry.languageModel('openai:ft:gpt-4.1-mini:tenant');

      expect(model.modelId, 'ft:gpt-4.1-mini:tenant');
    });

    test('resolves each supported model kind from one provider object', () {
      final registry = ProviderRegistry(
        providers: {
          'test': _AllModelProvider('test'),
        },
      );

      expect(registry.languageModel('test:chat').modelId, 'chat');
      expect(registry.embeddingModel('test:embed').modelId, 'embed');
      expect(registry.imageModel('test:image').modelId, 'image');
      expect(registry.speechModel('test:speech').modelId, 'speech');
      expect(
          registry.transcriptionModel('test:transcribe').modelId, 'transcribe');
    });

    test('reports provider ids by supported capability', () {
      final registry = ProviderRegistry(
        providers: {
          'ollama': _EmbeddingOnlyProvider('ollama'),
          'openai': _LanguageOnlyProvider('openai'),
        },
      );

      expect(registry.providerIds, ['ollama', 'openai']);
      expect(registry.languageProviderIds, ['openai']);
      expect(registry.embeddingProviderIds, ['ollama']);
      expect(registry.hasProvider('openai'), isTrue);
      expect(registry.hasLanguageProvider('openai'), isTrue);
      expect(registry.hasLanguageProvider('ollama'), isFalse);
      expect(registry.hasEmbeddingProvider('ollama'), isTrue);
      expect(
        () => registry.providerIds.add('anthropic'),
        throwsUnsupportedError,
      );
    });

    test('honors provider-declared facet support', () {
      final registry = ProviderRegistry(
        providers: {
          'limited': _LimitedFacetProvider('limited'),
        },
      );

      expect(registry.languageProviderIds, ['limited']);
      expect(registry.embeddingProviderIds, isEmpty);
      expect(registry.hasLanguageProvider('limited'), isTrue);
      expect(registry.hasEmbeddingProvider('limited'), isFalse);
      expect(registry.languageModel('limited:chat').providerId, 'limited');
      expect(
        () => registry.embeddingModel('limited:embed'),
        throwsUnsupportedError,
      );
    });

    test('returns registered provider objects by id', () {
      final provider = _LanguageOnlyProvider('openai');
      final registry = ProviderRegistry(
        providers: {
          'openai': provider,
        },
      );

      expect(identical(registry.provider('openai'), provider), isTrue);
    });

    test('throws clear errors for unknown providers', () {
      final registry = ProviderRegistry(
        providers: {
          'openai': _LanguageOnlyProvider('openai'),
        },
      );

      expect(
        () => registry.languageModel('anthropic:claude-sonnet-4'),
        throwsA(
          isA<UnsupportedError>()
              .having(
                (error) => error.toString(),
                'message',
                contains('No provider registered for "anthropic"'),
              )
              .having(
                (error) => error.toString(),
                'message',
                contains('openai'),
              ),
        ),
      );
    });

    test('throws clear errors for unsupported model kinds', () {
      final registry = ProviderRegistry(
        providers: {
          'openai': _LanguageOnlyProvider('openai'),
        },
      );

      expect(
        () => registry.embeddingModel('openai:text-embedding'),
        throwsA(
          isA<UnsupportedError>()
              .having(
                (error) => error.toString(),
                'message',
                contains('Provider "openai" does not support embedding model'),
              )
              .having(
                (error) => error.toString(),
                'message',
                contains('Available embedding model providers: none'),
              ),
        ),
      );
    });

    test('throws clear errors for invalid references', () {
      final registry = ProviderRegistry();

      expect(
        () => registry.languageModel('openai'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => registry.languageModel(':gpt-4.1-mini'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => registry.languageModel('openai:'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => registry.languageModel('OpenAI:gpt-4.1-mini'),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.name,
            'name',
            'reference',
          ),
        ),
      );
    });

    test('validates provider ids when configured', () {
      expect(
        () => ProviderRegistry(
          providers: {
            'OpenAI': _LanguageOnlyProvider('openai'),
          },
        ),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'providers')
              .having(
                (error) => error.invalidValue,
                'invalidValue',
                'OpenAI',
              ),
        ),
      );
    });

    test('requires registry key and provider identity to match', () {
      expect(
        () => ProviderRegistry(
          providers: {
            'openai': _LanguageOnlyProvider('openrouter'),
          },
        ),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'providers')
              .having(
                (error) => error.invalidValue,
                'invalidValue',
                'openrouter',
              ),
        ),
      );
    });
  });
}

final class _AllModelProvider
    implements
        LanguageModelProvider,
        EmbeddingModelProvider,
        ImageModelProvider,
        SpeechModelProvider,
        TranscriptionModelProvider {
  @override
  final String providerId;

  _AllModelProvider(this.providerId);

  @override
  LanguageModel languageModel(String modelId) {
    return _FakeLanguageModel(providerId, modelId);
  }

  @override
  EmbeddingModel embeddingModel(String modelId) {
    return _FakeEmbeddingModel(providerId, modelId);
  }

  @override
  ImageModel imageModel(String modelId) {
    return _FakeImageModel(providerId, modelId);
  }

  @override
  SpeechModel speechModel(String modelId) {
    return _FakeSpeechModel(providerId, modelId);
  }

  @override
  TranscriptionModel transcriptionModel(String modelId) {
    return _FakeTranscriptionModel(providerId, modelId);
  }
}

final class _LanguageOnlyProvider implements LanguageModelProvider {
  @override
  final String providerId;

  const _LanguageOnlyProvider(this.providerId);

  @override
  LanguageModel languageModel(String modelId) {
    return _FakeLanguageModel(providerId, modelId);
  }
}

final class _EmbeddingOnlyProvider implements EmbeddingModelProvider {
  @override
  final String providerId;

  const _EmbeddingOnlyProvider(this.providerId);

  @override
  EmbeddingModel embeddingModel(String modelId) {
    return _FakeEmbeddingModel(providerId, modelId);
  }
}

final class _LimitedFacetProvider
    implements
        ProviderModelFacetSupport,
        LanguageModelProvider,
        EmbeddingModelProvider {
  @override
  final String providerId;

  const _LimitedFacetProvider(this.providerId);

  @override
  bool get supportsLanguageModels => true;

  @override
  bool get supportsEmbeddingModels => false;

  @override
  bool get supportsImageModels => false;

  @override
  bool get supportsSpeechModels => false;

  @override
  bool get supportsTranscriptionModels => false;

  @override
  LanguageModel languageModel(String modelId) {
    return _FakeLanguageModel(providerId, modelId);
  }

  @override
  EmbeddingModel embeddingModel(String modelId) {
    return _FakeEmbeddingModel(providerId, modelId);
  }
}

final class _FakeLanguageModel implements LanguageModel {
  @override
  final String providerId;

  @override
  final String modelId;

  const _FakeLanguageModel(this.providerId, this.modelId);

  @override
  Future<GenerateTextResult> doGenerate(GenerateTextRequest request) async {
    return GenerateTextResult(
      content: const [TextContentPart('ok')],
      finishReason: FinishReason.stop,
    );
  }

  @override
  Stream<LanguageModelStreamEvent> doStream(GenerateTextRequest request) {
    return Stream.value(
      const TextDeltaEvent(
        id: 'text-1',
        delta: 'ok',
      ),
    );
  }
}

final class _FakeEmbeddingModel implements EmbeddingModel {
  @override
  final String providerId;

  @override
  final String modelId;

  const _FakeEmbeddingModel(this.providerId, this.modelId);

  @override
  Future<EmbedResult> doEmbed(EmbedRequest request) async {
    return EmbedResult(
      embeddings: [
        List<double>.filled(request.values.length, 0),
      ],
    );
  }
}

final class _FakeImageModel implements ImageModel {
  @override
  final String providerId;

  @override
  final String modelId;

  const _FakeImageModel(this.providerId, this.modelId);

  @override
  Future<ImageGenerationResult> doGenerate(
    ImageGenerationRequest request,
  ) async {
    return ImageGenerationResult(
      images: const [GeneratedImage()],
    );
  }
}

final class _FakeSpeechModel implements SpeechModel {
  @override
  final String providerId;

  @override
  final String modelId;

  const _FakeSpeechModel(this.providerId, this.modelId);

  @override
  Future<SpeechGenerationResult> doGenerate(
    SpeechGenerationRequest request,
  ) async {
    return const SpeechGenerationResult(audioBytes: [1, 2, 3]);
  }
}

final class _FakeTranscriptionModel implements TranscriptionModel {
  @override
  final String providerId;

  @override
  final String modelId;

  const _FakeTranscriptionModel(this.providerId, this.modelId);

  @override
  Future<TranscriptionResult> doGenerate(
    TranscriptionRequest request,
  ) async {
    return const TranscriptionResult(text: 'ok');
  }
}
