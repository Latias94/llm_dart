import 'dart:convert';

import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Anthropic Prompt IR -> messages prompt (documents & URLs)', () {
    AnthropicRequestBuilder builder() {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'claude-sonnet-4-20250514',
      );
      final anthropicConfig = AnthropicConfig.fromLLMConfig(llmConfig);
      return AnthropicRequestBuilder(anthropicConfig);
    }

    test('rejects system messages after non-system messages', () {
      final b = builder();

      final prompt = Prompt(messages: [
        PromptMessage.user('Hi'),
        PromptMessage.system('Late system message'),
      ]);

      expect(
        () => b.buildRequestBodyFromPrompt(prompt, null, false),
        throwsA(isA<InvalidRequestError>()),
      );
    });

    test('supports ImageUrlPart by compiling to image.url source', () {
      final b = builder();

      final prompt = Prompt(messages: [
        PromptMessage(
          role: PromptRole.user,
          parts: const [
            TextPart('Look:'),
            ImageUrlPart(
              url: 'https://example.com/a.png',
              text: 'caption',
            ),
          ],
        ),
      ]);

      final body = b.buildRequestBodyFromPrompt(prompt, null, false);
      final messages = body['messages'] as List<dynamic>;
      final content =
          (messages.single as Map<String, dynamic>)['content'] as List<dynamic>;

      expect(content, hasLength(3));
      expect(content[0]['type'], equals('text'));
      expect(content[0]['text'], equals('Look:'));
      expect(content[1]['type'], equals('text'));
      expect(content[1]['text'], equals('caption'));
      expect(content[2]['type'], equals('image'));
      expect(content[2]['source'],
          equals({'type': 'url', 'url': 'https://example.com/a.png'}));
    });

    test('supports text/plain FilePart with citations metadata', () {
      final b = builder();

      final prompt = Prompt(messages: [
        PromptMessage(
          role: PromptRole.user,
          parts: [
            FilePart(
              mime: FileMime.txt,
              data: utf8.encode('Hello world'),
              providerOptions: const {
                'anthropic': {
                  'title': 'Doc title',
                  'context': 'Doc context',
                  'citations': {'enabled': true},
                },
              },
            ),
          ],
        ),
      ]);

      final body = b.buildRequestBodyFromPrompt(prompt, null, false);
      final messages = body['messages'] as List<dynamic>;
      final content =
          (messages.single as Map<String, dynamic>)['content'] as List<dynamic>;

      expect(content, hasLength(1));
      expect(content[0]['type'], equals('document'));
      expect(
        content[0]['source'],
        equals({
          'type': 'text',
          'media_type': 'text/plain',
          'data': 'Hello world',
        }),
      );
      expect(content[0]['title'], equals('Doc title'));
      expect(content[0]['context'], equals('Doc context'));
      expect(content[0]['citations'], equals({'enabled': true}));
    });
  });
}
