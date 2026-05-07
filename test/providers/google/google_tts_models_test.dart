import 'package:llm_dart/src/compatibility/providers/google/google_tts_models.dart';
import 'package:test/test.dart';

void main() {
  group('Google TTS models', () {
    test('serialize and deserialize request and response models', () {
      final request = GoogleTTSRequest.singleSpeaker(
        text: 'Hello, world!',
        voiceName: 'Kore',
        model: 'gemini-2.5-flash-preview-tts',
      );

      final requestJson = request.toJson();
      expect(requestJson['model'], equals('gemini-2.5-flash-preview-tts'));
      expect(requestJson['contents'], isA<List>());

      final response = GoogleTTSResponse.fromApiResponse({
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'inlineData': {
                    'data': 'SGVsbG8=',
                    'mimeType': 'audio/pcm',
                  },
                },
              ],
            },
          },
        ],
        'modelVersion': 'gemini-2.5-flash-preview-tts',
      });

      expect(response.audioData, isNotEmpty);
      expect(response.contentType, equals('audio/pcm'));
      expect(response.model, equals('gemini-2.5-flash-preview-tts'));
    });
  });
}
