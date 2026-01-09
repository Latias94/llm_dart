import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_azure/azure_factory.dart';
import 'package:llm_dart_azure/provider.dart';

void main() {
  group('Azure OpenAI request mapping', () {
    test('v1 base URL: images + audio include api-version and api-key', () async {
      final adapter = _CapturingHttpClientAdapter();
      final customDio = Dio()..httpClientAdapter = adapter;

      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://example.openai.azure.com/openai',
        model: 'deployment_1',
      )
          .withProviderOptions('azure', {
            'apiVersion': '2024-10-01-preview',
            'useDeploymentBasedUrls': false,
          })
          .withTransportOptions({'customDio': customDio});

      final factory = AzureOpenAIProviderFactory();
      final provider = factory.create(llmConfig) as AzureOpenAIProvider;

      await provider.generateImages(
        const ImageGenerationRequest(prompt: 'hi'),
      );

      final imageRequest = adapter.lastRequest;
      expect(imageRequest, isNotNull);
      expect(imageRequest!.method.toUpperCase(), equals('POST'));
      expect(imageRequest.headers['api-key'], equals('test-key'));
      expect(imageRequest.headers.containsKey('Authorization'), isFalse);
      expect(
        imageRequest.uri.toString(),
        contains('/openai/v1/images/generations'),
      );
      expect(
        imageRequest.uri.queryParameters['api-version'],
        equals('2024-10-01-preview'),
      );
      expect((imageRequest.data as Map)['model'], equals('deployment_1'));

      await provider.textToSpeech(
        const TTSRequest(text: 'hello'),
      );

      final ttsRequest = adapter.lastRequest;
      expect(ttsRequest, isNotNull);
      expect(ttsRequest!.method.toUpperCase(), equals('POST'));
      expect(
        ttsRequest.uri.toString(),
        contains('/openai/v1/audio/speech'),
      );
      expect(
        ttsRequest.uri.queryParameters['api-version'],
        equals('2024-10-01-preview'),
      );
    });

    test('deployment-based URL: images include deployments/{deployment}', () async {
      final adapter = _CapturingHttpClientAdapter();
      final customDio = Dio()..httpClientAdapter = adapter;

      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://example.openai.azure.com/openai',
        model: 'deployment_1',
      )
          .withProviderOptions('azure', {
            'apiVersion': '2024-10-01-preview',
            'useDeploymentBasedUrls': true,
          })
          .withTransportOptions({'customDio': customDio});

      final factory = AzureOpenAIProviderFactory();
      final provider = factory.create(llmConfig) as AzureOpenAIProvider;

      await provider.generateImages(
        const ImageGenerationRequest(prompt: 'hi'),
      );

      final req = adapter.lastRequest;
      expect(req, isNotNull);
      expect(
        req!.uri.toString(),
        contains('/openai/deployments/deployment_1/images/generations'),
      );
      expect(
        req.uri.queryParameters['api-version'],
        equals('2024-10-01-preview'),
      );
    });
  });
}

class _CapturingHttpClientAdapter implements HttpClientAdapter {
  RequestOptions? lastRequest;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;

    if (options.responseType == ResponseType.bytes) {
      return ResponseBody.fromBytes(
        const [0, 1, 2],
        200,
        headers: {
          Headers.contentTypeHeader: ['application/octet-stream'],
        },
      );
    }

    if (options.path.endsWith('images/generations')) {
      return ResponseBody.fromString(
        jsonEncode({
          'data': [
            {'url': 'https://example.com/image.png'}
          ],
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'text': 'ok'}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
