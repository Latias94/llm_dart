import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

/// Fake LanguageModel implementation used for testing registry resolution.
class _FakeLanguageModel implements LanguageModel {
  @override
  final String providerId;

  @override
  final String modelId;

  @override
  final LLMConfig config;

  _FakeLanguageModel({
    required this.providerId,
    required this.modelId,
  }) : config = LLMConfig(
          baseUrl: 'https://example.com',
          model: modelId,
        );

  @override
  Future<GenerateTextResult> generateText(
    List<ChatMessage> messages, {
    CancellationToken? cancelToken,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<ChatStreamEvent> streamText(
    List<ChatMessage> messages, {
    CancellationToken? cancelToken,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<StreamTextPart> streamTextParts(
    List<ChatMessage> messages, {
    CancellationToken? cancelToken,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<GenerateObjectResult<T>> generateObject<T>(
    OutputSpec<T> output,
    List<ChatMessage> messages, {
    CancellationToken? cancelToken,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<GenerateTextResult> generateTextWithOptions(
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<ChatStreamEvent> streamTextWithOptions(
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<StreamTextPart> streamTextPartsWithOptions(
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<GenerateObjectResult<T>> generateObjectWithOptions<T>(
    OutputSpec<T> output,
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    throw UnimplementedError();
  }
}

/// Fake provider that can create language models.
class _FakeLanguageModelProvider implements LanguageModelProviderFactory {
  String? lastModelId;

  @override
  LanguageModel languageModel(String modelId) {
    lastModelId = modelId;
    return _FakeLanguageModel(
      providerId: 'fake',
      modelId: modelId,
    );
  }
}

/// Fake embedding capability used for testing.
class _FakeEmbeddingCapability implements EmbeddingCapability {
  @override
  Future<List<List<double>>> embed(
    List<String> input, {
    CancellationToken? cancelToken,
  }) async {
    return [
      List<double>.filled(3, 1.0),
    ];
  }
}

/// Fake provider that can create embedding models.
class _FakeEmbeddingProvider implements EmbeddingModelProviderFactory {
  String? lastModelId;

  @override
  EmbeddingCapability textEmbeddingModel(String modelId) {
    lastModelId = modelId;
    return _FakeEmbeddingCapability();
  }
}

/// Fake audio capability used for testing.
class _FakeAudioCapability implements AudioCapability {
  @override
  Set<AudioFeature> get supportedFeatures => const <AudioFeature>{};

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake provider that can create speech/transcription models.
class _FakeSpeechProvider implements SpeechModelProviderFactory {
  String? lastTranscriptionModelId;
  String? lastSpeechModelId;

  @override
  AudioCapability transcription(String modelId) {
    lastTranscriptionModelId = modelId;
    return _FakeAudioCapability();
  }

  @override
  AudioCapability speech(String modelId) {
    lastSpeechModelId = modelId;
    return _FakeAudioCapability();
  }
}

void main() {
  group('ProviderRegistryClient.languageModel', () {
    test('delegates to LanguageModelProviderFactory with correct model id', () {
      final fakeProvider = _FakeLanguageModelProvider();
      final registry = createProviderRegistry({
        'openai': fakeProvider,
      });

      final model = registry.languageModel('openai:gpt-4o');

      expect(fakeProvider.lastModelId, 'gpt-4o');
      expect(model, isA<_FakeLanguageModel>());
      final typed = model as _FakeLanguageModel;
      expect(typed.providerId, 'fake');
      expect(typed.modelId, 'gpt-4o');
    });

    test('throws InvalidRequestError on invalid id format', () {
      final fakeProvider = _FakeLanguageModelProvider();
      final registry = createProviderRegistry({
        'openai': fakeProvider,
      });

      expect(
        () => registry.languageModel('gpt-4o'),
        throwsA(isA<InvalidRequestError>()),
      );
    });

    test('throws InvalidRequestError when provider does not implement factory',
        () {
      final registry = createProviderRegistry({
        'dummy': Object(),
      });

      expect(
        () => registry.languageModel('dummy:model'),
        throwsA(isA<InvalidRequestError>()),
      );
    });
  });

  group('ProviderRegistryClient.textEmbeddingModel', () {
    test('delegates to EmbeddingModelProviderFactory with correct model id',
        () {
      final fakeProvider = _FakeEmbeddingProvider();
      final registry = createProviderRegistry({
        'emb': fakeProvider,
      });

      final embedding = registry.textEmbeddingModel('emb:text-embedding-1');

      expect(fakeProvider.lastModelId, 'text-embedding-1');
      expect(embedding, isA<EmbeddingCapability>());
      expect(
        embedding.embed(['test']),
        completion(isA<List<List<double>>>()),
      );
    });
  });

  group('ProviderRegistryClient speech models', () {
    test('delegates to SpeechModelProviderFactory for transcriptionModel', () {
      final fakeProvider = _FakeSpeechProvider();
      final registry = createProviderRegistry({
        'speech': fakeProvider,
      });

      final cap = registry.transcriptionModel('speech:whisper');

      expect(fakeProvider.lastTranscriptionModelId, 'whisper');
      expect(cap, isA<AudioCapability>());
    });

    test('delegates to SpeechModelProviderFactory for speechModel', () {
      final fakeProvider = _FakeSpeechProvider();
      final registry = createProviderRegistry({
        'speech': fakeProvider,
      });

      final cap = registry.speechModel('speech:tts');

      expect(fakeProvider.lastSpeechModelId, 'tts');
      expect(cap, isA<AudioCapability>());
    });
  });
}
