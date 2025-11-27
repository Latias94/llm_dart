import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart' as anthropic_pkg;
import 'package:test/test.dart';

void main() {
  group('Anthropic thinking mode parameter handling', () {
    test('enables thinking and strips sampling params for reasoning models',
        () {
      final config = anthropic_pkg.AnthropicConfig(
        apiKey: 'test-key',
        model: 'claude-sonnet-4-20250514', // supportsReasoning == true
        maxTokens: 256,
        temperature: 0.7,
        topP: 0.9,
        topK: 20,
        reasoning: true,
        thinkingBudgetTokens: 2048,
      );

      final builder = anthropic_pkg.AnthropicRequestBuilder(config);

      final body = builder.buildRequestBody(
        [ChatMessage.user('Hello')],
        null,
        false,
      );

      expect(body['model'], equals('claude-sonnet-4-20250514'));
      // max_tokens should be baseMaxTokens + thinkingBudget (256 + 2048).
      expect(body['max_tokens'], equals(2304));

      // When thinking is enabled for a reasoning-capable model:
      // - sampling params are not sent
      // - thinking config is attached.
      expect(body.containsKey('temperature'), isFalse);
      expect(body.containsKey('top_p'), isFalse);
      expect(body.containsKey('top_k'), isFalse);

      final thinking = body['thinking'] as Map<String, dynamic>?;
      expect(thinking, isNotNull);
      expect(thinking!['type'], equals('enabled'));
      expect(thinking['budget_tokens'], equals(2048));
    });

    test(
        'keeps sampling params and omits thinking for non-reasoning models even when reasoning=true',
        () {
      final config = anthropic_pkg.AnthropicConfig(
        apiKey: 'test-key',
        model: 'claude-3-haiku-20240307', // supportsReasoning == false
        maxTokens: 128,
        temperature: 0.3,
        topP: 0.8,
        topK: 10,
        reasoning: true,
        thinkingBudgetTokens: 4096,
      );

      final builder = anthropic_pkg.AnthropicRequestBuilder(config);

      final body = builder.buildRequestBody(
        [ChatMessage.user('Hello')],
        null,
        false,
      );

      // For non-reasoning models, reasoning flag should not enable thinking
      // or strip sampling parameters.
      expect(body['temperature'], equals(0.3));
      expect(body['top_p'], equals(0.8));
      expect(body['top_k'], equals(10));
      expect(body.containsKey('thinking'), isFalse);
    });
  });
}
