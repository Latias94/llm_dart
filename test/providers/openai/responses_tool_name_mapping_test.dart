import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai_client;
import 'package:llm_dart_openai/builtin_tools.dart';
import 'package:llm_dart_openai/responses.dart' as openai_responses;
import 'package:llm_dart_openai/client.dart';
import 'package:test/test.dart';

import '../../utils/fakes/fakes.dart';

void main() {
  group('OpenAI Responses ToolNameMapping', () {
    Tool functionToolNamed(String name) {
      return Tool.function(
        name: name,
        description: 'test tool',
        parameters: const ParametersSchema(
          schemaType: 'object',
          properties: {},
          required: [],
        ),
      );
    }

    test('rewrites colliding function tool names when built-in tools enabled',
        () async {
      final config = openai_client.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o',
        useResponsesAPI: true,
        builtInTools: const [OpenAIWebSearchTool()],
        toolChoice: const SpecificToolChoice('web_search_preview'),
      );

      final client = FakeOpenAIClient(config)
        ..jsonResponse = const <String, dynamic>{};
      final responses = openai_responses.OpenAIResponses(client, config);

      await responses.chatWithTools(
        [ChatMessage.user('test')],
        [functionToolNamed('web_search_preview')],
      );

      final tools = (client.lastJsonBody!['tools'] as List).cast<Map>();
      expect(
        tools.where((t) => t['type'] == 'web_search_preview'),
        hasLength(1),
      );

      final functionTools =
          tools.where((t) => t['type'] == 'function').toList();
      expect(functionTools, hasLength(1));
      expect(functionTools.single['name'], equals('web_search_preview__1'));

      final toolChoice =
          client.lastJsonBody!['tool_choice'] as Map<String, dynamic>;
      expect(toolChoice['type'], equals('function'));
      expect(toolChoice['name'], equals('web_search_preview__1'));
    });

    test('maps function_call names back to original tool names', () async {
      final config = openai_client.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o',
        useResponsesAPI: true,
        builtInTools: const [OpenAIWebSearchTool()],
      );

      final client = FakeOpenAIClient(config)
        ..jsonResponse = const <String, dynamic>{
          'output': [
            {
              'type': 'function_call',
              'call_id': 'call_1',
              'name': 'web_search_preview__1',
              'arguments': '{}',
            }
          ],
        };

      final responses = openai_responses.OpenAIResponses(client, config);

      final response = await responses.chatWithTools(
        [ChatMessage.user('test')],
        [functionToolNamed('web_search_preview')],
      );

      final toolCalls = response.toolCalls;
      expect(toolCalls, isNotNull);
      expect(toolCalls, hasLength(1));
      expect(toolCalls!.single.function.name, equals('web_search_preview'));
    });
  });
}
