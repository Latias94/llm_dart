import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_google/llm_dart_google.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('GoogleImageModel', () {
    test('Google factory exposes a Google image model', () {
      final model = Google(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).imageModel('imagen-3.0-generate-002');

      expect(model.providerId, 'google');
      expect(model.baseUrl, Google.defaultBaseUrl);
      expect(model.maxImagesPerCall, 4);
    });

    test('Imagen image model sends a predict request and decodes images',
        () async {
      TransportRequest? capturedRequest;

      final model = Google(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'predictions': [
                  {
                    'bytesBase64Encoded': base64Encode([1, 2, 3]),
                  },
                  {
                    'bytesBase64Encoded': base64Encode([4, 5, 6]),
                  },
                ],
              },
            );
          },
        ),
      ).imageModel(
        'imagen-3.0-generate-002',
        settings: const GoogleImageModelSettings(
          headers: {
            'x-settings': '1',
          },
        ),
      );

      final result = await generateImage(
        model: model,
        prompt: 'Draw a cat.',
        count: 2,
        callOptions: const CallOptions(
          timeout: Duration(seconds: 5),
          headers: {
            'x-call': '2',
          },
          providerOptions: GoogleImageOptions(
            aspectRatio: GoogleImageAspectRatio.landscape16x9,
            personGeneration: GooglePersonGeneration.allowAdult,
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      expect(
        capturedRequest!.uri.toString(),
        'https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-002:predict',
      );
      expect(capturedRequest!.headers, {
        'x-goog-api-key': 'test-key',
        'content-type': 'application/json',
        'accept': 'application/json',
        'x-settings': '1',
        'x-call': '2',
      });
      expect(capturedRequest!.timeout, const Duration(seconds: 5));
      expect(
        capturedRequest!.body,
        {
          'instances': [
            {
              'prompt': 'Draw a cat.',
            },
          ],
          'parameters': {
            'sampleCount': 2,
            'aspectRatio': '16:9',
            'personGeneration': 'allow_adult',
          },
        },
      );
      expect(result.images, hasLength(2));
      expect(result.images.first.bytes, [1, 2, 3]);
      expect(result.images.first.mediaType, 'image/png');
      expect(
        result.providerMetadata?.namespace('google'),
        {
          'generationApi': 'predict',
        },
      );
    });

    test('Gemini image model uses generateContent and decodes inline data',
        () async {
      TransportRequest? capturedRequest;

      final model = Google(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'modelVersion': 'gemini-2.5-flash-image',
                'usageMetadata': {
                  'promptTokenCount': 12,
                  'totalTokenCount': 16,
                },
                'candidates': [
                  {
                    'finishReason': 'STOP',
                    'content': {
                      'parts': [
                        {
                          'text': 'A refined cat prompt.',
                        },
                        {
                          'inlineData': {
                            'mimeType': 'image/png',
                            'data': base64Encode([7, 8, 9]),
                          },
                        },
                      ],
                    },
                  },
                ],
              },
            );
          },
        ),
      ).imageModel('gemini-2.5-flash-image');

      final result = await generateImage(
        model: model,
        prompt: 'Draw a cat.',
        callOptions: const CallOptions(
          providerOptions: GoogleImageOptions(
            aspectRatio: GoogleImageAspectRatio.square1x1,
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      expect(
        capturedRequest!.uri.toString(),
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent',
      );
      expect(
        capturedRequest!.body,
        {
          'contents': [
            {
              'parts': [
                {
                  'text': 'Draw a cat.',
                },
              ],
            },
          ],
          'generationConfig': {
            'responseModalities': ['TEXT', 'IMAGE'],
            'imageConfig': {
              'aspectRatio': '1:1',
            },
          },
        },
      );
      expect(result.images, hasLength(1));
      expect(result.images.single.bytes, [7, 8, 9]);
      expect(
        result.providerMetadata?.namespace('google'),
        {
          'generationApi': 'generateContent',
          'modelVersion': 'gemini-2.5-flash-image',
          'usage': {
            'promptTokenCount': 12,
            'totalTokenCount': 16,
          },
          'revisedPrompts': ['A refined cat prompt.'],
          'finishReasons': ['STOP'],
        },
      );
    });

    test('Gemini image model forwards safety settings from typed options',
        () async {
      TransportRequest? capturedRequest;

      final model = Google(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'candidates': [
                  {
                    'content': {
                      'parts': [
                        {
                          'inlineData': {
                            'mimeType': 'image/png',
                            'data': base64Encode([1, 2, 3]),
                          },
                        },
                      ],
                    },
                  },
                ],
              },
            );
          },
        ),
      ).imageModel(
        'gemini-2.5-flash-image',
        settings: const GoogleImageModelSettings(
          safetySettings: [
            GoogleSafetySetting(
              category: GoogleHarmCategory.harassment,
              threshold: GoogleHarmBlockThreshold.blockOnlyHigh,
            ),
          ],
        ),
      );

      await generateImage(
        model: model,
        prompt: 'Draw a cat.',
        callOptions: const CallOptions(
          providerOptions: GoogleImageOptions(
            safetySettings: [
              GoogleSafetySetting(
                category: GoogleHarmCategory.dangerousContent,
                threshold: GoogleHarmBlockThreshold.blockMediumAndAbove,
              ),
            ],
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      expect(
        capturedRequest!.body,
        {
          'contents': [
            {
              'parts': [
                {
                  'text': 'Draw a cat.',
                },
              ],
            },
          ],
          'generationConfig': {
            'responseModalities': ['TEXT', 'IMAGE'],
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
          ],
        },
      );
    });

    test('Google image model rejects request.size', () async {
      final model = Google(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).imageModel('imagen-3.0-generate-002');

      await expectLater(
        () => generateImage(
          model: model,
          prompt: 'Draw a cat.',
          size: '1024x1024',
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('GoogleImageOptions.aspectRatio'),
          ),
        ),
      );
    });

    test('Gemini image models reject multi-image generation', () async {
      final model = Google(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).imageModel('gemini-2.5-flash-image');

      await expectLater(
        () => generateImage(
          model: model,
          prompt: 'Draw a cat.',
          count: 2,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('only count=1'),
          ),
        ),
      );
    });

    test('image model rejects incompatible provider options', () async {
      final model = Google(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).imageModel('imagen-3.0-generate-002');

      await expectLater(
        () => generateImage(
          model: model,
          prompt: 'Draw a cat.',
          callOptions: const CallOptions(
            providerOptions: GoogleEmbedOptions(),
          ),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('Expected GoogleImageOptions'),
          ),
        ),
      );
    });

    test('Imagen image models reject Gemini safety settings', () async {
      final model = Google(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).imageModel(
        'imagen-3.0-generate-002',
        settings: const GoogleImageModelSettings(
          safetySettings: [
            GoogleSafetySetting(
              category: GoogleHarmCategory.harassment,
              threshold: GoogleHarmBlockThreshold.blockOnlyHigh,
            ),
          ],
        ),
      );

      await expectLater(
        () => generateImage(
          model: model,
          prompt: 'Draw a cat.',
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('Imagen safety filters are not configurable'),
          ),
        ),
      );
    });
  });
}

typedef _FakeTransportClient = FakeTransportClient;
