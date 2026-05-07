import 'dart:convert';

import 'package:llm_dart/providers/google/tts.dart';
import 'package:test/test.dart';

void main() {
  group('GoogleTTSStreamSupport', () {
    test('parses audio and completion events from a finished chunk', () {
      final support = GoogleTTSStreamSupport();
      final events = support.parseChunk({
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'inlineData': {
                    'data': base64Encode([1, 2, 3]),
                    'mimeType': 'audio/pcm',
                  },
                },
              ],
            },
            'finishReason': 'STOP',
          },
        ],
        'usageMetadata': {
          'promptTokenCount': 4,
          'candidatesTokenCount': 2,
          'totalTokenCount': 6,
        },
        'modelVersion': 'gemini-2.5-flash-preview-tts',
      });

      final audioEvent = events.whereType<GoogleTTSAudioDataEvent>().single;
      expect(audioEvent.data, [1, 2, 3]);

      final completionEvent =
          events.whereType<GoogleTTSCompletionEvent>().single;
      expect(completionEvent.response.contentType, 'audio/pcm');
      expect(
        completionEvent.response.model,
        'gemini-2.5-flash-preview-tts',
      );
      expect(completionEvent.response.usage?.promptTokens, 4);
      expect(completionEvent.response.usage?.completionTokens, 2);
      expect(completionEvent.response.usage?.totalTokens, 6);
    });

    test('returns an error event for malformed audio chunks', () {
      final support = GoogleTTSStreamSupport();
      final events = support.parseChunk({
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'inlineData': {
                    'data': 'not-base64',
                    'mimeType': 'audio/pcm',
                  },
                },
              ],
            },
            'finishReason': 'STOP',
          },
        ],
      });

      expect(events, hasLength(1));
      expect(events.single, isA<GoogleTTSErrorEvent>());
    });
  });
}
