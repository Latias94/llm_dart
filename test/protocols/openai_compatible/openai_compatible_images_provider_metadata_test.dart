import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:test/test.dart';

import '../../utils/fakes/openai_fake_client.dart';

void main() {
  group('OpenAI-compatible images providerMetadata', () {
    test('generateImages attaches endpoint + model providerMetadata', () async {
      final config = OpenAICompatibleConfig(
        providerId: 'deepseek',
        providerName: 'DeepSeek',
        apiKey: 'test-key',
        baseUrl: 'https://api.example.com/v1/',
        model: 'gpt-image-1',
      );

      final client = FakeOpenAIClient(config);
      client.jsonResponse = const {
        'data': [
          {
            'url': 'https://example.com/image.png',
            'revised_prompt': 'rp',
          },
        ],
      };

      final images = OpenAIStyleImages(client, config);

      final resp = await images.generateImages(
        const ImageGenerationRequest(
          prompt: 'hi',
          model: 'gpt-image-1',
        ),
      );

      expect(client.lastEndpoint, 'images/generations');
      expect(resp.model, 'gpt-image-1');

      final meta = resp.providerMetadata;
      expect(meta, isNotNull);
      expect(meta!.containsKey('deepseek'), isTrue);
      expect(meta.containsKey('deepseek.image'), isTrue);
      expect(
        meta['deepseek.image'],
        equals({
          'model': 'gpt-image-1',
          'endpoint': 'images/generations',
        }),
      );
    });

    test('editImage attaches endpoint + model providerMetadata', () async {
      final config = OpenAICompatibleConfig(
        providerId: 'deepseek',
        providerName: 'DeepSeek',
        apiKey: 'test-key',
        baseUrl: 'https://api.example.com/v1/',
        model: 'gpt-image-1',
      );

      final client = FakeOpenAIClient(config);
      client.formResponse = const {
        'data': [
          {
            'url': 'https://example.com/image.png',
            'revised_prompt': 'rp',
          },
        ],
      };

      final images = OpenAIStyleImages(client, config);

      final resp = await images.editImage(
        ImageEditRequest(
          image: const ImageInput(data: [1, 2, 3], format: 'png'),
          prompt: 'edit',
          model: 'gpt-image-1',
        ),
      );

      expect(client.lastEndpoint, 'images/edits');
      expect(resp.model, 'gpt-image-1');

      final meta = resp.providerMetadata;
      expect(meta, isNotNull);
      expect(meta!.containsKey('deepseek'), isTrue);
      expect(meta.containsKey('deepseek.image'), isTrue);
      expect(
        meta['deepseek.image'],
        equals({
          'model': 'gpt-image-1',
          'endpoint': 'images/edits',
        }),
      );
    });

    test('createVariation attaches endpoint + model providerMetadata',
        () async {
      final config = OpenAICompatibleConfig(
        providerId: 'deepseek',
        providerName: 'DeepSeek',
        apiKey: 'test-key',
        baseUrl: 'https://api.example.com/v1/',
        model: 'gpt-image-1',
      );

      final client = FakeOpenAIClient(config);
      client.formResponse = const {
        'data': [
          {
            'url': 'https://example.com/image.png',
            'revised_prompt': 'rp',
          },
        ],
      };

      final images = OpenAIStyleImages(client, config);

      final resp = await images.createVariation(
        ImageVariationRequest(
          image: const ImageInput(data: [1, 2, 3], format: 'png'),
          model: 'gpt-image-1',
        ),
      );

      expect(client.lastEndpoint, 'images/variations');
      expect(resp.model, 'gpt-image-1');

      final meta = resp.providerMetadata;
      expect(meta, isNotNull);
      expect(meta!.containsKey('deepseek'), isTrue);
      expect(meta.containsKey('deepseek.image'), isTrue);
      expect(
        meta['deepseek.image'],
        equals({
          'model': 'gpt-image-1',
          'endpoint': 'images/variations',
        }),
      );
    });
  });
}
