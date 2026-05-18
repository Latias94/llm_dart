import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('ModelRegistry', () {
    test('resolves language models from provider references', () {
      final registry = ModelRegistry(
        languageModels: {
          'openai': (modelId) => _FakeLanguageModel('openai', modelId),
        },
      );

      final model = registry.languageModel('openai:gpt-4.1-mini');

      expect(model.providerId, 'openai');
      expect(model.modelId, 'gpt-4.1-mini');
    });

    test('keeps colons that belong to the provider model id', () {
      final registry = ModelRegistry(
        languageModels: {
          'openai': (modelId) => _FakeLanguageModel('openai', modelId),
        },
      );

      final model = registry.languageModel('openai:ft:gpt-4.1-mini:tenant');

      expect(model.modelId, 'ft:gpt-4.1-mini:tenant');
    });

    test('resolves each supported model kind independently', () {
      final registry = ModelRegistry(
        languageModels: {
          'openai': (modelId) => _FakeLanguageModel('openai', modelId),
        },
        embeddingModels: {
          'openai': (modelId) => _FakeEmbeddingModel('openai', modelId),
        },
        imageModels: {
          'google': (modelId) => _FakeImageModel('google', modelId),
        },
        speechModels: {
          'elevenlabs': (modelId) => _FakeSpeechModel('elevenlabs', modelId),
        },
        transcriptionModels: {
          'elevenlabs': (modelId) =>
              _FakeTranscriptionModel('elevenlabs', modelId),
        },
      );

      expect(registry.languageModel('openai:gpt').modelId, 'gpt');
      expect(registry.embeddingModel('openai:text-embedding').modelId,
          'text-embedding');
      expect(registry.imageModel('google:imagen').providerId, 'google');
      expect(registry.speechModel('elevenlabs:tts').providerId, 'elevenlabs');
      expect(
        registry.transcriptionModel('elevenlabs:scribe').modelId,
        'scribe',
      );
    });

    test('reports provider ids for diagnostics and UI selection', () {
      final registry = ModelRegistry(
        languageModels: {
          'ollama': (modelId) => _FakeLanguageModel('ollama', modelId),
          'openai': (modelId) => _FakeLanguageModel('openai', modelId),
        },
      );

      expect(registry.languageProviderIds, ['ollama', 'openai']);
      expect(registry.hasLanguageProvider('openai'), isTrue);
      expect(registry.hasLanguageProvider('anthropic'), isFalse);
      expect(
        () => registry.languageProviderIds.add('anthropic'),
        throwsUnsupportedError,
      );
    });

    test('throws clear errors for unknown providers by model kind', () {
      final registry = ModelRegistry(
        languageModels: {
          'openai': (modelId) => _FakeLanguageModel('openai', modelId),
        },
      );

      expect(
        () => registry.languageModel('anthropic:claude-sonnet-4'),
        throwsA(
          isA<UnsupportedError>()
              .having(
                (error) => error.toString(),
                'message',
                contains('language model provider'),
              )
              .having(
                (error) => error.toString(),
                'message',
                contains('"anthropic"'),
              )
              .having(
                (error) => error.toString(),
                'message',
                contains('openai'),
              ),
        ),
      );
    });

    test('throws clear errors for invalid references', () {
      final registry = ModelRegistry();

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
        () => ModelRegistry(
          languageModels: {
            'OpenAI': (modelId) => _FakeLanguageModel('openai', modelId),
          },
        ),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'languageModels')
              .having(
                (error) => error.invalidValue,
                'invalidValue',
                'OpenAI',
              ),
        ),
      );
    });
  });
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
  int? get maxEmbeddingsPerCall => null;

  @override
  bool get supportsParallelCalls => true;

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
  int? get maxImagesPerCall => null;

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
