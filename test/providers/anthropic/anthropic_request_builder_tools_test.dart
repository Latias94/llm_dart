import 'package:llm_dart/core/web_search.dart';
import 'package:llm_dart/models/chat_models.dart';
import 'package:llm_dart/models/tool_models.dart';
import 'package:llm_dart/providers/anthropic/config.dart';
import 'package:llm_dart/providers/anthropic/models.dart';
import 'package:llm_dart/src/compatibility/providers/anthropic/request_builder.dart';
import 'package:test/test.dart';

void main() {
  group('Anthropic request builder tools', () {
    test('extracts cached message-builder tools into the API tools array', () {
      final builder = AnthropicRequestBuilder(
        const AnthropicConfig(
          apiKey: 'test-key',
          model: 'claude-3-5-sonnet-latest',
          toolChoice: SpecificToolChoice(
            'get_weather',
            disableParallelToolUse: true,
          ),
        ),
      );

      final body = builder.buildRequestBody(
        [
          MessageBuilder.system()
              .anthropicConfig(
            (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour),
          )
              .tools([_weatherTool()]).build(),
          ChatMessage.user('What is the weather?'),
        ],
        null,
        false,
      );

      expect(body['messages'], [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': 'What is the weather?'},
          ],
        },
      ]);
      expect(body['tools'], [
        {
          'name': 'get_weather',
          'description': 'Get current weather.',
          'input_schema': {
            'type': 'object',
            'properties': {
              'city': {
                'type': 'string',
                'description': 'City name.',
              },
            },
            'required': ['city'],
          },
          'cache_control': {
            'type': 'ephemeral',
            'ttl': '1h',
          },
        },
      ]);
      expect(body['tool_choice'], {
        'type': 'tool',
        'name': 'get_weather',
        'disable_parallel_tool_use': true,
      });
      expect(body.containsKey('system'), isFalse);
    });

    test('converts native web search tool with Anthropic web search config',
        () {
      final builder = AnthropicRequestBuilder(
        AnthropicConfig(
          apiKey: 'test-key',
          model: 'claude-3-5-sonnet-latest',
          tools: [_webSearchTool()],
          webSearchConfig: const WebSearchConfig(
            maxUses: 3,
            allowedDomains: ['example.com'],
            blockedDomains: ['blocked.test'],
            location: WebSearchLocation(
              city: 'Tokyo',
              region: 'Tokyo',
              country: 'JP',
              timezone: 'Asia/Tokyo',
            ),
          ),
        ),
      );

      final body = builder.buildRequestBody(
        [ChatMessage.user('Search current docs.')],
        null,
        false,
      );

      expect(body['tools'], [
        {
          'type': 'web_search_20250305',
          'name': 'web_search',
          'max_uses': 3,
          'allowed_domains': ['example.com'],
          'blocked_domains': ['blocked.test'],
          'user_location': {
            'type': 'approximate',
            'city': 'Tokyo',
            'region': 'Tokyo',
            'country': 'JP',
            'timezone': 'Asia/Tokyo',
          },
        },
      ]);
    });
  });
}

Tool _weatherTool() {
  return Tool.function(
    name: 'get_weather',
    description: 'Get current weather.',
    parameters: const ParametersSchema(
      schemaType: 'object',
      properties: {
        'city': ParameterProperty(
          propertyType: 'string',
          description: 'City name.',
        ),
      },
      required: ['city'],
    ),
  );
}

Tool _webSearchTool() {
  return Tool.function(
    name: 'web_search',
    description: 'Search the web.',
    parameters: const ParametersSchema(
      schemaType: 'object',
      properties: {},
      required: [],
    ),
  );
}
