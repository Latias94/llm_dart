import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_ollama/llm_dart_ollama.dart';
import 'package:test/test.dart';

class FakeOllamaClient extends OllamaClient {
  Map<String, dynamic>? lastRequestBody;
  String? lastEndpoint;

  FakeOllamaClient(OllamaConfig config) : super(config);

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastRequestBody = data;

    return {
      'message': {'role': 'assistant', 'content': 'ok'},
      'done': true,
    };
  }
}

void main() {
  group('OllamaChat prompt mapping', () {
    test('builds messages from ChatPromptMessage with tools and jsonSchema',
        () async {
      final tool = Tool.function(
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
          required: const ['location'],
        ),
      );

      final schema = StructuredOutputFormat(
        name: 'Weather',
        schema: {
          'type': 'object',
          'properties': {
            'temp': {'type': 'number'},
          },
          'required': ['temp'],
        },
      );

      final config = OllamaConfig(
        model: 'llama3.2',
        tools: [tool],
        jsonSchema: schema,
      );

      final client = FakeOllamaClient(config);
      final chat = OllamaChat(client, config);

      final messages = <ChatMessage>[
        ChatMessage.user('Hello'),
        ChatMessage.toolResult(
          results: [
            ToolCall(
              id: 'call_1',
              callType: 'function',
              function: const FunctionCall(
                name: 'get_weather',
                arguments: '{"location":"Tokyo"}',
              ),
            ),
          ],
        ),
      ];

      await chat.chatWithTools(messages, null);

      final body = client.lastRequestBody;
      expect(body, isNotNull);

      final apiMessages = body!['messages'] as List<dynamic>;
      expect(apiMessages.length, equals(2));

      final userMessage = apiMessages[0] as Map<String, dynamic>;
      expect(userMessage['role'], equals('user'));
      expect(userMessage['content'], contains('Hello'));

      final toolMessage = apiMessages[1] as Map<String, dynamic>;
      expect(toolMessage['role'], equals('tool'));
      expect(toolMessage['tool_call_id'], equals('call_1'));
      expect(
        toolMessage['content'],
        equals('{"location":"Tokyo"}'),
      );

      final toolsJson = body['tools'] as List<dynamic>;
      expect(toolsJson.length, equals(1));

      final responseFormat = body['response_format'] as Map<String, dynamic>?;
      expect(responseFormat, isNotNull);
      expect(responseFormat!['type'], equals('json_schema'));
    });
  });
}
