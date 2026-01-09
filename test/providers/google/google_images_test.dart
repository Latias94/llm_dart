import 'dart:convert';

import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_google/client.dart';
import 'package:llm_dart_google/images.dart';
import 'package:test/test.dart';

class _CapturingGoogleClient extends GoogleClient {
  final Map<String, Map<String, dynamic>> _responsesByEndpoint;

  String? lastEndpoint;
  Map<String, dynamic>? lastBody;

  _CapturingGoogleClient(
    super.config, {
    required Map<String, Map<String, dynamic>> responsesByEndpoint,
  }) : _responsesByEndpoint = responsesByEndpoint;

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastBody = data;

    final response = _responsesByEndpoint[endpoint];
    if (response == null) {
      throw StateError('No fake response registered for endpoint: $endpoint');
    }
    return response;
  }
}

void main() {
  group('GoogleImages', () {
    test('generateImages uses Imagen API when model contains "imagen"',
        () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-1.5-flash',
      );

      const model = 'imagen-3.0-generate-002';
      final endpoint = 'models/$model:predict';

      final pngBytes1 = <int>[1, 2, 3, 4];
      final pngBytes2 = <int>[5, 6, 7, 8];

      final client = _CapturingGoogleClient(
        config,
        responsesByEndpoint: {
          endpoint: {
            'predictions': [
              {'bytesBase64Encoded': base64Encode(pngBytes1)},
              {'bytesBase64Encoded': base64Encode(pngBytes2)},
            ],
          },
        },
      );

      final images = GoogleImages(client, config);

      final response = await images.generateImages(
        const ImageGenerationRequest(
          prompt: 'A cat wearing sunglasses',
          model: model,
          count: 2,
          size: '1024x1792',
        ),
      );

      expect(client.lastEndpoint, equals(endpoint));
      expect(client.lastBody, isNotNull);

      final body = client.lastBody!;
      final instances = body['instances'] as List;
      expect((instances.single as Map)['prompt'],
          equals('A cat wearing sunglasses'));

      final parameters = body['parameters'] as Map;
      expect(parameters['sampleCount'], equals(2));
      expect(parameters['aspectRatio'], equals('3:4'));
      expect(parameters['personGeneration'], equals('allow_adult'));

      expect(response.model, equals(model));
      expect(response.images, hasLength(2));
      expect(response.images.first.format, equals('png'));
      expect(response.images.first.data, equals(pngBytes1));
      expect(response.images.last.data, equals(pngBytes2));
    });

    test('generateImages uses Gemini API for non-Imagen models', () async {
      const model = 'gemini-2.0-flash-preview-image-generation';
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: model,
        temperature: 0.3,
        topP: 0.9,
        topK: 40,
      );

      final endpoint = 'models/$model:generateContent';
      final webpBytes = <int>[9, 10, 11];

      final client = _CapturingGoogleClient(
        config,
        responsesByEndpoint: {
          endpoint: {
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Revised prompt text'},
                    {
                      'inlineData': {
                        'mimeType': 'image/webp',
                        'data': base64Encode(webpBytes),
                      }
                    },
                  ],
                },
              },
            ],
          },
        },
      );

      final images = GoogleImages(client, config);
      final response = await images.generateImages(
        const ImageGenerationRequest(
          prompt: 'A futuristic city skyline at sunset',
          count: 1,
          size: '1:1',
        ),
      );

      expect(client.lastEndpoint, equals(endpoint));
      final body = client.lastBody!;

      final contents = body['contents'] as List;
      final firstParts = ((contents.single as Map)['parts'] as List);
      expect((firstParts.single as Map)['text'],
          equals('A futuristic city skyline at sunset'));

      final generationConfig = body['generationConfig'] as Map;
      expect(generationConfig['candidateCount'], equals(1));
      expect(generationConfig['temperature'], equals(0.3));
      expect(generationConfig['topP'], equals(0.9));
      expect(generationConfig['topK'], equals(40));
      expect(generationConfig['responseModalities'], equals(['TEXT', 'IMAGE']));

      final imageConfig = generationConfig['imageConfig'] as Map;
      expect(imageConfig['aspectRatio'], equals('1:1'));

      expect(response.model, equals(model));
      expect(response.revisedPrompt, equals('Revised prompt text'));
      expect(response.images, hasLength(1));
      expect(response.images.single.format, equals('webp'));
      expect(response.images.single.data, equals(webpBytes));
      expect(
          response.images.single.revisedPrompt, equals('Revised prompt text'));
    });

    test('editImage sends inlineData and parses Gemini image response',
        () async {
      const model = 'gemini-2.0-flash-preview-image-generation';
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: model,
      );

      final endpoint = 'models/$model:generateContent';
      final inputBytes = <int>[1, 1, 2, 3];
      final outputBytes = <int>[7, 7, 8];

      final client = _CapturingGoogleClient(
        config,
        responsesByEndpoint: {
          endpoint: {
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'inlineData': {
                        'mimeType': 'image/png',
                        'data': base64Encode(outputBytes),
                      }
                    },
                  ],
                },
              },
            ],
          },
        },
      );

      final images = GoogleImages(client, config);
      final response = await images.editImage(
        ImageEditRequest(
          image: ImageInput.fromBytes(inputBytes, format: 'png'),
          prompt: 'Make the image more vibrant',
          count: 1,
        ),
      );

      expect(client.lastEndpoint, equals(endpoint));

      final body = client.lastBody!;
      final contents = body['contents'] as List;
      final parts = ((contents.single as Map)['parts'] as List);
      expect(
          (parts.first as Map)['text'], equals('Make the image more vibrant'));

      final imagePart = parts[1] as Map;
      final inlineData = imagePart['inlineData'] as Map;
      expect(inlineData['mimeType'], equals('image/png'));
      expect(inlineData['data'], equals(base64Encode(inputBytes)));

      final generationConfig = body['generationConfig'] as Map;
      expect(generationConfig['responseModalities'], equals(['TEXT', 'IMAGE']));
      expect(generationConfig['candidateCount'], equals(1));

      expect(response.images, hasLength(1));
      expect(response.images.single.format, equals('png'));
      expect(response.images.single.data, equals(outputBytes));
    });

    test('editImage throws when ImageInput has no data or url', () async {
      final config =
          GoogleConfig(apiKey: 'test-key', model: 'gemini-1.5-flash');
      final client = _CapturingGoogleClient(config, responsesByEndpoint: {});
      final images = GoogleImages(client, config);

      expect(
        () => images.editImage(
          const ImageEditRequest(
            image: ImageInput(),
            prompt: 'Edit this image',
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createVariation throws when ImageInput has no data or url', () async {
      final config =
          GoogleConfig(apiKey: 'test-key', model: 'gemini-1.5-flash');
      final client = _CapturingGoogleClient(config, responsesByEndpoint: {});
      final images = GoogleImages(client, config);

      expect(
        () => images.createVariation(
          const ImageVariationRequest(image: ImageInput()),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('generateImage returns data URLs for generated images', () async {
      const model = 'gemini-2.0-flash-preview-image-generation';
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: model,
      );

      final endpoint = 'models/$model:generateContent';
      final pngBytes = <int>[0, 1, 2];

      final client = _CapturingGoogleClient(
        config,
        responsesByEndpoint: {
          endpoint: {
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'inlineData': {
                        'mimeType': 'image/png',
                        'data': base64Encode(pngBytes),
                      }
                    },
                  ],
                },
              },
            ],
          },
        },
      );

      final images = GoogleImages(client, config);
      final urls = await images.generateImage(prompt: 'A test image');

      expect(urls, hasLength(1));
      expect(urls.single,
          equals('data:image/png;base64,${base64Encode(pngBytes)}'));
    });
  });
}
