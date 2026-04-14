import 'dart:convert';

import 'package:llm_dart/core/cancellation.dart';
import 'package:llm_dart/models/image_models.dart';
import 'package:llm_dart/providers/google/config.dart';
import 'package:llm_dart/src/compatibility/providers/google/client.dart';
import 'package:llm_dart/src/compatibility/providers/google/google_image_support.dart';
import 'package:llm_dart/src/compatibility/providers/google/images.dart';
import 'package:test/test.dart';

void main() {
  group('GoogleImages', () {
    test('Imagen generation keeps predict request shaping and response parsing',
        () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'imagen-3.0-generate-002',
      );
      final client = _FakeGoogleClient(
        config,
        response: {
          'predictions': [
            {
              'bytesBase64Encoded': base64Encode([1, 2, 3]),
            },
          ],
        },
      );
      final images = GoogleImages(client, config);

      final response = await images.generateImages(
        const ImageGenerationRequest(
          prompt: 'Draw a lighthouse',
          count: 2,
          size: '1536x640',
        ),
      );

      expect(client.lastEndpoint, 'models/imagen-3.0-generate-002:predict');
      expect(client.lastBody, {
        'instances': [
          {
            'prompt': 'Draw a lighthouse',
          },
        ],
        'parameters': {
          'sampleCount': 2,
          'aspectRatio': '16:9',
          'personGeneration': 'allow_adult',
        },
      });
      expect(response.model, 'imagen-3.0-generate-002');
      expect(response.images, hasLength(1));
      expect(response.images.single.data, [1, 2, 3]);
      expect(response.images.single.format, 'png');
    });

    test('Gemini generation keeps request shaping and revised prompt parsing',
        () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-2.0-flash-preview-image-generation',
        responseModalities: const ['TEXT', 'IMAGE'],
        safetySettings: const [
          SafetySetting(
            category: HarmCategory.harmCategoryDangerousContent,
            threshold: HarmBlockThreshold.blockOnlyHigh,
          ),
        ],
      );
      final client = _FakeGoogleClient(
        config,
        response: {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': 'Refined lighthouse prompt',
                  },
                  {
                    'inlineData': {
                      'mimeType': 'image/webp',
                      'data': base64Encode([4, 5, 6]),
                    },
                  },
                ],
              },
            },
          ],
        },
      );
      final images = GoogleImages(client, config);

      final response = await images.generateImages(
        const ImageGenerationRequest(
          prompt: 'Draw a lighthouse',
          count: 1,
          size: '1:1',
        ),
      );

      expect(
        client.lastEndpoint,
        'models/gemini-2.0-flash-preview-image-generation:generateContent',
      );
      expect(client.lastBody, {
        'contents': [
          {
            'parts': [
              {'text': 'Draw a lighthouse'},
            ],
          },
        ],
        'generationConfig': {
          'responseModalities': ['TEXT', 'IMAGE'],
          'imageConfig': {
            'aspectRatio': '1:1',
          },
          'candidateCount': 1,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_ONLY_HIGH',
          },
        ],
      });
      expect(response.revisedPrompt, 'Refined lighthouse prompt');
      expect(response.images, hasLength(1));
      expect(response.images.single.data, [4, 5, 6]);
      expect(response.images.single.format, 'webp');
    });

    test('Image variation reuses shared Gemini inline-image request shaping',
        () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-2.0-flash-preview-image-generation',
      );
      final client = _FakeGoogleClient(
        config,
        response: {
          'candidates': [
            {
              'content': {
                'parts': [
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
      final images = GoogleImages(client, config);

      final response = await images.createVariation(
        const ImageVariationRequest(
          image: ImageInput(data: [9, 8, 7], format: 'png'),
          count: 2,
        ),
      );
      final lastBody = client.lastBody!;
      final parts = ((lastBody['contents'] as List).single
          as Map<String, dynamic>)['parts'];

      expect(
        client.lastEndpoint,
        'models/gemini-2.0-flash-preview-image-generation:generateContent',
      );
      expect(parts, [
        {'text': GoogleImageSupport.variationPrompt},
        {
          'inlineData': {
            'mimeType': 'image/png',
            'data': base64Encode([9, 8, 7]),
          },
        },
      ]);
      expect(
        lastBody['generationConfig'],
        {
          'responseModalities': ['TEXT', 'IMAGE'],
          'candidateCount': 2,
        },
      );
      expect(response.images.single.data, [7, 8, 9]);
    });
  });
}

final class _FakeGoogleClient extends GoogleClient {
  final Map<String, dynamic> response;
  String? lastEndpoint;
  Map<String, dynamic>? lastBody;

  _FakeGoogleClient(
    super.config, {
    required this.response,
  });

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    TransportCancellation? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastBody = data;
    return response;
  }
}
