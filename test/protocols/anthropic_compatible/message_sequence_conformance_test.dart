import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('Anthropic-compatible message sequence conformance', () {
    test('rejects non-user first non-system message', () {
      const config = AnthropicConfig(
        apiKey: 'k',
        model: 'test-model',
        providerId: 'anthropic',
      );
      final builder = AnthropicRequestBuilder(config);

      expect(
        () => builder.buildRequestBody(
          [
            ChatMessage.assistant('hi'),
          ],
          const [],
          false,
        ),
        throwsA(isA<InvalidRequestError>()),
      );
    });
  });
}
