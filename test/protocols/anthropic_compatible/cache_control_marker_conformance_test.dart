import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_core/models/tool_models.dart';
import 'package:test/test.dart';

Tool _noopTool(String name) {
  return Tool.function(
    name: name,
    description: 'noop',
    parameters: const ParametersSchema(
      schemaType: 'object',
      properties: {
        'q': ParameterProperty(
          propertyType: 'string',
          description: 'q',
        ),
      },
      required: ['q'],
    ),
  );
}

void main() {
  group('Anthropic-compatible cache_control marker conformance', () {
    test('applies per-message cache_control marker and omits marker block', () {
      const config = AnthropicConfig(
        apiKey: 'k',
        model: 'test-model',
        providerId: 'anthropic',
        cacheControl: {'type': 'ephemeral'},
      );
      final builder = AnthropicRequestBuilder(config);

      final message = ChatMessage(
        role: ChatRole.user,
        messageType: const TextMessage(),
        content: '',
        protocolPayloads: {
          'anthropic': {
            'contentBlocks': [
              {
                'type': 'text',
                'text': '',
                'cache_control': {'type': 'ephemeral', 'ttl': '1h'},
              },
              {
                'type': 'text',
                'text': 'Hello',
              },
            ],
          },
        },
      );

      final body = builder.buildRequestBody([message], const [], false);
      final messages = body['messages'] as List<dynamic>;
      expect(messages, hasLength(1));

      final content =
          (messages.single as Map<String, dynamic>)['content'] as List<dynamic>;

      // Marker block is not included in outgoing content.
      expect(
        content.whereType<Map>().any(
              (b) =>
                  b['text'] == '' &&
                  b['cache_control'] != null &&
                  b['type'] == 'text',
            ),
        isFalse,
      );

      final textBlock = content
          .whereType<Map>()
          .cast<Map<String, dynamic>>()
          .firstWhere((b) => b['type'] == 'text');
      expect(textBlock['text'], equals('Hello'));
      expect(textBlock['cache_control'],
          equals({'type': 'ephemeral', 'ttl': '1h'}));
    });

    test('applies tool cache_control marker to last tool', () {
      const config = AnthropicConfig(
        apiKey: 'k',
        model: 'test-model',
        providerId: 'anthropic',
      );
      final builder = AnthropicRequestBuilder(config);

      final toolsMessage = ChatMessage(
        role: ChatRole.system,
        messageType: const TextMessage(),
        content: '',
        protocolPayloads: {
          'anthropic': {
            'contentBlocks': [
              {
                'type': 'text',
                'text': '',
                'cache_control': {'type': 'ephemeral', 'ttl': '1h'},
              },
              {
                'type': 'tools',
                'tools': [
                  _noopTool('t1').toJson(),
                  _noopTool('t2').toJson(),
                ],
              },
            ],
          },
        },
      );

      final body = builder.buildRequestBody(
        [
          toolsMessage,
          ChatMessage.user('hi'),
        ],
        null,
        false,
      );

      final tools = body['tools'] as List<dynamic>;
      expect(tools, hasLength(2));
      expect((tools.first as Map).containsKey('cache_control'), isFalse);
      expect(
        (tools.last as Map)['cache_control'],
        equals({'type': 'ephemeral', 'ttl': '1h'}),
      );
    });
  });
}
