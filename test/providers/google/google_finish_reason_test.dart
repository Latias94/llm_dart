import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Google finishReason (typed)', () {
    test('maps STOP to unified.stop when no tool calls', () {
      final response = GoogleChatResponse({
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': 'Hello'},
              ],
            },
            'finishReason': 'STOP',
          },
        ],
      });

      expect(response, isA<ChatResponseWithFinishReason>());
      final finish = (response as ChatResponseWithFinishReason).finishReason!;
      expect(finish.unified, equals(LLMUnifiedFinishReason.stop));
      expect(finish.raw, equals('STOP'));
    });

    test('prefers unified.toolCalls when function tool calls are present', () {
      final response = GoogleChatResponse({
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'functionCall': {
                    'name': 'get_weather',
                    'args': {'location': 'London'},
                  },
                },
              ],
            },
            'finishReason': 'STOP',
          },
        ],
      });

      final finish = (response as ChatResponseWithFinishReason).finishReason!;
      expect(finish.unified, equals(LLMUnifiedFinishReason.toolCalls));
      expect(finish.raw, equals('STOP'));
    });

    test('maps MAX_TOKENS to unified.length', () {
      final response = GoogleChatResponse({
        'candidates': [
          {
            'content': {'parts': []},
            'finishReason': 'MAX_TOKENS',
          },
        ],
      });

      final finish = (response as ChatResponseWithFinishReason).finishReason!;
      expect(finish.unified, equals(LLMUnifiedFinishReason.length));
      expect(finish.raw, equals('MAX_TOKENS'));
    });

    test(
        'does not override MAX_TOKENS to toolCalls when tool calls are present',
        () {
      final response = GoogleChatResponse({
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'functionCall': {
                    'name': 'get_weather',
                    'args': {'location': 'London'},
                  },
                },
              ],
            },
            'finishReason': 'MAX_TOKENS',
          },
        ],
      });

      final finish = (response as ChatResponseWithFinishReason).finishReason!;
      expect(finish.unified, equals(LLMUnifiedFinishReason.length));
      expect(finish.raw, equals('MAX_TOKENS'));
    });

    test('maps SAFETY to unified.contentFilter', () {
      final response = GoogleChatResponse({
        'candidates': [
          {
            'content': {'parts': []},
            'finishReason': 'SAFETY',
          },
        ],
      });

      final finish = (response as ChatResponseWithFinishReason).finishReason!;
      expect(finish.unified, equals(LLMUnifiedFinishReason.contentFilter));
      expect(finish.raw, equals('SAFETY'));
    });
  });
}
