import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('Anthropic prompt caching (Prompt IR precedence)', () {
    const defaultCache = {'type': 'ephemeral', 'ttl': '1h'};
    const messageCache = {'type': 'ephemeral', 'ttl': '5m'};
    const partCache = {'type': 'ephemeral', 'ttl': '1m'};
    const toolCallCache = {'type': 'ephemeral', 'ttl': '10m'};

    AnthropicRequestBuilder builderWithDefaultCache() {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'claude-sonnet-4-20250514',
        providerOptions: const {
          'anthropic': {
            'cacheControl': defaultCache,
          },
        },
      );
      final anthropicConfig = AnthropicConfig.fromLLMConfig(llmConfig);
      return AnthropicRequestBuilder(anthropicConfig);
    }

    test('config-level cacheControl applies to last PromptMessage part', () {
      final builder = builderWithDefaultCache();

      final prompt = Prompt(messages: [
        PromptMessage(
          role: ChatRole.user,
          parts: const [
            TextPart('A'),
            TextPart('B'),
          ],
        ),
      ]);

      final body = builder.buildRequestBodyFromPrompt(prompt, null, false);
      final messages = body['messages'] as List<dynamic>;
      final content = messages.single['content'] as List<dynamic>;

      expect(content[0]['cache_control'], isNull);
      expect(content[1]['cache_control'], equals(defaultCache));
    });

    test('PromptMessage providerOptions overrides config default (last part)',
        () {
      final builder = builderWithDefaultCache();

      final prompt = Prompt(messages: [
        PromptMessage(
          role: ChatRole.user,
          providerOptions: const {
            'anthropic': {'cacheControl': messageCache},
          },
          parts: const [
            TextPart('A'),
            TextPart('B'),
          ],
        ),
      ]);

      final body = builder.buildRequestBodyFromPrompt(prompt, null, false);
      final messages = body['messages'] as List<dynamic>;
      final content = messages.single['content'] as List<dynamic>;

      expect(content[0]['cache_control'], isNull);
      expect(content[1]['cache_control'], equals(messageCache));
    });

    test('part providerOptions overrides message providerOptions', () {
      final builder = builderWithDefaultCache();

      final prompt = Prompt(messages: [
        PromptMessage(
          role: ChatRole.user,
          providerOptions: const {
            'anthropic': {'cacheControl': messageCache},
          },
          parts: const [
            TextPart(
              'A',
              providerOptions: {
                'anthropic': {'cacheControl': partCache},
              },
            ),
            TextPart('B'),
          ],
        ),
      ]);

      final body = builder.buildRequestBodyFromPrompt(prompt, null, false);
      final messages = body['messages'] as List<dynamic>;
      final content = messages.single['content'] as List<dynamic>;

      expect(content[0]['cache_control'], equals(partCache));
      expect(content[1]['cache_control'], equals(messageCache));
    });

    test('ToolCallPart precedence: part > toolCall > message > default', () {
      final builder = builderWithDefaultCache();

      final toolCall = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: const FunctionCall(name: 'get_weather', arguments: '{}'),
        providerOptions: const {
          'anthropic': {'cacheControl': toolCallCache},
        },
      );

      final prompt = Prompt(messages: [
        PromptMessage.user('hi'),
        PromptMessage(
          role: ChatRole.assistant,
          providerOptions: const {
            'anthropic': {'cacheControl': messageCache},
          },
          parts: [
            ToolCallPart(
              toolCall,
              providerOptions: const {
                'anthropic': {'cacheControl': partCache},
              },
            ),
          ],
        ),
      ]);

      final body = builder.buildRequestBodyFromPrompt(prompt, null, false);
      final messages = body['messages'] as List<dynamic>;
      final assistant = messages[1] as Map<String, dynamic>;
      final content = assistant['content'] as List<dynamic>;

      expect(content.single['type'], equals('tool_use'));
      expect(content.single['cache_control'], equals(partCache));
    });

    test('ToolResultPart precedence: part > toolResult > message > default',
        () {
      final builder = builderWithDefaultCache();

      final toolCall = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: const FunctionCall(name: 'get_weather', arguments: '{}'),
      );

      final toolResult = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: const FunctionCall(name: 'get_weather', arguments: '"ok"'),
        providerOptions: const {
          'anthropic': {'cacheControl': toolCallCache},
        },
      );

      final prompt = Prompt(messages: [
        PromptMessage.user('hi'),
        PromptMessage(
          role: ChatRole.assistant,
          parts: [
            ToolCallPart(toolCall),
          ],
        ),
        PromptMessage(
          role: ChatRole.user,
          providerOptions: const {
            'anthropic': {'cacheControl': messageCache},
          },
          parts: [
            ToolResultPart(
              toolResult,
              providerOptions: const {
                'anthropic': {'cacheControl': partCache},
              },
            ),
          ],
        ),
      ]);

      final body = builder.buildRequestBodyFromPrompt(prompt, null, false);
      final messages = body['messages'] as List<dynamic>;
      final userToolResultMsg = messages[2] as Map<String, dynamic>;
      final content = userToolResultMsg['content'] as List<dynamic>;

      expect(content.single['type'], equals('tool_result'));
      expect(content.single['cache_control'], equals(partCache));
    });
  });
}
