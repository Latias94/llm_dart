import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('Anthropic web search tool (provider-native)', () {
    test(
        'injects web_search_* tool into request body when providerOptions.webSearch is set',
        () {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'claude-sonnet-4-20250514',
        providerOptions: {
          'anthropic': {
            'webSearch': {
              'max_uses': 3,
              'allowed_domains': ['example.com'],
              'user_location': {
                'type': 'approximate',
                'city': 'London',
                'region': 'England',
                'country': 'GB',
                'timezone': 'Europe/London',
              },
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

      final json = tools.first as Map<String, dynamic>;
      expect(json['type'], equals('web_search_20250305'));
      expect(json['name'], equals('web_search'));
      expect(json['max_uses'], equals(3));
      expect(json['allowed_domains'], equals(['example.com']));
      expect((json['user_location'] as Map)['city'], equals('London'));
      expect((json['user_location'] as Map)['type'], equals('approximate'));
    });

    test(
        'allows overriding tool type via providerOptions.webSearch.mode=web_search_*',
        () {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'claude-sonnet-4-20250514',
        providerOptions: {
          'anthropic': {
            'webSearch': const {
              'mode': 'web_search_20250305',
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
      expect(json['type'], equals('web_search_20250305'));
    });

    test(
        'allows a function tool named web_search when provider-native web search is disabled',
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
            name: 'web_search',
            description: 'Local web search',
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
      expect(json['name'], equals('web_search'));
    });

    test(
        'rewrites colliding function tool name when provider-native web search is enabled',
        () {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'claude-sonnet-4-20250514',
        providerOptions: {
          'anthropic': {
            'webSearchEnabled': true,
          },
        },
      );

      final anthropicConfig = AnthropicConfig.fromLLMConfig(llmConfig);
      final builder = AnthropicRequestBuilder(anthropicConfig);

      final body = builder.buildRequestBody(
        [ChatMessage.user('hi')],
        [
          Tool.function(
            name: 'web_search',
            description: 'Local web search',
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

      expect(toolNames, contains('web_search'));
      expect(toolNames, contains('web_search__1'));
    });

    test(
        'injects web_search_* tool into request body when providerTools includes anthropic.web_search_*',
        () {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'claude-sonnet-4-20250514',
        providerTools: const [
          ProviderTool(
            id: 'anthropic.web_search_20250305',
            options: {
              'max_uses': 2,
              'allowed_domains': ['example.com'],
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
      expect(json['type'], equals('web_search_20250305'));
      expect(json['name'], equals('web_search'));
      expect(json['max_uses'], equals(2));
      expect(json['allowed_domains'], equals(['example.com']));
    });

    test(
        'rewrites colliding function tool name when providerTools enables provider-native web search',
        () {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'claude-sonnet-4-20250514',
        providerTools: const [
          ProviderTool(id: 'anthropic.web_search_20250305'),
        ],
      );

      final anthropicConfig = AnthropicConfig.fromLLMConfig(llmConfig);
      final builder = AnthropicRequestBuilder(anthropicConfig);

      final body = builder.buildRequestBody(
        [ChatMessage.user('hi')],
        [
          Tool.function(
            name: 'web_search',
            description: 'Local web search',
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

      expect(toolNames, contains('web_search'));
      expect(toolNames, contains('web_search__1'));
    });
  });
}
