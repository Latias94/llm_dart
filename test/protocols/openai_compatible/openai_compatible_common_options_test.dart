import 'package:dio/dio.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:llm_dart_openai_compatible/client.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI-compatible common options parity', () {
    test('allows keyless requests and merges custom headers', () async {
      final llmConfig = LLMConfig(
        apiKey: null,
        baseUrl: 'https://api.example.com/v1/',
        model: 'gpt-4o',
        providerOptions: const {
          'openai-compatible': {
            'headers': {
              'X-Test': '1',
            },
          },
        },
      );

      final config = OpenAICompatibleConfig.fromLLMConfig(
        llmConfig,
        providerId: 'openai-compatible',
        providerName: 'OpenAI-compatible',
      );

      final client = OpenAIClient(config);
      final adapter = _CapturingHttpClientAdapter();
      client.dio.httpClientAdapter = adapter;

      await client.postJson('chat/completions', {
        'model': 'gpt-4o',
        'messages': const [],
        'stream': false,
      });

      final options = adapter.lastOptions;
      expect(options, isNotNull);

      final headersLower = <String, String>{};
      for (final entry in options!.headers.entries) {
        headersLower[entry.key.toLowerCase()] = entry.value.toString();
      }

      expect(headersLower.containsKey('authorization'), isFalse);
      expect(headersLower['x-test'], equals('1'));
    });

    test('appends queryParams to request URLs', () async {
      final llmConfig = LLMConfig(
        apiKey: null,
        baseUrl: 'https://api.example.com/v1/',
        model: 'gpt-4o',
        providerOptions: const {
          'openai-compatible': {
            'queryParams': {
              'foo': 'bar',
            },
          },
        },
      );

      final config = OpenAICompatibleConfig.fromLLMConfig(
        llmConfig,
        providerId: 'openai-compatible',
        providerName: 'OpenAI-compatible',
      );

      final client = OpenAIClient(config);
      final adapter = _CapturingHttpClientAdapter();
      client.dio.httpClientAdapter = adapter;

      await client.postJson('chat/completions', {
        'model': 'gpt-4o',
        'messages': const [],
        'stream': false,
      });

      final options = adapter.lastOptions;
      expect(options, isNotNull);
      expect(options!.uri.queryParameters['foo'], equals('bar'));
    });

    test('includeUsage adds stream_options.include_usage=true for streaming',
        () {
      final llmConfig = LLMConfig(
        apiKey: 'k',
        baseUrl: 'https://api.example.com/v1/',
        model: 'gpt-4o',
        providerOptions: const {
          'openai-compatible': {
            'includeUsage': true,
          },
        },
      );

      final config = OpenAICompatibleConfig.fromLLMConfig(
        llmConfig,
        providerId: 'openai-compatible',
        providerName: 'OpenAI-compatible',
      );

      final client = OpenAIClient(config);
      final body = OpenAIRequestBuilder(config).buildChatCompletionsRequestBody(
        client,
        messages: [ChatMessage.user('hi')],
        tools: const [],
        stream: true,
      );

      expect(body['stream_options'], equals(const {'include_usage': true}));
    });

    test(
        'supportsStructuredOutputs=false downgrades json_schema to json_object',
        () {
      final llmConfig = LLMConfig(
        apiKey: 'k',
        baseUrl: 'https://api.example.com/v1/',
        model: 'gpt-4o',
        providerOptions: const {
          'openai-compatible': {
            'supportsStructuredOutputs': false,
            'jsonSchema': StructuredOutputFormat(
              name: 'response',
              schema: {
                'type': 'object',
                'properties': {
                  'answer': {'type': 'string'},
                },
                'required': ['answer'],
              },
            ),
          },
        },
      );

      final config = OpenAICompatibleConfig.fromLLMConfig(
        llmConfig,
        providerId: 'openai-compatible',
        providerName: 'OpenAI-compatible',
      );

      final client = OpenAIClient(config);
      final body = OpenAIRequestBuilder(config).buildChatCompletionsRequestBody(
        client,
        messages: [ChatMessage.user('hi')],
        tools: const [],
        stream: false,
      );

      final responseFormat = body['response_format'] as Map<String, dynamic>?;
      expect(responseFormat, isNotNull);
      expect(responseFormat!['type'], equals('json_object'));
    });
  });
}

class _CapturingHttpClientAdapter implements HttpClientAdapter {
  RequestOptions? lastOptions;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    return ResponseBody.fromString(
      '{"ok": true}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
