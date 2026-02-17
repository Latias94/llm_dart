import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_ollama/ollama.dart';
import 'package:test/test.dart';

void main() {
  group('OllamaChatResponse warnings', () {
    test('emits compatibility warning when tool call ids are synthetic', () {
      final response = OllamaChatResponse({
        'message': {
          'role': 'assistant',
          'tool_calls': [
            {
              'function': {
                'name': 'getWeather',
                'arguments': {'city': 'London'},
              },
            },
          ],
        },
      });

      expect(response, isA<ChatResponseWithWarnings>());
      final warnings = (response as ChatResponseWithWarnings).warnings;
      expect(warnings, hasLength(1));
      expect(warnings.single, isA<LLMCompatibilityWarning>());
      expect(
        (warnings.single as LLMCompatibilityWarning).feature,
        equals('synthetic tool call ids'),
      );
    });

    test('does not emit warnings when no tool calls exist', () {
      final response = OllamaChatResponse({
        'message': {
          'role': 'assistant',
          'content': 'ok',
        },
      });

      expect(response, isA<ChatResponseWithWarnings>());
      expect(
        (response as ChatResponseWithWarnings).warnings,
        isEmpty,
      );
    });
  });
}
