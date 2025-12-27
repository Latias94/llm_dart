import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('Anthropic providerOptions cacheControl', () {
    test('applies cache_control to system, messages, and tools', () {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'claude-sonnet-4-20250514',
        systemPrompt: 'Config system prompt',
        providerOptions: const {
          'anthropic': {
            'cacheControl': {'type': 'ephemeral', 'ttl': '1h'},
          },
        },
      );

      final anthropicConfig = AnthropicConfig.fromLLMConfig(llmConfig);
      final builder = AnthropicRequestBuilder(anthropicConfig);

      final tool1 = Tool.function(
        name: 'get_weather',
        description: 'Get current weather',
        parameters: ParametersSchema(
          schemaType: 'object',
          properties: {
            'location': ParameterProperty(
              propertyType: 'string',
              description: 'City name',
            ),
          },
          required: ['location'],
        ),
      );

      final tool2 = Tool.function(
        name: 'search_documents',
        description: 'Search through documents',
        parameters: ParametersSchema(
          schemaType: 'object',
          properties: {
            'query': ParameterProperty(
              propertyType: 'string',
              description: 'Search query',
            ),
          },
          required: ['query'],
        ),
      );

      final body = builder.buildRequestBody(
        [
          ChatMessage.system('System message'),
          ChatMessage.user('Hello'),
        ],
        [tool1, tool2],
        false,
      );

      final system = body['system'] as List<dynamic>;
      expect(system.length, equals(2));
      expect(system[0]['text'], equals('Config system prompt'));
      expect(system[0]['cache_control'],
          equals({'type': 'ephemeral', 'ttl': '1h'}));
      expect(system[1]['text'], equals('System message'));
      expect(system[1]['cache_control'],
          equals({'type': 'ephemeral', 'ttl': '1h'}));

      final messages = body['messages'] as List<dynamic>;
      expect(messages.length, equals(1));
      final userContent = messages[0]['content'] as List<dynamic>;
      expect(userContent.length, equals(1));
      expect(userContent[0]['type'], equals('text'));
      expect(userContent[0]['text'], equals('Hello'));
      expect(userContent[0]['cache_control'],
          equals({'type': 'ephemeral', 'ttl': '1h'}));

      final tools = body['tools'] as List<dynamic>;
      expect(tools.length, equals(2));
      expect(tools[0].containsKey('cache_control'), isFalse);
      expect(tools[1]['cache_control'],
          equals({'type': 'ephemeral', 'ttl': '1h'}));
    });
  });
}
