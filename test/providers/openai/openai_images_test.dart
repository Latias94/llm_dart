import 'dart:convert';

import 'package:llm_dart/models/image_models.dart';
import 'package:llm_dart/providers/openai/client.dart';
import 'package:llm_dart/providers/openai/config.dart';
import 'package:llm_dart/src/compatibility/providers/openai/images.dart';
import 'package:llm_dart_transport/dio.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAIImages compatibility shell', () {
    test('generateImages keeps JSON request shaping and image parsing',
        () async {
      final client = _FakeOpenAIClient(
        const OpenAIConfig(apiKey: 'test-key', model: 'gpt-image-1'),
      )..jsonResponse = {
          'data': [
            {
              'url': 'https://example.com/image.png',
              'b64_json': base64Encode([1, 2, 3]),
              'revised_prompt': 'Refined prompt',
            },
          ],
        };
      final images = OpenAIImages(client, client.config);

      final response = await images.generateImages(
        const ImageGenerationRequest(
          prompt: 'Draw a lighthouse',
          negativePrompt: 'fog',
          size: '1024x1024',
          count: 2,
          seed: 7,
          steps: 30,
          guidanceScale: 4.5,
          enhancePrompt: true,
          style: 'vivid',
          quality: 'high',
        ),
      );

      expect(client.lastJsonEndpoint, 'images/generations');
      expect(client.lastJsonBody, {
        'model': 'gpt-image-1',
        'prompt': 'Draw a lighthouse',
        'negative_prompt': 'fog',
        'size': '1024x1024',
        'n': 2,
        'seed': 7,
        'num_inference_steps': 30,
        'guidance_scale': 4.5,
        'prompt_enhancement': true,
        'style': 'vivid',
        'quality': 'high',
      });
      expect(response.model, 'gpt-image-1');
      expect(response.revisedPrompt, 'Refined prompt');
      expect(response.images, hasLength(1));
      expect(response.images.single.url, 'https://example.com/image.png');
      expect(response.images.single.data, [1, 2, 3]);
      expect(response.images.single.format, 'png');
    });

    test('editImage keeps multipart field and file shaping', () async {
      final client = _FakeOpenAIClient(
        const OpenAIConfig(apiKey: 'test-key', model: 'gpt-image-1'),
      )..formResponse = {
          'data': [
            {
              'url': 'https://example.com/edit.png',
            },
          ],
        };
      final images = OpenAIImages(client, client.config);

      final response = await images.editImage(
        const ImageEditRequest(
          image: ImageInput(data: [9, 8, 7], format: 'png'),
          mask: ImageInput(data: [6, 5, 4], format: 'png'),
          prompt: 'Add a boat',
          model: 'dall-e-2',
          count: 1,
          size: '512x512',
          responseFormat: 'url',
          user: 'user-1',
        ),
      );

      expect(client.lastFormEndpoint, 'images/edits');
      expect(
        Map<String, String>.fromEntries(client.lastFormData!.fields),
        {
          'prompt': 'Add a boat',
          'model': 'dall-e-2',
          'n': '1',
          'size': '512x512',
          'response_format': 'url',
          'user': 'user-1',
        },
      );
      expect(client.lastFormData!.files, hasLength(2));
      expect(client.lastFormData!.files[0].key, 'image');
      expect(client.lastFormData!.files[1].key, 'mask');
      expect(client.lastFormData!.files[0].value.filename, 'image.png');
      expect(client.lastFormData!.files[1].value.filename, 'mask.png');
      expect(client.lastFormData!.files[0].value.contentType?.mimeType,
          'image/png');
      expect(response.images.single.url, 'https://example.com/edit.png');
    });

    test('createVariation keeps multipart field and file shaping', () async {
      final client = _FakeOpenAIClient(
        const OpenAIConfig(apiKey: 'test-key', model: 'gpt-image-1'),
      )..formResponse = {
          'data': [
            {
              'url': 'https://example.com/variation.png',
            },
          ],
        };
      final images = OpenAIImages(client, client.config);

      final response = await images.createVariation(
        const ImageVariationRequest(
          image: ImageInput(data: [1, 2, 3], format: 'png'),
          model: 'dall-e-2',
          count: 3,
          size: '256x256',
          responseFormat: 'b64_json',
          user: 'user-2',
        ),
      );

      expect(client.lastFormEndpoint, 'images/variations');
      expect(
        Map<String, String>.fromEntries(client.lastFormData!.fields),
        {
          'model': 'dall-e-2',
          'n': '3',
          'size': '256x256',
          'response_format': 'b64_json',
          'user': 'user-2',
        },
      );
      expect(client.lastFormData!.files, hasLength(1));
      expect(client.lastFormData!.files.single.key, 'image');
      expect(response.images.single.url, 'https://example.com/variation.png');
    });
  });
}

final class _FakeOpenAIClient extends OpenAIClient {
  Map<String, dynamic> jsonResponse = const {};
  Map<String, dynamic> formResponse = const {};
  String? lastJsonEndpoint;
  Map<String, dynamic>? lastJsonBody;
  String? lastFormEndpoint;
  FormData? lastFormData;

  _FakeOpenAIClient(super.config);

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> body, {
    cancelToken,
  }) async {
    lastJsonEndpoint = endpoint;
    lastJsonBody = body;
    return jsonResponse;
  }

  @override
  Future<Map<String, dynamic>> postForm(
    String endpoint,
    FormData formData, {
    cancelToken,
  }) async {
    lastFormEndpoint = endpoint;
    lastFormData = formData;
    return formResponse;
  }
}
