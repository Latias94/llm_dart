import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/openai.dart';
import 'package:test/test.dart';

import '../../utils/fakes/openai_fake_client.dart';

void main() {
  group('OpenAI images providerMetadata', () {
    test('generateImages attaches openai + openai.image metadata', () async {
      final config = OpenAIConfig(apiKey: 'test-key', model: 'gpt-image-1');
      final client = FakeOpenAIClient(config);
      client.jsonResponse = const {
        'data': [
          {
            'url': 'https://example.com/image.png',
            'revised_prompt': 'rp',
          },
        ],
      };

      final images = OpenAIImages(client, config);

      final resp = await images.generateImages(
        const ImageGenerationRequest(prompt: 'hi', model: 'gpt-image-1'),
      );

      expect(client.lastEndpoint, 'images/generations');
      expect(resp.model, 'gpt-image-1');

      final meta = resp.providerMetadata;
      expect(meta, isNotNull);
      expect(meta!.containsKey('openai'), isTrue);
      expect(meta.containsKey('openai.image'), isTrue);
      expect(
        meta['openai.image'],
        equals({
          'model': 'gpt-image-1',
          'endpoint': 'images/generations',
        }),
      );
    });

    test('editImage attaches openai + openai.image metadata', () async {
      final config = OpenAIConfig(apiKey: 'test-key', model: 'gpt-image-1');
      final client = FakeOpenAIClient(config);
      client.formResponse = const {
        'data': [
          {
            'url': 'https://example.com/image.png',
            'revised_prompt': 'rp',
          },
        ],
      };

      final images = OpenAIImages(client, config);
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
      expect(meta!.containsKey('openai'), isTrue);
      expect(meta.containsKey('openai.image'), isTrue);
      expect(
        meta['openai.image'],
        equals({
          'model': 'gpt-image-1',
          'endpoint': 'images/edits',
        }),
      );
    });

    test('createVariation attaches openai + openai.image metadata', () async {
      final config = OpenAIConfig(apiKey: 'test-key', model: 'gpt-image-1');
      final client = FakeOpenAIClient(config);
      client.formResponse = const {
        'data': [
          {
            'url': 'https://example.com/image.png',
            'revised_prompt': 'rp',
          },
        ],
      };

      final images = OpenAIImages(client, config);
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
      expect(meta!.containsKey('openai'), isTrue);
      expect(meta.containsKey('openai.image'), isTrue);
      expect(
        meta['openai.image'],
        equals({
          'model': 'gpt-image-1',
          'endpoint': 'images/variations',
        }),
      );
    });
  });
}
