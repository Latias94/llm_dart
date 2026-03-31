import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAIImageModel', () {
    test('OpenAI factory exposes an OpenAI-family image model', () {
      final model = OpenAI(
        apiKey: 'test-key',
        profile: const OpenRouterProfile(),
        transport: const _FakeTransportClient(),
      ).imageModel('dall-e-3');

      expect(model.providerId, 'openrouter');
      expect(model.baseUrl, 'https://openrouter.ai/api/v1');
      expect(
        model.defaultHeaders,
        {'authorization': 'Bearer test-key'},
      );
    });

    test('generateImage sends a request and decodes base64 image output',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'created': 1710000000,
                'size': '1024x1024',
                'quality': 'hd',
                'background': 'transparent',
                'output_format': 'webp',
                'data': [
                  {
                    'b64_json': base64Encode([1, 2, 3, 4]),
                    'revised_prompt': 'A more polished cat prompt.',
                  },
                ],
              },
            );
          },
        ),
      ).imageModel(
        'dall-e-3',
        settings: const OpenAIImageModelSettings(
          organization: 'org_123',
          project: 'proj_456',
          headers: {
            'x-profile': 'image',
          },
        ),
      );

      final result = await generateImage(
        model: model,
        prompt: 'Draw a cat.',
        count: 1,
        size: '1024x1024',
        callOptions: const CallOptions(
          timeout: Duration(seconds: 5),
          headers: {
            'x-request': 'request-header',
          },
          providerOptions: OpenAIImageOptions(
            style: OpenAIImageStyle.vivid,
            quality: OpenAIImageQuality.hd,
            background: OpenAIImageBackground.transparent,
            outputFormat: OpenAIImageOutputFormat.webp,
            user: 'user_123',
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.uri.toString(),
          'https://api.openai.com/v1/images/generations');
      expect(capturedRequest!.method, TransportMethod.post);
      expect(capturedRequest!.timeout, const Duration(seconds: 5));
      expect(
        capturedRequest!.headers,
        {
          'authorization': 'Bearer test-key',
          'openai-organization': 'org_123',
          'openai-project': 'proj_456',
          'x-profile': 'image',
          'content-type': 'application/json',
          'accept': 'application/json',
          'x-request': 'request-header',
        },
      );
      expect(
        capturedRequest!.body,
        {
          'model': 'dall-e-3',
          'prompt': 'Draw a cat.',
          'n': 1,
          'size': '1024x1024',
          'style': 'vivid',
          'quality': 'hd',
          'background': 'transparent',
          'output_format': 'webp',
          'user': 'user_123',
          'response_format': 'b64_json',
        },
      );

      expect(result.images, hasLength(1));
      expect(result.images.single.bytes, [1, 2, 3, 4]);
      expect(result.images.single.mediaType, 'image/webp');
      expect(
        result.providerMetadata?.namespace('openai'),
        {
          'created': 1710000000,
          'size': '1024x1024',
          'quality': 'hd',
          'background': 'transparent',
          'outputFormat': 'webp',
          'responseFormat': 'b64_json',
          'revisedPrompts': ['A more polished cat prompt.'],
        },
      );
    });

    test('gpt-image models omit response_format and can decode url output',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              body: {
                'data': [
                  {
                    'url': 'https://example.com/image.png',
                  },
                ],
              },
            );
          },
        ),
      ).imageModel('gpt-image-1');

      final result = await generateImage(
        model: model,
        prompt: 'Draw a cat.',
      );

      expect(capturedRequest, isNotNull);
      expect(
        (capturedRequest!.body as Map<String, Object?>)
            .containsKey('response_format'),
        isFalse,
      );
      expect(result.images.single.uri?.toString(),
          'https://example.com/image.png');
      expect(result.images.single.bytes, isNull);
    });

    test('image model rejects incompatible provider options', () async {
      final model = OpenAI(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).imageModel('dall-e-3');

      await expectLater(
        () => generateImage(
          model: model,
          prompt: 'Draw a cat.',
          callOptions: const CallOptions(
            providerOptions: OpenAISpeechOptions(),
          ),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('Expected OpenAIImageOptions'),
          ),
        ),
      );
    });
  });
}

typedef _FakeTransportClient = FakeTransportClient;
