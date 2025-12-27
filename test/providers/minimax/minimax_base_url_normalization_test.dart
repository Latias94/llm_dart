import 'package:test/test.dart';

import 'package:llm_dart_minimax/llm_dart_minimax.dart';

void main() {
  group('MiniMax baseUrl normalization', () {
    test('normalizeMinimaxAnthropicBaseUrl appends /v1/ for /anthropic', () {
      expect(
        normalizeMinimaxAnthropicBaseUrl(minimaxAnthropicBaseUrl),
        equals(minimaxAnthropicV1BaseUrl),
      );
      expect(
        normalizeMinimaxAnthropicBaseUrl('https://api.minimax.io/anthropic'),
        equals(minimaxAnthropicV1BaseUrl),
      );
    });

    test('normalizeMinimaxAnthropicBaseUrl appends / for /anthropic/v1', () {
      expect(
        normalizeMinimaxAnthropicBaseUrl(minimaxAnthropicV1BaseUrl),
        equals(minimaxAnthropicV1BaseUrl),
      );
      expect(
        normalizeMinimaxAnthropicBaseUrl('https://api.minimax.io/anthropic/v1'),
        equals(minimaxAnthropicV1BaseUrl),
      );
    });

    test('createMinimaxProvider normalizes baseUrl (international + CN)', () {
      final international = createMinimaxProvider(
        apiKey: 'test-key',
        baseUrl: minimaxAnthropicBaseUrl,
        model: minimaxDefaultModel,
      );
      expect(international.config.baseUrl, equals(minimaxAnthropicV1BaseUrl));

      final china = createMinimaxProvider(
        apiKey: 'test-key',
        baseUrl: minimaxiAnthropicBaseUrl,
        model: minimaxDefaultModel,
      );
      expect(china.config.baseUrl, equals(minimaxiAnthropicV1BaseUrl));
    });
  });
}
