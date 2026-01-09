import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:llm_dart_openai_compatible/client.dart';
import 'package:llm_dart_xai/responses.dart';
import 'package:test/test.dart';

import '../../utils/fakes/fakes.dart';

void main() {
  group('xAI Responses request builder', () {
    test('maps providerTools to xAI Responses tools', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.x.ai/v1/',
        model: 'grok-4-fast',
        maxTokens: 123,
        providerTools: const [
          ProviderTool(
            id: 'xai.web_search',
            options: {
              'allowed_domains': ['example.com'],
              'enable_image_understanding': true,
            },
          ),
          ProviderTool(id: 'xai.x_search'),
          ProviderTool(id: 'xai.code_execution'),
          ProviderTool(id: 'xai.mcp'),
        ],
        providerOptions: const {
          'xai.responses': {
            'store': false,
            'previousResponseId': 'resp_1',
            'parallelToolCalls': true,
          },
        },
      );

      final config = OpenAICompatibleConfig.fromLLMConfig(
        llmConfig,
        providerId: 'xai.responses',
        providerName: 'xAI (Responses)',
      );

      final client = FakeOpenAIClient(config)
        ..jsonResponse = const {
          'object': 'response',
          'status': 'completed',
          'output': [],
          'usage': {
            'input_tokens': 0,
            'output_tokens': 0,
            'total_tokens': 0,
          },
        };
      final responses = XAIResponses(client, config);

      await responses.chat([ChatMessage.user('Hi')]);

      expect(client.lastEndpoint, equals('responses'));
      final body = client.lastJsonBody;
      expect(body, isNotNull);
      expect(body!['model'], equals('grok-4-fast'));
      expect(body['stream'], isFalse);
      expect(body['max_output_tokens'], equals(123));
      expect(body['previous_response_id'], equals('resp_1'));
      expect(body['store'], isFalse);
      expect(body['parallel_tool_calls'], isTrue);

      final tools = body['tools'] as List?;
      expect(tools, isNotNull);
      expect(tools!.whereType<Map>().map((t) => t['type']).toSet(),
          containsAll(['web_search', 'x_search', 'code_interpreter', 'mcp']));

      final webSearch = tools
          .whereType<Map>()
          .cast<Map>()
          .firstWhere((t) => t['type'] == 'web_search');
      expect(webSearch['allowed_domains'], equals(['example.com']));
      expect(webSearch['enable_image_understanding'], isTrue);
    });

    test('includes function tools in Responses tools array', () async {
      final weather = Tool.function(
        name: 'weather',
        description: 'Get weather by location',
        parameters: const ParametersSchema(
          schemaType: 'object',
          properties: {
            'location': ParameterProperty(
              propertyType: 'string',
              description: 'city name',
            ),
          },
          required: ['location'],
        ),
      );

      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.x.ai/v1/',
        model: 'grok-4-fast',
        tools: [weather],
      );

      final config = OpenAICompatibleConfig.fromLLMConfig(
        llmConfig,
        providerId: 'xai.responses',
        providerName: 'xAI (Responses)',
      );

      final client = FakeOpenAIClient(config)
        ..jsonResponse = const {
          'object': 'response',
          'status': 'completed',
          'output': [],
          'usage': {
            'input_tokens': 0,
            'output_tokens': 0,
            'total_tokens': 0,
          },
        };
      final responses = XAIResponses(client, config);

      await responses.chatWithTools([ChatMessage.user('Hi')], null);

      final tools =
          (client.lastJsonBody?['tools'] as List?)?.whereType<Map>().toList();
      expect(tools, isNotNull);

      final fn = tools!.firstWhere((t) => t['type'] == 'function');
      expect(fn['function'], isA<Map>());
      expect((fn['function'] as Map)['name'], equals('weather'));
    });
  });
}
