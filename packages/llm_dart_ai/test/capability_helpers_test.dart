import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:test/test.dart';

void main() {
  group('embed', () {
    test('wraps a single embedding result', () async {
      final model = _RecordingEmbeddingModel(
        result: EmbedResult(
          embeddings: const [
            [0.1, 0.2, 0.3],
          ],
          usage: const UsageStats(
            inputTokens: 3,
            totalTokens: 3,
          ),
        ),
      );

      final result = await embed(
        model: model,
        value: 'hello',
        dimensions: 256,
        callOptions: const CallOptions(
          timeout: Duration(seconds: 3),
        ),
      );

      expect(result.value, 'hello');
      expect(result.embedding, [0.1, 0.2, 0.3]);
      expect(result.usage, const UsageStats(inputTokens: 3, totalTokens: 3));
      expect(model.lastRequest?.values, ['hello']);
      expect(model.lastRequest?.dimensions, 256);
      expect(
        model.lastRequest?.callOptions.timeout,
        const Duration(seconds: 3),
      );
    });

    test('rejects model results with the wrong single-value count', () async {
      final model = _RecordingEmbeddingModel(
        result: EmbedResult(
          embeddings: const [
            [0.1, 0.2],
            [0.3, 0.4],
          ],
        ),
      );

      await expectLater(
        () => embed(
          model: model,
          value: 'hello',
        ),
        throwsStateError,
      );
    });
  });

  group('embedMany', () {
    test('delegates a batched embedding request', () async {
      final model = _RecordingEmbeddingModel(
        result: EmbedResult(
          embeddings: const [
            [0.1, 0.2],
            [0.3, 0.4],
          ],
        ),
      );

      final result = await embedMany(
        model: model,
        values: const ['a', 'b'],
      );

      expect(result.embeddings, [
        [0.1, 0.2],
        [0.3, 0.4],
      ]);
      expect(model.lastRequest?.values, ['a', 'b']);
    });

    test('rejects empty batched embedding requests', () async {
      final model = _RecordingEmbeddingModel(
        result: EmbedResult(
          embeddings: const [],
        ),
      );

      await expectLater(
        () => embedMany(
          model: model,
          values: const [],
        ),
        throwsArgumentError,
      );
    });

    test('rejects model results with the wrong batch count', () async {
      final model = _RecordingEmbeddingModel(
        result: EmbedResult(
          embeddings: const [
            [0.1, 0.2],
          ],
        ),
      );

      await expectLater(
        () => embedMany(
          model: model,
          values: const ['a', 'b'],
        ),
        throwsStateError,
      );
    });
  });

  group('generateImage', () {
    test('builds a shared image request from helper arguments', () async {
      final model = _RecordingImageModel(
        result: ImageGenerationResult(
          images: const [
            GeneratedImage(
              bytes: [1, 2, 3],
              mediaType: 'image/png',
            ),
          ],
        ),
      );

      final result = await generateImage(
        model: model,
        prompt: 'Draw a cat.',
        count: 2,
        size: '1024x1024',
      );

      expect(result.images, hasLength(1));
      expect(model.lastRequest?.prompt, 'Draw a cat.');
      expect(model.lastRequest?.count, 2);
      expect(model.lastRequest?.size, '1024x1024');
    });

    test('rejects non-positive image counts', () async {
      final model = _RecordingImageModel(
        result: ImageGenerationResult(images: const []),
      );

      await expectLater(
        () => generateImage(
          model: model,
          prompt: 'Draw a cat.',
          count: 0,
        ),
        throwsArgumentError,
      );
    });
  });

  group('generateSpeech', () {
    test('builds a shared speech request from helper arguments', () async {
      final model = _RecordingSpeechModel(
        result: const SpeechGenerationResult(
          audioBytes: [1, 2, 3],
          mediaType: 'audio/mp3',
        ),
      );

      final result = await generateSpeech(
        model: model,
        text: 'Hello world.',
        voice: 'alloy',
      );

      expect(result.audioBytes, [1, 2, 3]);
      expect(model.lastRequest?.text, 'Hello world.');
      expect(model.lastRequest?.voice, 'alloy');
    });
  });

  group('transcribe', () {
    test('builds a shared transcription request from helper arguments',
        () async {
      final model = _RecordingTranscriptionModel(
        result: const TranscriptionResult(
          text: 'hello world',
        ),
      );

      final result = await transcribe(
        model: model,
        audioBytes: const [1, 2, 3],
        mediaType: 'audio/wav',
      );

      expect(result.text, 'hello world');
      expect(model.lastRequest?.audioBytes, [1, 2, 3]);
      expect(model.lastRequest?.mediaType, 'audio/wav');
    });

    test('rejects empty audio bytes', () async {
      final model = _RecordingTranscriptionModel(
        result: const TranscriptionResult(text: 'unused'),
      );

      await expectLater(
        () => transcribe(
          model: model,
          audioBytes: const [],
        ),
        throwsArgumentError,
      );
    });
  });
}

final class _RecordingEmbeddingModel implements EmbeddingModel {
  final EmbedResult result;
  EmbedRequest? lastRequest;

  _RecordingEmbeddingModel({
    required this.result,
  });

  @override
  String get modelId => 'embed-test-model';

  @override
  String get providerId => 'test';

  @override
  Future<EmbedResult> doEmbed(EmbedRequest request) async {
    lastRequest = request;
    return result;
  }
}

final class _RecordingImageModel implements ImageModel {
  final ImageGenerationResult result;
  ImageGenerationRequest? lastRequest;

  _RecordingImageModel({
    required this.result,
  });

  @override
  String get modelId => 'image-test-model';

  @override
  String get providerId => 'test';

  @override
  Future<ImageGenerationResult> doGenerate(
    ImageGenerationRequest request,
  ) async {
    lastRequest = request;
    return result;
  }
}

final class _RecordingSpeechModel implements SpeechModel {
  final SpeechGenerationResult result;
  SpeechGenerationRequest? lastRequest;

  _RecordingSpeechModel({
    required this.result,
  });

  @override
  String get modelId => 'speech-test-model';

  @override
  String get providerId => 'test';

  @override
  Future<SpeechGenerationResult> doGenerate(
    SpeechGenerationRequest request,
  ) async {
    lastRequest = request;
    return result;
  }
}

final class _RecordingTranscriptionModel implements TranscriptionModel {
  final TranscriptionResult result;
  TranscriptionRequest? lastRequest;

  _RecordingTranscriptionModel({
    required this.result,
  });

  @override
  String get modelId => 'transcription-test-model';

  @override
  String get providerId => 'test';

  @override
  Future<TranscriptionResult> doGenerate(TranscriptionRequest request) async {
    lastRequest = request;
    return result;
  }
}
