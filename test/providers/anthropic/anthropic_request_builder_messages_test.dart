import 'package:llm_dart/models/chat_models.dart';
import 'package:llm_dart/models/tool_models.dart';
import 'package:llm_dart/providers/anthropic/config.dart';
import 'package:llm_dart/providers/anthropic/models.dart';
import 'package:llm_dart/src/compatibility/providers/anthropic/request_builder.dart';
import 'package:test/test.dart';

void main() {
  group('Anthropic request builder messages', () {
    test('keeps cached system text in system and excludes tool blocks', () {
      final builder = _builder();

      final body = builder.buildRequestBody(
        [
          MessageBuilder.system()
              .text('Reusable system instructions.')
              .tools([_weatherTool()])
              .anthropicConfig(
                (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour),
              )
              .build(),
          ChatMessage.user('Hello'),
        ],
        null,
        false,
      );

      expect(body['messages'], [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': 'Hello'},
          ],
        },
      ]);
      expect(body['system'], [
        {
          'type': 'text',
          'text': 'Reusable system instructions.',
          'cache_control': {
            'type': 'ephemeral',
            'ttl': '1h',
          },
        },
      ]);

      final systemBlocks = body['system'] as List<dynamic>;
      expect(
        systemBlocks.any(
          (block) => block is Map<String, dynamic> && block['type'] == 'tools',
        ),
        isFalse,
      );
    });

    test('applies cache control to user and assistant text blocks', () {
      final builder = _builder();

      final body = builder.buildRequestBody(
        [
          MessageBuilder.user()
              .text('Cached user text.')
              .anthropicConfig(
                (anthropic) =>
                    anthropic.cache(ttl: AnthropicCacheTtl.fiveMinutes),
              )
              .build(),
          MessageBuilder.assistant()
              .text('Cached assistant text.')
              .anthropicConfig(
                (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour),
              )
              .build(),
        ],
        null,
        false,
      );

      expect(body['messages'], [
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': 'Cached user text.',
              'cache_control': {
                'type': 'ephemeral',
                'ttl': '5m',
              },
            },
          ],
        },
        {
          'role': 'assistant',
          'content': [
            {
              'type': 'text',
              'text': 'Cached assistant text.',
              'cache_control': {
                'type': 'ephemeral',
                'ttl': '1h',
              },
            },
          ],
        },
      ]);
    });

    test('falls back to text when tool use arguments are malformed', () {
      final builder = _builder();

      final body = builder.buildRequestBody(
        [
          ChatMessage.user('Call the tool.'),
          ChatMessage.toolUse(
            toolCalls: [
              const ToolCall(
                id: 'toolu_1',
                callType: 'function',
                function: FunctionCall(
                  name: 'get_weather',
                  arguments: '{not-json',
                ),
              ),
            ],
          ),
        ],
        null,
        false,
      );

      expect(body['messages'], [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': 'Call the tool.'},
          ],
        },
        {
          'role': 'assistant',
          'content': [
            {
              'type': 'text',
              'text': '[Error: Invalid tool call arguments for get_weather]',
            },
          ],
        },
      ]);
    });

    test('infers tool result errors from JSON and text content', () {
      final builder = _builder();

      final body = builder.buildRequestBody(
        [
          ChatMessage.toolResult(
            results: [
              const ToolCall(
                id: 'toolu_json',
                callType: 'function',
                function: FunctionCall(
                  name: 'get_weather',
                  arguments: '{"success":false,"message":"bad city"}',
                ),
              ),
              const ToolCall(
                id: 'toolu_text',
                callType: 'function',
                function: FunctionCall(
                  name: 'get_weather',
                  arguments: 'Exception: lookup failed',
                ),
              ),
            ],
          ),
        ],
        null,
        false,
      );

      expect(body['messages'], [
        {
          'role': 'user',
          'content': [
            {
              'type': 'tool_result',
              'tool_use_id': 'toolu_json',
              'content': '{"success":false,"message":"bad city"}',
              'is_error': true,
            },
            {
              'type': 'tool_result',
              'tool_use_id': 'toolu_text',
              'content': 'Exception: lookup failed',
              'is_error': true,
            },
          ],
        },
      ]);
    });
  });
}

AnthropicRequestBuilder _builder() {
  return AnthropicRequestBuilder(
    const AnthropicConfig(
      apiKey: 'test-key',
      model: 'claude-3-5-sonnet-latest',
    ),
  );
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
