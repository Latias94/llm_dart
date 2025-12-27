import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('Anthropic web fetch tool (provider-native)', () {
    test(
        'injects web_fetch_* tool into request body when providerOptions.webFetch is set',
        () {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'claude-sonnet-4-20250514',
        providerOptions: const {
          'anthropic': {
            'webFetch': {
              'max_uses': 2,
              'allowed_domains': ['example.com'],
              'citations': {'enabled': true},
              'max_content_tokens': 512,
            },
          },
        },
      );

      final anthropicConfig = AnthropicConfig.fromLLMConfig(llmConfig);
      final builder = AnthropicRequestBuilder(anthropicConfig);

      final body = builder.buildRequestBody(
        [ChatMessage.user('hi')],
        null,
        false,
      );

      final tools = body['tools'] as List<dynamic>;
      expect(tools, hasLength(1));

      final json = tools.single as Map<String, dynamic>;
      expect(json['type'], equals('web_fetch_20250910'));
      expect(json['name'], equals('web_fetch'));
      expect(json['max_uses'], equals(2));
      expect(json['allowed_domains'], equals(['example.com']));
      expect(json['citations'], equals({'enabled': true}));
      expect(json['max_content_tokens'], equals(512));
    });

    test('allows overriding tool type via providerOptions.webFetch.toolType',
        () {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'claude-sonnet-4-20250514',
        providerOptions: const {
          'anthropic': {
            'webFetch': {
              'toolType': 'web_fetch_20250910',
            },
          },
        },
      );

      final anthropicConfig = AnthropicConfig.fromLLMConfig(llmConfig);
      final builder = AnthropicRequestBuilder(anthropicConfig);

      final body = builder.buildRequestBody(
        [ChatMessage.user('hi')],
        null,
        false,
      );

      final tools = body['tools'] as List<dynamic>;
      final json = tools.single as Map<String, dynamic>;
      expect(json['type'], equals('web_fetch_20250910'));
      expect(json['name'], equals('web_fetch'));
    });

    test(
        'allows a function tool named web_fetch when provider-native web fetch is disabled',
        () {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'claude-sonnet-4-20250514',
      );

      final anthropicConfig = AnthropicConfig.fromLLMConfig(llmConfig);
      final builder = AnthropicRequestBuilder(anthropicConfig);

      final body = builder.buildRequestBody(
        [ChatMessage.user('hi')],
        [
          Tool.function(
            name: 'web_fetch',
            description: 'Local web fetch',
            parameters: const ParametersSchema(
              schemaType: 'object',
              properties: {},
              required: [],
            ),
          ),
        ],
        false,
      );

      final tools = body['tools'] as List<dynamic>;
      expect(tools, hasLength(1));

      final json = tools.single as Map<String, dynamic>;
      expect(json['name'], equals('web_fetch'));
    });

    test(
        'rewrites colliding function tool name when provider-native web fetch is enabled',
        () {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'claude-sonnet-4-20250514',
        providerOptions: const {
          'anthropic': {
            'webFetchEnabled': true,
          },
        },
      );

      final anthropicConfig = AnthropicConfig.fromLLMConfig(llmConfig);
      final builder = AnthropicRequestBuilder(anthropicConfig);

      final body = builder.buildRequestBody(
        [ChatMessage.user('hi')],
        [
          Tool.function(
            name: 'web_fetch',
            description: 'Local web fetch',
            parameters: const ParametersSchema(
              schemaType: 'object',
              properties: {},
              required: [],
            ),
          ),
        ],
        false,
      );

      final tools = body['tools'] as List<dynamic>;
      expect(tools, hasLength(2));

      final toolNames = tools
          .whereType<Map>()
          .map((t) => t['name'])
          .whereType<String>()
          .toList();

      expect(toolNames, contains('web_fetch'));
      expect(toolNames, contains('web_fetch__1'));
    });

    test(
        'injects web_fetch_* tool into request body when providerTools includes anthropic.web_fetch_*',
        () {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'claude-sonnet-4-20250514',
        providerTools: const [
          ProviderTool(
            id: 'anthropic.web_fetch_20250910',
            options: {
              'max_uses': 1,
              'max_content_tokens': 64,
            },
          ),
        ],
      );

      final anthropicConfig = AnthropicConfig.fromLLMConfig(llmConfig);
      final builder = AnthropicRequestBuilder(anthropicConfig);

      final body = builder.buildRequestBody(
        [ChatMessage.user('hi')],
        null,
        false,
      );

      final tools = body['tools'] as List<dynamic>;
      expect(tools, hasLength(1));

      final json = tools.single as Map<String, dynamic>;
      expect(json['type'], equals('web_fetch_20250910'));
      expect(json['name'], equals('web_fetch'));
      expect(json['max_uses'], equals(1));
      expect(json['max_content_tokens'], equals(64));
    });

    test(
        'rewrites colliding function tool name when providerTools enables provider-native web fetch',
        () {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'claude-sonnet-4-20250514',
        providerTools: const [
          ProviderTool(id: 'anthropic.web_fetch_20250910'),
        ],
      );

      final anthropicConfig = AnthropicConfig.fromLLMConfig(llmConfig);
      final builder = AnthropicRequestBuilder(anthropicConfig);

      final body = builder.buildRequestBody(
        [ChatMessage.user('hi')],
        [
          Tool.function(
            name: 'web_fetch',
            description: 'Local web fetch',
            parameters: const ParametersSchema(
              schemaType: 'object',
              properties: {},
              required: [],
            ),
          ),
        ],
        false,
      );

      final tools = body['tools'] as List<dynamic>;
      expect(tools, hasLength(2));

      final toolNames = tools
          .whereType<Map>()
          .map((t) => t['name'])
          .whereType<String>()
          .toList();

      expect(toolNames, contains('web_fetch'));
      expect(toolNames, contains('web_fetch__1'));
    });
  });
}
