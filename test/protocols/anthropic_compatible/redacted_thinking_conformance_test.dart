import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

import '_fake_anthropic_compatible_json_client.dart';

void main() {
  group('Anthropic-compatible redacted thinking conformance', () {
    test('surfaces redacted thinking placeholder and preserves block',
        () async {
      const config = AnthropicConfig(
        apiKey: 'k',
        model: 'test-model',
        providerId: 'anthropic',
      );

      final client = FakeAnthropicCompatibleJsonClient(
        config,
        responses: [
          {
            'id': 'msg_redacted',
            'model': 'test-model',
            'stop_reason': 'end_turn',
            'usage': {
              'input_tokens': 1,
              'output_tokens': 1,
            },
            'content': [
              {
                'type': 'redacted_thinking',
                'data': 'ciphertext',
              },
              {
                'type': 'text',
                'text': 'Hello',
              },
            ],
          },
          {
            'id': 'msg_next',
            'model': 'test-model',
            'stop_reason': 'end_turn',
            'usage': {
              'input_tokens': 1,
              'output_tokens': 1,
            },
            'content': [
              {
                'type': 'text',
                'text': 'OK',
              },
            ],
          },
        ],
      );

      final chat = AnthropicChat(client, config);
      final first =
          await chat.chatWithTools([ChatMessage.user('Hi')], const []);

      expect(first.text, equals('Hello'));
      expect(
        first.thinking,
        contains('[Redacted thinking content - encrypted for safety]'),
      );

      expect(first, isA<ChatResponseWithAssistantMessage>());
      final assistantMessage =
          (first as ChatResponseWithAssistantMessage).assistantMessage;

      await chat.chatWithTools(
        [
          ChatMessage.user('Hi'),
          assistantMessage,
        ],
        const [],
      );

      expect(client.requests, hasLength(2));
      final secondRequest = client.requests[1];
      final messages = secondRequest['messages'] as List<dynamic>;
      expect(messages, hasLength(2));

      final assistant = messages[1] as Map<String, dynamic>;
      final content = assistant['content'] as List<dynamic>;
      expect(
        content.whereType<Map>().any((b) => b['type'] == 'redacted_thinking'),
        isTrue,
      );
    });
  });
}
