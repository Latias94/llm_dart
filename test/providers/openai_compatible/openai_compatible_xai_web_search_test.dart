import 'package:dio/dio.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/testing.dart';
import 'package:test/test.dart';

import 'openai_compatible_test_utils.dart';

class CitationsOpenAICompatibleClient extends OpenAICompatibleClient {
  CitationsOpenAICompatibleClient(super.config);

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
    Map<String, String>? headers,
  }) async {
    return {
      'id': 'chatcmpl-1',
      'model': config.model,
      'citations': ['https://example.com'],
      'choices': [
        {
          'message': {
            'role': 'assistant',
            'content': 'ok',
          },
        },
      ],
    };
  }
}

void main() {
  group('OpenAICompatibleChat xai-openai web search', () {
    test('maps WebSearchConfig to search_parameters', () async {
      const webSearchConfig = WebSearchConfig(
        maxResults: 5,
        blockedDomains: ['example.com'],
        mode: 'auto',
        fromDate: '2025-01-01',
        toDate: '2025-01-02',
        searchType: WebSearchType.combined,
      );

      final originalConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.x.ai/v1/',
        model: 'grok-3',
        extensions: {
          LLMConfigKeys.webSearchEnabled: true,
          LLMConfigKeys.webSearchConfig: webSearchConfig,
        },
      );

      final config = OpenAICompatibleConfigs.xaiOpenAI(
        apiKey: 'test-key',
        model: 'grok-3',
        originalConfig: originalConfig,
      );

      final client = CapturingOpenAICompatibleClient(config);
      final chat = OpenAICompatibleChat(client, config);

      await chat.chat([ModelMessage.userText('Hello')]);

      final body = client.lastRequestBody!;
      expect(body.containsKey('search_parameters'), isTrue);

      final search = body['search_parameters'] as Map<String, dynamic>;
      expect(search['mode'], equals('auto'));
      expect(search['max_search_results'], equals(5));
      expect(search['from_date'], equals('2025-01-01'));
      expect(search['to_date'], equals('2025-01-02'));

      final sources = (search['sources'] as List).cast<Map<String, dynamic>>();
      expect(sources, hasLength(2));
      expect(sources.map((s) => s['type']).toList(), equals(['web', 'news']));
      expect(
        sources.map((s) => s['excluded_websites']).toList(),
        equals([
          ['example.com'],
          ['example.com'],
        ]),
      );
    });
  });

  group('OpenAICompatibleChat metadata', () {
    test('includes citations in metadata when present', () async {
      final originalConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.x.ai/v1/',
        model: 'grok-3',
      );

      final config = OpenAICompatibleConfigs.xaiOpenAI(
        apiKey: 'test-key',
        model: 'grok-3',
        originalConfig: originalConfig,
      );

      final client = CitationsOpenAICompatibleClient(config);
      final chat = OpenAICompatibleChat(client, config);

      final response = await chat.chat([ModelMessage.userText('Hello')]);
      final metadata = response.metadata!;

      expect(metadata['provider'], equals('xai-openai'));
      expect(metadata['model'], equals('grok-3'));
      expect(metadata['id'], equals('chatcmpl-1'));
      expect(metadata['hasCitations'], isTrue);
      expect(metadata['citations'], equals(['https://example.com']));
    });
  });
}
