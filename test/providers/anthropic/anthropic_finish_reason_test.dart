import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Anthropic finishReason (typed)', () {
    test('maps pause_turn to unified.stop', () {
      final response = AnthropicChatResponse({
        'content': [
          {'type': 'text', 'text': 'ok'},
        ],
        'stop_reason': 'pause_turn',
      });

      final finish = (response as ChatResponseWithFinishReason).finishReason!;
      expect(finish.unified, equals(LLMUnifiedFinishReason.stop));
      expect(finish.raw, equals('pause_turn'));
    });

    test('maps end_turn to unified.stop', () {
      final response = AnthropicChatResponse({
        'content': [
          {'type': 'text', 'text': 'ok'},
        ],
        'stop_reason': 'end_turn',
      });

      expect(response, isA<ChatResponseWithFinishReason>());
      final finish = (response as ChatResponseWithFinishReason).finishReason!;
      expect(finish.unified, equals(LLMUnifiedFinishReason.stop));
      expect(finish.raw, equals('end_turn'));
    });

    test('maps stop_sequence to unified.stop', () {
      final response = AnthropicChatResponse({
        'content': [
          {'type': 'text', 'text': 'ok'},
        ],
        'stop_reason': 'stop_sequence',
      });

      final finish = (response as ChatResponseWithFinishReason).finishReason!;
      expect(finish.unified, equals(LLMUnifiedFinishReason.stop));
      expect(finish.raw, equals('stop_sequence'));
    });

    test('maps max_tokens to unified.length', () {
      final response = AnthropicChatResponse({
        'content': [
          {'type': 'text', 'text': 'ok'},
        ],
        'stop_reason': 'max_tokens',
      });

      final finish = (response as ChatResponseWithFinishReason).finishReason!;
      expect(finish.unified, equals(LLMUnifiedFinishReason.length));
      expect(finish.raw, equals('max_tokens'));
    });

    test('maps model_context_window_exceeded to unified.length', () {
      final response = AnthropicChatResponse({
        'content': [
          {'type': 'text', 'text': 'ok'},
        ],
        'stop_reason': 'model_context_window_exceeded',
      });

      final finish = (response as ChatResponseWithFinishReason).finishReason!;
      expect(finish.unified, equals(LLMUnifiedFinishReason.length));
      expect(finish.raw, equals('model_context_window_exceeded'));
    });

    test('maps refusal to unified.contentFilter', () {
      final response = AnthropicChatResponse({
        'content': [
          {'type': 'text', 'text': 'nope'},
        ],
        'stop_reason': 'refusal',
      });

      final finish = (response as ChatResponseWithFinishReason).finishReason!;
      expect(finish.unified, equals(LLMUnifiedFinishReason.contentFilter));
      expect(finish.raw, equals('refusal'));
    });

    test('maps tool_use to unified.toolCalls when local tool calls are present',
        () {
      final response = AnthropicChatResponse({
        'content': [
          {
            'type': 'tool_use',
            'id': 'tool_1',
            'name': 'get_weather',
            'input': {'location': 'SF'},
          },
        ],
        'stop_reason': 'tool_use',
      });

      final finish = (response as ChatResponseWithFinishReason).finishReason!;
      expect(finish.unified, equals(LLMUnifiedFinishReason.toolCalls));
      expect(finish.raw, equals('tool_use'));
    });

    test('does not map tool_use to unified.toolCalls for provider-native tools',
        () {
      final response = AnthropicChatResponse({
        'content': [
          {
            'type': 'tool_use',
            'id': 'tool_1',
            'name': 'web_search',
            'input': {'query': 'hi'},
          },
        ],
        'stop_reason': 'tool_use',
      });

      expect(response.toolCalls, isNull);
      expect(response, isA<ChatResponseWithWarnings>());
      final warnings = (response as ChatResponseWithWarnings).warnings;
      expect(
        warnings.any(
          (w) =>
              w is LLMCompatibilityWarning &&
              w.feature == 'provider-native tool_use not surfaced',
        ),
        isTrue,
      );
      final finish = (response as ChatResponseWithFinishReason).finishReason!;
      expect(finish.unified, equals(LLMUnifiedFinishReason.other));
      expect(finish.raw, equals('tool_use'));
    });
  });
}
