import 'dart:typed_data';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

class _CapturingSttModel implements SpeechToTextCapability {
  STTRequest? lastRequest;

  @override
  Future<STTResponse> speechToText(
    STTRequest request, {
    CancelToken? cancelToken,
  }) async {
    lastRequest = request;
    return const STTResponse(text: 'ok');
  }
}

void main() {
  group('transcribe download (AI SDK parity)', () {
    test('throws InvalidRequestError for invalid audioUrl', () async {
      final model = _CapturingSttModel();

      expect(
        () => transcribe(
          model: model,
          request: const STTRequest(audioUrl: 'not-a-url'),
          download: ({
            required Uri url,
            CancelToken? cancelToken,
          }) async {
            throw StateError('download should not be called');
          },
        ),
        throwsA(isA<InvalidRequestError>()),
      );
    });

    test('downloads audioUrl and forwards as audioData', () async {
      final model = _CapturingSttModel();

      final result = await transcribe(
        model: model,
        request: const STTRequest(
          audioUrl: 'https://example.com/audio.mp3',
        ),
        download: ({
          required Uri url,
          CancelToken? cancelToken,
        }) async {
          expect(url.toString(), equals('https://example.com/audio.mp3'));
          return DownloadResult(
            data: Uint8List.fromList([1, 2, 3]),
            mediaType: 'audio/mpeg',
          );
        },
      );

      expect(result.text, equals('ok'));
      expect(model.lastRequest, isNotNull);
      expect(model.lastRequest!.audioData, equals(const [1, 2, 3]));
      expect(model.lastRequest!.audioUrl, isNull);
      expect(model.lastRequest!.filePath, isNull);
      expect(model.lastRequest!.cloudStorageUrl, isNull);
      expect(model.lastRequest!.format, equals('mp3'));
    });

    test('ignores audioUrl when audioData is already provided', () async {
      final model = _CapturingSttModel();

      final result = await transcribe(
        model: model,
        request: const STTRequest(
          audioData: <int>[9],
          audioUrl: 'https://example.com/should-not-download.mp3',
        ),
        download: ({
          required Uri url,
          CancelToken? cancelToken,
        }) async {
          throw StateError('download should not be called');
        },
      );

      expect(result.text, equals('ok'));
      expect(model.lastRequest, isNotNull);
      expect(model.lastRequest!.audioData, equals(const [9]));
      expect(model.lastRequest!.audioUrl, isNull);
    });

    test('passes cancelToken to download function', () async {
      final model = _CapturingSttModel();
      final token = CancelToken();

      token.cancel('stop');

      expect(
        () => transcribe(
          model: model,
          request: const STTRequest(
            audioUrl: 'https://example.com/audio.mp3',
          ),
          cancelToken: token,
          download: ({
            required Uri url,
            CancelToken? cancelToken,
          }) async {
            expect(cancelToken, same(token));
            if (cancelToken?.isCancelled == true) {
              throw CancelledError(
                cancelToken?.reason?.toString() ?? 'Cancelled',
              );
            }
            return DownloadResult(data: Uint8List(0));
          },
        ),
        throwsA(isA<CancelledError>()),
      );
    });
  });
}
