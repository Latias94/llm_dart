import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:llm_dart_xai/llm_dart_xai.dart';
import 'package:test/test.dart';

import '../../utils/fakes/openai_fake_client.dart';

void main() {
  group('xAI image generation (provider metadata)', () {
    test('uses config.imageModel and exposes responses.headers', () async {
      final xaiConfig = XAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://example.com/v1/',
        model: 'grok-3',
        imageModel: 'grok-2-image',
      );

      final openAIConfig = OpenAICompatibleConfig(
        providerId: 'xai',
        providerName: 'xAI',
        apiKey: 'test-key',
        baseUrl: 'https://example.com/v1/',
        model: 'grok-3',
      );

      final client = FakeOpenAIClient(openAIConfig)
        ..jsonHeaders = const {'x-test': '1'}
        ..jsonResponse = const {
          'data': [
            {
              'url': 'https://example.com/image.png',
              'revised_prompt': 'rev',
            }
          ],
        };

      final provider = XAIProvider(xaiConfig, client: client);

      final response = await provider.generateImagesWithCallOptions(
        const ImageGenerationRequest(
          prompt: 'hi',
          size: '1024x1024',
        ),
        callOptions: const LLMCallOptions(),
      );

      expect(client.lastEndpoint, equals('images/generations'));
      expect(client.lastJsonBody?['model'], equals('grok-2-image'));
      expect(response.images, hasLength(1));
      expect(response.responses, hasLength(1));
      expect(response.responses.single.headers, equals(const {'x-test': '1'}));
      expect(
        response.warnings.any(
          (w) => w is LLMUnsupportedWarning && w.feature == 'size',
        ),
        isTrue,
      );
    });
  });
}
