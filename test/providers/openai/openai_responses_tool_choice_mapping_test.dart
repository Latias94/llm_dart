import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_openai/builtin_tools.dart';
import 'package:llm_dart_openai/client.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai_client;
import 'package:llm_dart_openai/responses.dart' as openai_responses;
import 'package:test/test.dart';

import '../../utils/fakes/fakes.dart';

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
      final clientAuto = FakeOpenAIClient(configAuto);
      await openai_responses.OpenAIResponses(clientAuto, configAuto)
          .chatWithTools([ChatMessage.user('hi')], [_tool('t')]);
      expect(clientAuto.lastJsonBody?['tool_choice'], equals('auto'));

      final configNone =
          configAuto.copyWith(toolChoice: const NoneToolChoice());
      final clientNone = FakeOpenAIClient(configNone);
      await openai_responses.OpenAIResponses(clientNone, configNone)
          .chatWithTools([ChatMessage.user('hi')], [_tool('t')]);
      expect(clientNone.lastJsonBody?['tool_choice'], equals('none'));

      final configReq = configAuto.copyWith(toolChoice: const AnyToolChoice());
      final clientReq = FakeOpenAIClient(configReq);
      await openai_responses.OpenAIResponses(clientReq, configReq)
          .chatWithTools([ChatMessage.user('hi')], [_tool('t')]);
      expect(clientReq.lastJsonBody?['tool_choice'], equals('required'));
    });

    test('serializes specific function selection as {type:function,name}',
        () async {
      final config = openai_client.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o',
        useResponsesAPI: true,
        toolChoice: const SpecificToolChoice('myTool'),
      );
      final client = FakeOpenAIClient(config);

      await openai_responses.OpenAIResponses(client, config)
          .chatWithTools([ChatMessage.user('hi')], [_tool('myTool')]);

      expect(client.lastJsonBody?['tool_choice'], isA<Map>());
      final choice =
          (client.lastJsonBody?['tool_choice'] as Map).cast<String, dynamic>();
      expect(choice['type'], equals('function'));
      expect(choice['name'], equals('myTool'));
    });

    test('allows selecting built-in tool when no function tool matches',
        () async {
      final config = openai_client.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o',
        useResponsesAPI: true,
        builtInTools: const [OpenAIWebSearchTool()],
        toolChoice: const SpecificToolChoice('web_search_preview'),
      );
      final client = FakeOpenAIClient(config);

      await openai_responses.OpenAIResponses(client, config)
          .chat([ChatMessage.user('hi')]);

      expect(client.lastJsonBody?['tool_choice'], isA<Map>());
      final choice =
          (client.lastJsonBody?['tool_choice'] as Map).cast<String, dynamic>();
      expect(choice['type'], equals('web_search_preview'));
    });
  });
}
