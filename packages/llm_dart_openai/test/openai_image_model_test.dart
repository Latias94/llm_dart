import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'dart:convert';

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

    test('image models expose Vercel-aligned max images per call', () {
      final provider = OpenAI(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      );

      expect(provider.imageModel('dall-e-3').maxImagesPerCall, 1);
      expect(provider.imageModel('dall-e-2').maxImagesPerCall, 10);
      expect(provider.imageModel('gpt-image-2').maxImagesPerCall, 10);
      expect(provider.imageModel('unknown-image-model').maxImagesPerCall, 1);
    });

    test('generateImage sends a request and decodes base64 image output',
        () async {
      TransportRequest? capturedRequest;
      final cancelToken = TransportCancellation();

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              headers: const {
                'x-request-id': 'req_image_1',
              },
              body: {
                'created': 1710000000,
                'size': '1024x1024',
                'quality': 'hd',
                'background': 'transparent',
                'output_format': 'webp',
                'usage': {
                  'input_tokens': 12,
                  'output_tokens': 4,
                  'total_tokens': 16,
                  'input_tokens_details': {
                    'image_tokens': 7,
                    'text_tokens': 5,
                  },
                },
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
        callOptions: CallOptions(
          timeout: const Duration(seconds: 5),
          headers: const {
            'x-request': 'request-header',
          },
          cancellation: cancelToken,
          providerOptions: const OpenAIImageOptions(
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
      expect(identical(capturedRequest!.cancellation, cancelToken), isTrue);
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
      expect(result.usage!.inputTokens, 12);
      expect(result.usage!.outputTokens, 4);
      expect(result.usage!.totalTokens, 16);
      expect(result.warnings, isEmpty);
      expect(result.responseMetadata, isNotNull);
      expect(result.responseMetadata!.modelId, 'dall-e-3');
      expect(result.responseMetadata!.timestamp, isA<DateTime>());
      expect(
        result.responseMetadata!.headers,
        containsPair('x-request-id', 'req_image_1'),
      );
      expect(
        result.providerMetadata?.namespace('openai'),
        {
          'images': [
            {
              'revisedPrompt': 'A more polished cat prompt.',
              'created': 1710000000,
              'size': '1024x1024',
              'quality': 'hd',
              'background': 'transparent',
              'outputFormat': 'webp',
              'imageTokens': 7,
              'textTokens': 5,
            },
          ],
          'created': 1710000000,
          'size': '1024x1024',
          'quality': 'hd',
          'background': 'transparent',
          'outputFormat': 'webp',
          'responseFormat': 'b64_json',
          'revisedPrompts': ['A more polished cat prompt.'],
          'usage': {
            'input_tokens': 12,
            'output_tokens': 4,
            'total_tokens': 16,
            'input_tokens_details': {
              'image_tokens': 7,
              'text_tokens': 5,
            },
          },
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

    test('gpt-image-2 omits response_format and maps generation options',
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
                'output_format': 'webp',
                'data': [
                  {
                    'b64_json': base64Encode([9, 8, 7]),
                  },
                ],
              },
            );
          },
        ),
      ).imageModel('gpt-image-2');

      final result = await generateImage(
        model: model,
        prompt: 'Draw a cat.',
        callOptions: const CallOptions(
          providerOptions: OpenAIImageOptions(
            quality: OpenAIImageQuality.high,
            background: OpenAIImageBackground.transparent,
            moderation: OpenAIImageModeration.low,
            outputFormat: OpenAIImageOutputFormat.webp,
            outputCompression: 75,
            user: 'user_123',
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      expect(
        capturedRequest!.body,
        {
          'model': 'gpt-image-2',
          'prompt': 'Draw a cat.',
          'n': 1,
          'quality': 'high',
          'background': 'transparent',
          'moderation': 'low',
          'output_format': 'webp',
          'output_compression': 75,
          'user': 'user_123',
        },
      );
      expect(
        (capturedRequest!.body as Map<String, Object?>)
            .containsKey('response_format'),
        isFalse,
      );
      expect(result.images.single.bytes, [9, 8, 7]);
      expect(result.images.single.mediaType, 'image/webp');
      expect(
        result.providerMetadata?.namespace('openai'),
        {
          'images': [
            {
              'outputFormat': 'webp',
            },
          ],
          'outputFormat': 'webp',
        },
      );
    });

    test('image response metadata distributes token details across images',
        () async {
      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            return TransportResponse(
              statusCode: 200,
              body: {
                'usage': {
                  'input_tokens': 8,
                  'input_tokens_details': {
                    'image_tokens': 5,
                    'text_tokens': 3,
                  },
                },
                'data': [
                  {
                    'b64_json': base64Encode([1]),
                  },
                  {
                    'b64_json': base64Encode([2]),
                  },
                ],
              },
            );
          },
        ),
      ).imageModel('dall-e-2');

      final result = await generateImage(
        model: model,
        prompt: 'Draw two cats.',
        count: 2,
      );

      expect(result.images, hasLength(2));
      expect(result.usage!.inputTokens, 8);
      expect(
        result.providerMetadata?.namespace('openai')?['images'],
        [
          {
            'imageTokens': 2,
            'textTokens': 1,
          },
          {
            'imageTokens': 3,
            'textTokens': 2,
          },
        ],
      );
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

    test('image generation rejects invalid output compression', () async {
      final model = OpenAI(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).imageModel('gpt-image-2');

      await expectLater(
        () => generateImage(
          model: model,
          prompt: 'Draw a cat.',
          callOptions: const CallOptions(
            providerOptions: OpenAIImageOptions(
              outputCompression: 101,
            ),
          ),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('between 0 and 100'),
          ),
        ),
      );
    });

    test('image generation rejects counts above the model limit', () async {
      final model = OpenAI(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).imageModel('dall-e-3');

      await expectLater(
        () => generateImage(
          model: model,
          prompt: 'Draw two cats.',
          count: 2,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('at most 1 generated images per call'),
          ),
        ),
      );
    });

    test('edit sends multipart data and decodes edited image output', () async {
      TransportRequest? capturedRequest;
      final cancelToken = TransportCancellation();

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'created': 1710000001,
                'output_format': 'webp',
                'data': [
                  {
                    'b64_json': base64Encode(utf8.encode('edited-image')),
                    'revised_prompt': 'A more polished edited cat prompt.',
                  },
                ],
                'usage': {
                  'input_tokens': 12,
                },
              },
            );
          },
        ),
      ).imageModel(
        'gpt-image-1',
        settings: const OpenAIImageModelSettings(
          organization: 'org_123',
          project: 'proj_456',
          headers: {
            'x-profile': 'image-edit',
          },
        ),
      );

      final result = await model.edit(
        OpenAIImageEditRequest(
          prompt: 'Turn this cat into a watercolor postcard.',
          images: [
            OpenAIImageEditInput(
              bytes: utf8.encode('image-bytes'),
              mediaType: 'image/png',
            ),
          ],
          mask: OpenAIImageEditInput(
            bytes: utf8.encode('mask-bytes'),
            mediaType: 'image/png',
          ),
          count: 2,
          size: '1024x1024',
          inputFidelity: OpenAIImageInputFidelity.high,
          partialImages: 2,
          outputCompression: 80,
          callOptions: CallOptions(
            timeout: const Duration(seconds: 5),
            headers: const {
              'x-request': 'request-header',
            },
            cancellation: cancelToken,
            providerOptions: const OpenAIImageOptions(
              background: OpenAIImageBackground.transparent,
              quality: OpenAIImageQuality.high,
              outputFormat: OpenAIImageOutputFormat.webp,
              responseFormat: OpenAIImageResponseFormat.base64Json,
              user: 'user_123',
            ),
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.uri.toString(),
          'https://api.openai.com/v1/images/edits');
      expect(capturedRequest!.method, TransportMethod.post);
      expect(capturedRequest!.responseType, TransportResponseType.json);
      expect(capturedRequest!.timeout, const Duration(seconds: 5));
      expect(identical(capturedRequest!.cancellation, cancelToken), isTrue);
      expect(capturedRequest!.headers['authorization'], 'Bearer test-key');
      expect(capturedRequest!.headers['openai-organization'], 'org_123');
      expect(capturedRequest!.headers['openai-project'], 'proj_456');
      expect(capturedRequest!.headers['x-profile'], 'image-edit');
      expect(capturedRequest!.headers['x-request'], 'request-header');
      expect(capturedRequest!.headers['accept'], 'application/json');
      expect(
        capturedRequest!.headers['content-type'],
        startsWith('multipart/form-data; boundary='),
      );

      final bodyText = utf8.decode(capturedRequest!.body! as List<int>);
      expect(bodyText, contains('name="model"'));
      expect(bodyText, contains('gpt-image-1'));
      expect(bodyText, contains('name="prompt"'));
      expect(bodyText, contains('Turn this cat into a watercolor postcard.'));
      expect(bodyText, contains('name="image"; filename="image.png"'));
      expect(bodyText, contains('image-bytes'));
      expect(bodyText, contains('name="mask"; filename="mask.png"'));
      expect(bodyText, contains('mask-bytes'));
      expect(bodyText, contains('name="n"'));
      expect(bodyText, contains('name="size"'));
      expect(bodyText, contains('1024x1024'));
      expect(bodyText, contains('name="background"'));
      expect(bodyText, contains('transparent'));
      expect(bodyText, contains('name="input_fidelity"'));
      expect(bodyText, contains('high'));
      expect(bodyText, contains('name="partial_images"'));
      expect(bodyText, contains('name="quality"'));
      expect(bodyText, contains('name="output_compression"'));
      expect(bodyText, contains('name="output_format"'));
      expect(bodyText, contains('webp'));
      expect(bodyText, contains('name="response_format"'));
      expect(bodyText, contains('b64_json'));
      expect(bodyText, contains('name="user"'));
      expect(bodyText, contains('user_123'));

      expect(result.images, hasLength(1));
      expect(result.images.single.bytes, utf8.encode('edited-image'));
      expect(result.images.single.mediaType, 'image/webp');
      expect(result.usage!.inputTokens, 12);
      expect(result.responseMetadata, isNotNull);
      expect(result.responseMetadata!.modelId, 'gpt-image-1');
      expect(
        result.providerMetadata?.namespace('openai'),
        {
          'images': [
            {
              'revisedPrompt': 'A more polished edited cat prompt.',
              'created': 1710000001,
              'outputFormat': 'webp',
            },
          ],
          'created': 1710000001,
          'outputFormat': 'webp',
          'responseFormat': 'b64_json',
          'revisedPrompts': ['A more polished edited cat prompt.'],
          'usage': {
            'input_tokens': 12,
          },
        },
      );
    });

    test('edit rejects generation-only style options', () async {
      final model = OpenAI(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).imageModel('gpt-image-1');

      await expectLater(
        () => model.edit(
          OpenAIImageEditRequest(
            prompt: 'Edit this image.',
            images: const [
              OpenAIImageEditInput(
                bytes: [1, 2, 3],
                mediaType: 'image/png',
              ),
            ],
            callOptions: const CallOptions(
              providerOptions: OpenAIImageOptions(
                style: OpenAIImageStyle.vivid,
              ),
            ),
          ),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('only supported for image generation'),
          ),
        ),
      );
    });

    test('edit rejects non-image inputs', () async {
      final model = OpenAI(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).imageModel('gpt-image-1');

      await expectLater(
        () => model.edit(
          const OpenAIImageEditRequest(
            prompt: 'Edit this image.',
            images: [
              OpenAIImageEditInput(
                bytes: [1, 2, 3],
                mediaType: 'application/pdf',
              ),
            ],
          ),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('image/* media type'),
          ),
        ),
      );
    });
  });
}

typedef _FakeTransportClient = FakeTransportClient;
