import 'dart:typed_data';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

class _FakeVideoModel implements ExperimentalVideoGenerationCapability {
  int calls = 0;
  final List<int> ns = [];

  @override
  Future<ExperimentalVideoGenerationResponse> generateVideos(
    ExperimentalVideoGenerationRequest request, {
    CancelToken? cancelToken,
  }) async {
    calls++;
    ns.add(request.n);
    return ExperimentalVideoGenerationResponse(
      videos: [
        ExperimentalGeneratedVideoUrl(
          url: Uri.parse('https://example.com/video.mp4'),
          mediaType: 'video/mp4',
        ),
      ],
      responses: [
        ExperimentalVideoResponseMetadata(
          timestamp: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          modelId: 'test-model',
          headers: const {'x-test': '1'},
        ),
      ],
      providerMetadata: const {
        'test': {'ok': true}
      },
    );
  }
}

class _FakeVideoModelWithCallOptions extends _FakeVideoModel
    implements ExperimentalVideoGenerationCallOptionsCapability {
  LLMCallOptions? lastCallOptions;

  @override
  Future<ExperimentalVideoGenerationResponse> generateVideosWithCallOptions(
    ExperimentalVideoGenerationRequest request, {
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) async {
    lastCallOptions = callOptions;
    return super.generateVideos(request, cancelToken: cancelToken);
  }
}

void main() {
  group('experimentalGenerateVideo', () {
    test('uses base capability when callOptions empty', () async {
      final model = _FakeVideoModel();
      final result = await experimentalGenerateVideo(
        model: model,
        request: const ExperimentalVideoGenerationRequest(prompt: 'hi'),
        download: ({
          required Uri url,
          CancelToken? cancelToken,
        }) async =>
            DownloadResult(
          data: Uint8List.fromList([1, 2, 3]),
          mediaType: 'video/mp4',
        ),
      );

      expect(model.calls, equals(1));
      expect(result.video, isA<ExperimentalGeneratedVideoBinary>());
      expect(result.video.mediaType, equals('video/mp4'));
      expect(result.responses.single.modelId, equals('test-model'));
      expect(result.providerMetadata?['test'], isNotNull);
    });

    test('throws when callOptions provided but not supported', () async {
      final model = _FakeVideoModel();

      expect(
        () => experimentalGenerateVideo(
          model: model,
          request: const ExperimentalVideoGenerationRequest(prompt: 'hi'),
          download: ({
            required Uri url,
            CancelToken? cancelToken,
          }) async =>
              DownloadResult(
            data: Uint8List.fromList([1, 2, 3]),
            mediaType: 'video/mp4',
          ),
          callOptions: const LLMCallOptions(headers: {'x': 'y'}),
        ),
        throwsA(isA<InvalidRequestError>()),
      );
    });

    test('uses call-options capability when callOptions provided', () async {
      final model = _FakeVideoModelWithCallOptions();
      await experimentalGenerateVideo(
        model: model,
        request: const ExperimentalVideoGenerationRequest(prompt: 'hi'),
        download: ({
          required Uri url,
          CancelToken? cancelToken,
        }) async =>
            DownloadResult(
          data: Uint8List.fromList([1, 2, 3]),
          mediaType: 'video/mp4',
        ),
        callOptions: const LLMCallOptions(headers: {'x': 'y'}),
      );

      expect(model.calls, equals(1));
      expect(model.lastCallOptions?.headers?['x'], equals('y'));
    });

    test('splits calls when n exceeds maxVideosPerCall (experimental)',
        () async {
      final model = _FakeVideoModelMaxPerCall();
      final result = await experimentalGenerateVideo(
        model: model,
        request: const ExperimentalVideoGenerationRequest(prompt: 'hi', n: 10),
        download: ({
          required Uri url,
          CancelToken? cancelToken,
        }) async =>
            DownloadResult(
          data: Uint8List.fromList([1, 2, 3]),
          mediaType: 'video/mp4',
        ),
      );

      expect(model.ns, equals([4, 4, 2]));
      expect(result.videos, hasLength(3));
      expect(result.responses, hasLength(3));
    });
  });
}

class _FakeVideoModelMaxPerCall extends _FakeVideoModel
    implements ExperimentalVideoGenerationMaxVideosPerCallCapability {
  @override
  int get maxVideosPerCall => 4;
}
