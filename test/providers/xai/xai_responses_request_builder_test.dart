import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:llm_dart_xai/responses.dart';
import 'package:llm_dart_xai/file_search_tool_options.dart';
import 'package:llm_dart_xai/mcp_tool_options.dart';
import 'package:llm_dart_xai/provider_tools.dart';
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
            args: {
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
        inputSchema: Schema.params(
          properties: {
            'location': Schema.string('city name'),
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

    test('normalizes camelCase provider tool options', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.x.ai/v1/',
        model: 'grok-4-fast',
        providerTools: [
          XAIProviderTools.fileSearch(
            options: const XAIFileSearchToolOptions(
              vectorStoreIds: ['vs_1'],
              maxNumResults: 7,
            ),
          ),
          XAIProviderTools.mcp(
            options: const XAIMcpToolOptions(
              serverUrl: 'https://mcp.example.com',
              serverLabel: 'mcp',
              serverDescription: 'test server',
              allowedTools: ['tool_a', 'tool_b'],
              headers: {'x-test': '1'},
              authorization: 'Bearer test',
            ),
          ),
        ],
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

      final tools =
          (client.lastJsonBody?['tools'] as List?)?.whereType<Map>().toList();
      expect(tools, isNotNull);

      final fileSearch = tools!
          .firstWhere((t) => t['type'] == 'file_search')
          .cast<String, dynamic>();
      expect(fileSearch['vector_store_ids'], equals(['vs_1']));
      expect(fileSearch['max_num_results'], equals(7));

      final mcp =
          tools.firstWhere((t) => t['type'] == 'mcp').cast<String, dynamic>();
      expect(mcp['server_url'], equals('https://mcp.example.com'));
      expect(mcp['server_label'], equals('mcp'));
      expect(mcp['server_description'], equals('test server'));
      expect(mcp['allowed_tools'], equals(['tool_a', 'tool_b']));
      expect(mcp['headers'], equals({'x-test': '1'}));
      expect(mcp['authorization'], equals('Bearer test'));
    });
  });
}
