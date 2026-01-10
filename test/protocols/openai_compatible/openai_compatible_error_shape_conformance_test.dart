import 'package:dio/dio.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/client.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI-compatible error shape conformance', () {
    test('extracts string error from {"error": "..."}', () async {
      final llmConfig = LLMConfig(
        apiKey: 'k',
        baseUrl: 'https://api.example.com/v1/',
        model: 'gpt-4o',
      );

      final config = OpenAICompatibleConfig.fromLLMConfig(
        llmConfig,
        providerId: 'openai-compatible',
        providerName: 'OpenAI-compatible',
      );

      final client = OpenAIClient(config);
      client.dio.httpClientAdapter = _FixedStatusAdapter(
        statusCode: 400,
        body: '{"error":"something went wrong"}',
      );

      await expectLater(
        () => client.postJson('chat/completions', {
          'model': 'gpt-4o',
          'messages': const [],
          'stream': false,
        }),
        throwsA(
          isA<InvalidRequestError>().having(
            (e) => e.message,
            'message',
            contains('something went wrong'),
          ),
        ),
      );
    });

    test('extracts nested error from {"error": {"error": "..."}}', () async {
      final llmConfig = LLMConfig(
        apiKey: 'k',
        baseUrl: 'https://api.example.com/v1/',
        model: 'gpt-4o',
      );

      final config = OpenAICompatibleConfig.fromLLMConfig(
        llmConfig,
        providerId: 'openai-compatible',
        providerName: 'OpenAI-compatible',
      );

      final client = OpenAIClient(config);
      client.dio.httpClientAdapter = _FixedStatusAdapter(
        statusCode: 400,
        body: '{"error":{"error":"bad request"}}',
      );

      await expectLater(
        () => client.postJson('chat/completions', {
          'model': 'gpt-4o',
          'messages': const [],
          'stream': false,
        }),
        throwsA(
          isA<InvalidRequestError>().having(
            (e) => e.message,
            'message',
            contains('bad request'),
          ),
        ),
      );
    });
  });
}

class _FixedStatusAdapter implements HttpClientAdapter {
  final int statusCode;
  final String body;

  _FixedStatusAdapter({
    required this.statusCode,
    required this.body,
  });

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
