import 'package:llm_dart/models/chat_models.dart';
import 'package:llm_dart/models/tool_models.dart';
import 'package:llm_dart/core/web_search.dart';
import 'package:llm_dart/providers/google/config.dart';
import 'package:llm_dart/src/compatibility/providers/google/client.dart';
import 'package:llm_dart/src/compatibility/providers/google/google_chat_message_codec.dart';
import 'package:llm_dart/src/compatibility/providers/google/google_chat_request_builder.dart';
import 'package:test/test.dart';

void main() {
  group('Google chat message codec extraction', () {
    test('converts supported inline images without changing payload shape', () {
      final codec = _buildCodec();

      final message = ChatMessage.image(
        role: ChatRole.user,
        mime: ImageMime.png,
        data: [1, 2, 3],
      );

      final result = codec.convertMessage(message);

      expect(result['role'], 'user');
      expect(result['parts'], [
        {
          'inlineData': {
            'mimeType': 'image/png',
            'data': 'AQID',
          },
        },
      ]);
    });

    test('converts tool-call replay messages through Google function parts',
        () {
      final codec = _buildCodec();
      const toolCall = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: FunctionCall(
          name: 'get_weather',
          arguments: '{"city":"Hong Kong"}',
        ),
      );

      final toolUse = codec.convertMessage(
        ChatMessage.toolUse(toolCalls: [toolCall]),
      );
      final toolResult = codec.convertMessage(
        ChatMessage.toolResult(results: [toolCall]),
      );

      expect(toolUse['role'], 'model');
      expect(toolUse['parts'], [
        {
          'functionCall': {
            'name': 'get_weather',
            'args': {'city': 'Hong Kong'},
          },
        },
      ]);

      expect(toolResult['role'], 'function');
      expect(toolResult['parts'], [
        {
          'functionResponse': {
            'name': 'get_weather',
            'response': {
              'name': 'get_weather',
              'content': {'city': 'Hong Kong'},
            },
          },
        },
      ]);
    });

    test('keeps specific tool choice mapping and missing-tool fallback', () {
      final codec = _buildCodec();
      final tools = [_weatherTool()];

      expect(
        codec.convertToolChoice(
          const SpecificToolChoice('get_weather'),
          tools,
        ),
        {
          'function_calling_config': {
            'mode': 'ANY',
            'allowed_function_names': ['get_weather'],
          },
        },
      );

      expect(
        codec.convertToolChoice(
          const SpecificToolChoice('missing_tool'),
          tools,
        ),
        {
          'function_calling_config': {
            'mode': 'AUTO',
          },
        },
      );
    });

    test(
        'request builder still composes system prompt, tools, and stream thinking',
        () {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-2.0-flash',
        systemPrompt: 'Be concise.',
        tools: [_weatherTool()],
        toolChoice: const SpecificToolChoice('get_weather'),
      );
      final client = GoogleClient(config);
      final builder = GoogleChatRequestBuilder(
        client: client,
        config: config,
      );

      final body = builder.buildRequestBody(
        [
          ChatMessage.system('Ignored system message'),
          ChatMessage.user('What is the weather?'),
        ],
        null,
        true,
      );

      expect(body['contents'], [
        {
          'role': 'user',
          'parts': [
            {'text': 'Be concise.'},
          ],
        },
        {
          'role': 'user',
          'parts': [
            {'text': 'What is the weather?'},
          ],
        },
      ]);
      expect(body['generationConfig'], {
        'thinkingConfig': {
          'includeThoughts': true,
        },
      });
      expect(body['tools'], [
        {
          'functionDeclarations': [
            {
              'name': 'get_weather',
              'description': 'Get weather information.',
              'parameters': {
                'type': 'object',
                'properties': {
                  'city': {
                    'type': 'string',
                    'description': 'City name.',
                  },
                },
                'required': ['city'],
              },
            },
          ],
        },
      ]);
      expect(body['tool_config'], {
        'function_calling_config': {
          'mode': 'ANY',
          'allowed_function_names': ['get_weather'],
        },
      });
    });

    test('request builder maps explicit web search config without LLMConfig',
        () {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-2.0-flash',
        webSearchConfig: const WebSearchConfig(),
      );
      final client = GoogleClient(config);
      final builder = GoogleChatRequestBuilder(
        client: client,
        config: config,
      );

      final body = builder.buildRequestBody(
        [ChatMessage.user('Search current information.')],
        null,
        false,
      );

      expect(body['tools'], [
        {'google_search': <String, Object?>{}},
      ]);
    });
  });
}

GoogleChatMessageCodec _buildCodec() {
  final config = GoogleConfig(
    apiKey: 'test-key',
    model: 'gemini-2.0-flash',
  );

  return GoogleChatMessageCodec(
    client: GoogleClient(config),
    config: config,
  );
}

Tool _weatherTool() {
  return Tool.function(
    name: 'get_weather',
    description: 'Get weather information.',
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
