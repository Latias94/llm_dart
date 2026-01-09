import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_openai/builtin_tools.dart';
import 'package:llm_dart_openai/client.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai_client;
import 'package:llm_dart_openai/responses.dart' as openai_responses;
import 'package:test/test.dart';

void main() {
  group('OpenAI Responses tool_choice mapping (AI SDK parity)', () {
    Tool _tool(String name) => Tool.function(
          name: name,
          description: 'tool',
          parameters: const ParametersSchema(
            schemaType: 'object',
            properties: {},
            required: [],
          ),
        );

    test('serializes auto/none/required as strings', () async {
      final configAuto = openai_client.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o',
        useResponsesAPI: true,
        toolChoice: const AutoToolChoice(),
      );
      final clientAuto = _CapturingOpenAIClient(configAuto);
      await openai_responses
          .OpenAIResponses(clientAuto, configAuto)
          .chatWithTools([ChatMessage.user('hi')], [_tool('t')]);
      expect(clientAuto.lastBody?['tool_choice'], equals('auto'));

      final configNone = configAuto.copyWith(toolChoice: const NoneToolChoice());
      final clientNone = _CapturingOpenAIClient(configNone);
      await openai_responses
          .OpenAIResponses(clientNone, configNone)
          .chatWithTools([ChatMessage.user('hi')], [_tool('t')]);
      expect(clientNone.lastBody?['tool_choice'], equals('none'));

      final configReq = configAuto.copyWith(toolChoice: const AnyToolChoice());
      final clientReq = _CapturingOpenAIClient(configReq);
      await openai_responses
          .OpenAIResponses(clientReq, configReq)
          .chatWithTools([ChatMessage.user('hi')], [_tool('t')]);
      expect(clientReq.lastBody?['tool_choice'], equals('required'));
    });

    test('serializes specific function selection as {type:function,name}', () async {
      final config = openai_client.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o',
        useResponsesAPI: true,
        toolChoice: const SpecificToolChoice('myTool'),
      );
      final client = _CapturingOpenAIClient(config);

      await openai_responses
          .OpenAIResponses(client, config)
          .chatWithTools([ChatMessage.user('hi')], [_tool('myTool')]);

      expect(client.lastBody?['tool_choice'], isA<Map>());
      final choice = (client.lastBody?['tool_choice'] as Map).cast<String, dynamic>();
      expect(choice['type'], equals('function'));
      expect(choice['name'], equals('myTool'));
    });

    test('allows selecting built-in tool when no function tool matches', () async {
      final config = openai_client.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o',
        useResponsesAPI: true,
        builtInTools: const [OpenAIWebSearchTool()],
        toolChoice: const SpecificToolChoice('web_search_preview'),
      );
      final client = _CapturingOpenAIClient(config);

      await openai_responses
          .OpenAIResponses(client, config)
          .chat([ChatMessage.user('hi')]);

      expect(client.lastBody?['tool_choice'], isA<Map>());
      final choice = (client.lastBody?['tool_choice'] as Map).cast<String, dynamic>();
      expect(choice['type'], equals('web_search_preview'));
    });
  });
}

class _CapturingOpenAIClient extends OpenAIClient {
  Map<String, dynamic>? lastBody;

  _CapturingOpenAIClient(super.config);

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) async {
    lastBody = body;
    return const <String, dynamic>{};
  }
}

