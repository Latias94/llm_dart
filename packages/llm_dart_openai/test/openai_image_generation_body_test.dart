import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_openai/src/openai_image_generation_body.dart';
import 'package:llm_dart_openai/src/openai_image_options.dart';
import 'package:llm_dart_openai/src/openai_image_types.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI image generation body projection', () {
    test('maps generation options to OpenAI JSON fields', () {
      final body = buildOpenAIImageGenerationRequestBody(
        modelId: 'dall-e-3',
        request: ImageGenerationRequest(
          prompt: 'Draw a cat.',
          count: 1,
          size: '1024x1024',
          callOptions: CallOptions(
            providerOptions: OpenAIImageOptions(
              style: OpenAIImageStyle.vivid,
              quality: OpenAIImageQuality.hd,
              background: OpenAIImageBackground.transparent,
              moderation: OpenAIImageModeration.low,
              outputFormat: OpenAIImageOutputFormat.webp,
              outputCompression: 75,
              user: 'user_123',
            ),
          ),
        ),
        options: const OpenAIImageOptions(
          style: OpenAIImageStyle.vivid,
          quality: OpenAIImageQuality.hd,
          background: OpenAIImageBackground.transparent,
          moderation: OpenAIImageModeration.low,
          outputFormat: OpenAIImageOutputFormat.webp,
          outputCompression: 75,
          user: 'user_123',
        ),
      );

      expect(
        body,
        {
          'model': 'dall-e-3',
          'prompt': 'Draw a cat.',
          'n': 1,
          'size': '1024x1024',
          'style': 'vivid',
          'quality': 'hd',
          'background': 'transparent',
          'moderation': 'low',
          'output_format': 'webp',
          'output_compression': 75,
          'user': 'user_123',
          'response_format': 'b64_json',
        },
      );
    });

    test('omits response_format for gpt-image models', () {
      final body = buildOpenAIImageGenerationRequestBody(
        modelId: 'gpt-image-2',
        request: ImageGenerationRequest(
          prompt: 'Draw a cat.',
          count: 1,
        ),
        options: null,
      );

      expect(body.containsKey('response_format'), isFalse);
    });
  });
}
