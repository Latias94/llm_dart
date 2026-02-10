import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('Anthropic-compatible Prompt IR compilation conformance', () {
    test('applies message cacheControl to last part only', () {
      const config = AnthropicConfig(
        apiKey: 'k',
        model: 'test-model',
        providerId: 'anthropic',
      );
      final builder = AnthropicRequestBuilder(config);

      final prompt = Prompt(
        messages: [
          PromptMessage(
            role: ChatRole.user,
            parts: const [
              TextPart('part1'),
              TextPart('part2'),
            ],
            providerOptions: const {
              'anthropic': {
                'cacheControl': {'type': 'ephemeral', 'ttl': '1h'},
              },
            },
          ),
        ],
      );

      final built = builder.buildRequestFromPrompt(prompt, const [], false);
      final messages = built.body['messages'] as List<dynamic>;
      expect(messages, hasLength(1));

      final message = messages.single as Map<String, dynamic>;
      final content = message['content'] as List<dynamic>;
      expect(content, hasLength(2));

      expect((content.first as Map).containsKey('cache_control'), isFalse);
      expect(
        (content.last as Map)['cache_control'],
        equals({'type': 'ephemeral', 'ttl': '1h'}),
      );
    });

    test(
        'splits ToolCallPart/ToolResultPart by overrideRole (order-preserving)',
        () {
      const config = AnthropicConfig(
        apiKey: 'k',
        model: 'test-model',
        providerId: 'anthropic',
      );
      final builder = AnthropicRequestBuilder(config);

      final toolCall = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: const FunctionCall(
          name: 'get_weather',
          arguments: '{"city":"Tokyo"}',
        ),
      );
      final toolResult = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: const FunctionCall(
          name: 'get_weather',
          arguments: '11 degrees celsius',
        ),
      );

      final prompt = Prompt(
        messages: [
          PromptMessage(
            role: ChatRole.user,
            parts: [
              const TextPart('Before'),
              ToolCallPart(toolCall, overrideRole: ChatRole.assistant),
              ToolResultPart(toolResult, overrideRole: ChatRole.user),
              const TextPart('After'),
            ],
          ),
        ],
      );

      final built = builder.buildRequestFromPrompt(prompt, const [], false);
      final messages = built.body['messages'] as List<dynamic>;
      expect(messages, hasLength(3));

      expect(
        messages[0],
        equals({
          'role': 'user',
          'content': [
            {'type': 'text', 'text': 'Before'},
          ],
        }),
      );

      final assistant = messages[1] as Map<String, dynamic>;
      expect(assistant['role'], equals('assistant'));
      final assistantContent = assistant['content'] as List<dynamic>;
      expect(assistantContent, hasLength(1));
      final toolUse = assistantContent.single as Map<String, dynamic>;
      expect(toolUse['type'], equals('tool_use'));
      expect(toolUse['id'], equals('call_1'));
      expect(toolUse['name'], equals('get_weather'));
      expect(toolUse['input'], equals({'city': 'Tokyo'}));

      expect(
        messages[2],
        equals({
          'role': 'user',
          'content': [
            {
              'type': 'tool_result',
              'tool_use_id': 'call_1',
              'content': '11 degrees celsius',
              'is_error': false,
            },
            {'type': 'text', 'text': 'After'},
          ],
        }),
      );
    });

    test('compiles FileUrlPart to document(url) blocks', () {
      const config = AnthropicConfig(
        apiKey: 'k',
        model: 'test-model',
        providerId: 'anthropic',
      );
      final builder = AnthropicRequestBuilder(config);

      final prompt = Prompt(
        messages: [
          const PromptMessage(
            role: ChatRole.user,
            parts: [
              FileUrlPart(
                mime: FileMime.pdf,
                url: ' https://example.com/a.pdf ',
                providerOptions: {
                  'anthropic': {'title': 'Doc title'},
                },
              ),
            ],
          ),
        ],
      );

      final built = builder.buildRequestFromPrompt(prompt, const [], false);
      final messages = built.body['messages'] as List<dynamic>;
      expect(messages, hasLength(1));

      expect(
        messages.single,
        equals({
          'role': 'user',
          'content': [
            {
              'type': 'document',
              'source': {
                'type': 'url',
                'url': 'https://example.com/a.pdf',
              },
              'title': 'Doc title',
            },
          ],
        }),
      );
    });
  });
}
