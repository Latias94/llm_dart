import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/openai_factory.dart';
import 'package:llm_dart_openai/provider.dart';

void main() {
  group('OpenAI providerMetadata namespacing', () {
    test('chat completions adds openai.chat alias key', () async {
      final adapter = _FakeOpenAIHttpClientAdapter();
      final customDio = Dio()..httpClientAdapter = adapter;

      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o',
      )
          .withProviderOptions('openai', {
            'useResponsesAPI': false,
          })
          .withTransportOptions({'customDio': customDio});

      final factory = OpenAIProviderFactory();
      final provider = factory.create(llmConfig) as OpenAIProvider;

      final response = await provider.chat([ChatMessage.user('hi')]);
      final meta = response.providerMetadata;

      expect(meta, isNotNull);
      expect(meta!.containsKey('openai'), isTrue);
      expect(meta.containsKey('openai.chat'), isTrue);
      expect(meta['openai.chat'], equals(meta['openai']));

      expect(response.usage, isNotNull);
      expect(response.usage!.promptTokens, equals(3));
      expect(response.usage!.completionTokens, equals(4));
      expect(response.usage!.totalTokens, equals(7));
    });

    test('responses api adds openai.responses alias key + normalizes usage', () async {
      final adapter = _FakeOpenAIHttpClientAdapter();
      final customDio = Dio()..httpClientAdapter = adapter;

      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o',
      )
          .withProviderOptions('openai', {
            'useResponsesAPI': true,
          })
          .withTransportOptions({'customDio': customDio});

      final factory = OpenAIProviderFactory();
      final provider = factory.create(llmConfig) as OpenAIProvider;

      final response = await provider.chat([ChatMessage.user('hi')]);
      final meta = response.providerMetadata;

      expect(meta, isNotNull);
      expect(meta!.containsKey('openai'), isTrue);
      expect(meta.containsKey('openai.responses'), isTrue);
      expect(meta['openai.responses'], equals(meta['openai']));

      expect(response.usage, isNotNull);
      expect(response.usage!.promptTokens, equals(11));
      expect(response.usage!.completionTokens, equals(7));
      expect(response.usage!.totalTokens, equals(18));
      expect(response.usage!.reasoningTokens, equals(5));
    });
  });
}

class _FakeOpenAIHttpClientAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;

    if (path.contains('chat/completions')) {
      return ResponseBody.fromString(
        jsonEncode({
          'id': 'chatcmpl_1',
          'object': 'chat.completion',
          'model': 'gpt-4o',
          'system_fingerprint': 'fp_1',
          'choices': [
            {
              'index': 0,
              'message': {'role': 'assistant', 'content': 'hi'},
              'finish_reason': 'stop',
            }
          ],
          'usage': {
            'prompt_tokens': 3,
            'completion_tokens': 4,
            'total_tokens': 7,
          },
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (path.contains('responses')) {
      return ResponseBody.fromString(
        jsonEncode({
          'id': 'resp_1',
          'object': 'response',
          'status': 'completed',
          'model': 'gpt-4o',
          'output': [
            {
              'id': 'msg_1',
              'type': 'message',
              'status': 'completed',
              'role': 'assistant',
              'content': [
                {
                  'type': 'output_text',
                  'text': 'hi',
                  'annotations': [],
                  'logprobs': [],
                }
              ],
            }
          ],
          'usage': {
            'input_tokens': 11,
            'output_tokens': 7,
            'total_tokens': 18,
            'output_tokens_details': {'reasoning_tokens': 5},
          },
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({
        'error': {'message': 'unhandled'},
      }),
      500,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

