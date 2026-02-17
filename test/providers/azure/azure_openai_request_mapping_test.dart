import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_azure/azure_factory.dart';
import 'package:llm_dart_azure/provider.dart';

void main() {
  group('Azure OpenAI request mapping', () {
    test('v1 base URL: images + audio include api-version and api-key',
        () async {
      final adapter = _CapturingHttpClientAdapter();
      final customDio = Dio()..httpClientAdapter = adapter;

      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://example.openai.azure.com/openai',
        model: 'deployment_1',
      ).withProviderOptions('azure', {
        'apiVersion': '2024-10-01-preview',
        'useDeploymentBasedUrls': false,
      }).withTransportOptions({'customDio': customDio});

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

      await provider.speechToText(
        const STTRequest(audioData: [1, 2, 3]),
      );

      final sttRequest = adapter.lastRequest;
      expect(sttRequest, isNotNull);
      expect(sttRequest!.method.toUpperCase(), equals('POST'));
      expect(
        sttRequest.uri.toString(),
        contains('/openai/v1/audio/transcriptions'),
      );
      expect(
        sttRequest.uri.queryParameters['api-version'],
        equals('2024-10-01-preview'),
      );

      await provider.translateAudio(
        const AudioTranslationRequest(audioData: [1, 2, 3]),
      );

      final translationRequest = adapter.lastRequest;
      expect(translationRequest, isNotNull);
      expect(translationRequest!.method.toUpperCase(), equals('POST'));
      expect(
        translationRequest.uri.toString(),
        contains('/openai/v1/audio/translations'),
      );
      expect(
        translationRequest.uri.queryParameters['api-version'],
        equals('2024-10-01-preview'),
      );
    });

    test('v1 base URL: responses include api-version', () async {
      final adapter = _CapturingHttpClientAdapter();
      final customDio = Dio()..httpClientAdapter = adapter;

      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://example.openai.azure.com/openai',
        model: 'deployment_1',
      ).withProviderOptions('azure', {
        'apiVersion': '2024-10-01-preview',
        'useDeploymentBasedUrls': false,
      }).withTransportOptions({'customDio': customDio});

      final factory = AzureOpenAIProviderFactory();
      final provider = factory.create(llmConfig) as AzureOpenAIProvider;

      await provider.chat([ChatMessage.user('hi')]);

      final req = adapter.lastRequest;
      expect(req, isNotNull);
      expect(req!.headers['api-key'], equals('test-key'));
      expect(req.headers.containsKey('Authorization'), isFalse);
      expect(req.uri.toString(), contains('/openai/v1/responses'));
      expect(
        req.uri.queryParameters['api-version'],
        equals('2024-10-01-preview'),
      );
    });

    test('v1 base URL: per-call providerTools serialize into Responses tools',
        () async {
      final adapter = _CapturingHttpClientAdapter();
      final customDio = Dio()..httpClientAdapter = adapter;

      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://example.openai.azure.com/openai',
        model: 'deployment_1',
      ).withProviderOptions('azure', {
        'apiVersion': '2024-10-01-preview',
        'useDeploymentBasedUrls': false,
      }).withTransportOptions({'customDio': customDio});

      final factory = AzureOpenAIProviderFactory();
      final provider = factory.create(llmConfig) as AzureOpenAIProvider;

      await provider.chat(
        [ChatMessage.user('hi')],
        providerTools: const [
          ProviderTool(
            id: 'azure.web_search_preview',
            options: {'searchContextSize': 'high'},
          ),
        ],
      );

      final req = adapter.lastRequest;
      expect(req, isNotNull);
      expect(req!.uri.toString(), contains('/openai/v1/responses'));

      final body = req.data as Map;
      final tools =
          (body['tools'] as List?)?.whereType<Map>().toList() ?? const [];
      expect(tools.any((t) => t['type'] == 'web_search_preview'), isTrue);

      final web = tools.firstWhere((t) => t['type'] == 'web_search_preview');
      expect(web['search_context_size'], equals('high'));
    });

    test('v1 base URL: prompt IR (responses) groups multi-part message',
        () async {
      final adapter = _CapturingHttpClientAdapter();
      final customDio = Dio()..httpClientAdapter = adapter;

      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://example.openai.azure.com/openai',
        model: 'deployment_1',
      ).withProviderOptions('azure', {
        'apiVersion': '2024-10-01-preview',
        'useDeploymentBasedUrls': false,
      }).withTransportOptions({'customDio': customDio});

      final factory = AzureOpenAIProviderFactory();
      final provider = factory.create(llmConfig) as AzureOpenAIProvider;

      final prompt = Prompt(
        messages: [
          PromptMessage(
            role: PromptRole.user,
            parts: [
              const TextPart('Describe this image:'),
              ImagePart(
                mime: ImageMime.png,
                data: const [1, 2, 3],
                text: 'A small icon.',
              ),
            ],
          ),
        ],
      );

      await provider.chatPrompt(prompt);

      final req = adapter.lastRequest;
      expect(req, isNotNull);
      expect(req!.uri.toString(), contains('/openai/v1/responses'));
      expect(
          req.uri.queryParameters['api-version'], equals('2024-10-01-preview'));

      final body = req.data as Map;
      expect(body['model'], equals('deployment_1'));

      final input = body['input'] as List;
      expect(input, hasLength(1));
      final msg = input.single as Map;
      expect(msg['role'], equals('user'));
      final content = msg['content'] as List;
      expect(content, hasLength(3));
      expect(content[0],
          equals({'type': 'input_text', 'text': 'Describe this image:'}));
      expect(
          content[1], equals({'type': 'input_text', 'text': 'A small icon.'}));
      expect((content[2] as Map)['type'], equals('input_image'));
      expect((content[2] as Map)['image_url'], isA<String>());
    });

    test('deployment-based URL: images include deployments/{deployment}',
        () async {
      final adapter = _CapturingHttpClientAdapter();
      final customDio = Dio()..httpClientAdapter = adapter;

      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://example.openai.azure.com/openai',
        model: 'deployment_1',
      ).withProviderOptions('azure', {
        'apiVersion': '2024-10-01-preview',
        'useDeploymentBasedUrls': true,
      }).withTransportOptions({'customDio': customDio});

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

    test('deployment-based URL: responses include deployments/{deployment}',
        () async {
      final adapter = _CapturingHttpClientAdapter();
      final customDio = Dio()..httpClientAdapter = adapter;

      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://example.openai.azure.com/openai',
        model: 'deployment_1',
      ).withProviderOptions('azure', {
        'apiVersion': '2024-10-01-preview',
        'useDeploymentBasedUrls': true,
      }).withTransportOptions({'customDio': customDio});

      final factory = AzureOpenAIProviderFactory();
      final provider = factory.create(llmConfig) as AzureOpenAIProvider;

      await provider.chat([ChatMessage.user('hi')]);

      final req = adapter.lastRequest;
      expect(req, isNotNull);
      expect(req!.uri.toString(),
          contains('/openai/deployments/deployment_1/responses'));
      expect(
        req.uri.queryParameters['api-version'],
        equals('2024-10-01-preview'),
      );
    });

    test('deployment-based URL: audio includes deployments/{deployment}',
        () async {
      final adapter = _CapturingHttpClientAdapter();
      final customDio = Dio()..httpClientAdapter = adapter;

      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://example.openai.azure.com/openai',
        model: 'deployment_1',
      ).withProviderOptions('azure', {
        'apiVersion': '2024-10-01-preview',
        'useDeploymentBasedUrls': true,
      }).withTransportOptions({'customDio': customDio});

      final factory = AzureOpenAIProviderFactory();
      final provider = factory.create(llmConfig) as AzureOpenAIProvider;

      await provider.textToSpeech(
        const TTSRequest(text: 'hello'),
      );

      final req = adapter.lastRequest;
      expect(req, isNotNull);
      expect(
        req!.uri.toString(),
        contains('/openai/deployments/deployment_1/audio/speech'),
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

    if (options.path.endsWith('responses')) {
      return ResponseBody.fromString(
        jsonEncode({
          'id': 'resp_1',
          'output_text': 'ok',
          'output': const [],
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
