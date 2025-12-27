import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai_client;
import 'package:test/test.dart';

void main() {
  group('OpenAI Responses API include options', () {
    test('should auto-include web search sources when web search tool present',
        () async {
      final originalConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o-search-preview',
        providerOptions: const {},
      );

      final config = openai_client.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o-search-preview',
        useResponsesAPI: true,
        builtInTools: [OpenAIBuiltInTools.webSearch()],
        originalConfig: originalConfig,
      );

      final client = _CapturingOpenAIClient(config);
      final responses = openai_client.OpenAIResponses(client, config);

      await responses.chat([ChatMessage.user('test')]);

      expect(client.lastBody, isNotNull);
      expect(client.lastBody!['include'], isA<List>());
      expect(
        (client.lastBody!['include'] as List).cast<String>(),
        contains('web_search_call.action.sources'),
      );
    });

    test(
        'should auto-include file search results when file search tool present',
        () async {
      final originalConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o',
        providerOptions: const {},
      );

      final config = openai_client.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o',
        useResponsesAPI: true,
        builtInTools: [OpenAIBuiltInTools.fileSearch()],
        originalConfig: originalConfig,
      );

      final client = _CapturingOpenAIClient(config);
      final responses = openai_client.OpenAIResponses(client, config);

      await responses.chat([ChatMessage.user('test')]);

      expect(client.lastBody, isNotNull);
      expect(client.lastBody!['include'], isA<List>());
      expect(
        (client.lastBody!['include'] as List).cast<String>(),
        contains('file_search_call.results'),
      );
    });

    test(
        'should auto-include computer call image urls when computer use tool present',
        () async {
      final originalConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o',
        providerOptions: const {},
      );

      final config = openai_client.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o',
        useResponsesAPI: true,
        builtInTools: [
          OpenAIBuiltInTools.computerUse(
            displayWidth: 1024,
            displayHeight: 768,
            environment: 'browser',
          )
        ],
        originalConfig: originalConfig,
      );

      final client = _CapturingOpenAIClient(config);
      final responses = openai_client.OpenAIResponses(client, config);

      await responses.chat([ChatMessage.user('test')]);

      expect(client.lastBody, isNotNull);
      expect(client.lastBody!['include'], isA<List>());
      expect(
        (client.lastBody!['include'] as List).cast<String>(),
        contains('computer_call_output.output.image_url'),
      );
    });

    test('should merge providerOptions include with auto web search include',
        () async {
      final originalConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o-search-preview',
        providerOptions: const {
          'openai': {
            'include': [
              'message.output_text.logprobs',
              'web_search_call.action.sources',
            ],
          }
        },
      );

      final config = openai_client.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o-search-preview',
        useResponsesAPI: true,
        builtInTools: [OpenAIBuiltInTools.webSearch()],
        originalConfig: originalConfig,
      );

      final client = _CapturingOpenAIClient(config);
      final responses = openai_client.OpenAIResponses(client, config);

      await responses.chat([ChatMessage.user('test')]);

      final include = (client.lastBody!['include'] as List).cast<String>();
      expect(include, contains('message.output_text.logprobs'));
      expect(include, contains('web_search_call.action.sources'));
      expect(include.toSet().length, equals(include.length));
    });

    test('should pass through providerOptions include without web search tool',
        () async {
      final originalConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o',
        providerOptions: const {
          'openai': {
            'include': ['message.output_text.logprobs'],
          }
        },
      );

      final config = openai_client.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o',
        useResponsesAPI: true,
        originalConfig: originalConfig,
      );

      final client = _CapturingOpenAIClient(config);
      final responses = openai_client.OpenAIResponses(client, config);

      await responses.chat([ChatMessage.user('test')]);

      expect(
        (client.lastBody!['include'] as List).cast<String>(),
        equals(['message.output_text.logprobs']),
      );
    });
  });
}

class _CapturingOpenAIClient extends openai_client.OpenAIClient {
  Map<String, dynamic>? lastBody;

  _CapturingOpenAIClient(super.config);

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) async {
    lastBody = body;
    return {};
  }
}
