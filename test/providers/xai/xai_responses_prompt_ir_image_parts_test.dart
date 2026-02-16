import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:llm_dart_xai/responses.dart';
import 'package:test/test.dart';

import '../../utils/fakes/openai_fake_client.dart';

void main() {
  group('xAI Responses Prompt IR image parts', () {
    test('encodes ImagePart as input_image data URL', () async {
      final config = OpenAICompatibleConfig(
        providerId: 'xai.responses',
        providerName: 'xAI (Responses)',
        apiKey: 'test-key',
        baseUrl: 'https://example.com/v1/',
        model: 'grok-4-fast',
      );

      final client = FakeOpenAIClient(config)..jsonResponse = const {};

      final responses = XAIResponses(client, config);

      final prompt = Prompt(
        messages: [
          PromptMessage(
            role: PromptRole.user,
            parts: [
              const TextPart('Look'),
              ImagePart(
                mime: ImageMime.png,
                data: const [1, 2, 3],
                text: 'This is an image.',
              ),
            ],
          ),
        ],
      );

      await responses.chatPrompt(prompt);

      final input = client.lastJsonBody?['input'] as List?;
      expect(input, isNotNull);
      expect(input, hasLength(1));

      final user = input!.single as Map;
      expect(user['role'], equals('user'));
      final content = user['content'] as List;
      expect(content, hasLength(2));

      expect(content[0],
          equals({'type': 'input_text', 'text': 'Look\n\nThis is an image.'}));

      final image = content[1] as Map;
      expect(image['type'], equals('input_image'));
      expect(
        image['image_url'],
        equals('data:image/png;base64,${base64Encode(const [1, 2, 3])}'),
      );
    });

    test('encodes ImageUrlPart as input_image url', () async {
      final config = OpenAICompatibleConfig(
        providerId: 'xai.responses',
        providerName: 'xAI (Responses)',
        apiKey: 'test-key',
        baseUrl: 'https://example.com/v1/',
        model: 'grok-4-fast',
      );

      final client = FakeOpenAIClient(config)..jsonResponse = const {};

      final responses = XAIResponses(client, config);

      final prompt = Prompt(
        messages: [
          PromptMessage(
            role: PromptRole.user,
            parts: [
              const TextPart('See'),
              const ImageUrlPart(
                url: 'https://example.com/a.png',
                text: 'remote',
              ),
            ],
          ),
        ],
      );

      await responses.chatPrompt(prompt);

      final input = client.lastJsonBody?['input'] as List?;
      expect(input, isNotNull);
      expect(input, hasLength(1));

      final user = input!.single as Map;
      final content = user['content'] as List;
      expect(content, hasLength(2));
      expect(
          content[0], equals({'type': 'input_text', 'text': 'See\n\nremote'}));
      expect(
        content[1],
        equals({
          'type': 'input_image',
          'image_url': 'https://example.com/a.png',
        }),
      );
    });
  });
}
