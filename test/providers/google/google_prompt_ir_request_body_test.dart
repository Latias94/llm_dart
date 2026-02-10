import 'dart:convert';

import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

import '../../utils/fakes/fakes.dart';

void main() {
  group('Google Prompt IR request body', () {
    test('groups multiple parts into a single content entry', () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-1.5-flash',
      );

      final client = FakeGoogleClient(
        config,
        defaultJsonResponse: {
          'modelVersion': config.model,
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'ok'}
                ],
              },
            },
          ],
        },
      );
      final chat = GoogleChat(client, config);

      final prompt = Prompt(
        messages: [
          PromptMessage(
            role: ChatRole.user,
            parts: [
              const TextPart('Describe this image:'),
              ImagePart(
                mime: ImageMime.png,
                data: const [1, 2, 3],
                text: 'A small icon.',
              ),
            ],
          ),
        ],
      );

      await chat.chatPrompt(prompt);

      final contents = client.lastBody?['contents'] as List?;
      expect(contents, isNotNull);
      expect(contents, hasLength(1));

      final entry = contents!.single as Map;
      expect(entry['role'], equals('user'));

      final parts = entry['parts'] as List;
      expect(parts, hasLength(3));
      expect((parts[0] as Map)['text'], equals('Describe this image:'));
      expect((parts[1] as Map)['text'], equals('A small icon.'));

      final inlineData = (parts[2] as Map)['inlineData'] as Map;
      expect(inlineData['mimeType'], equals('image/png'));
      expect(inlineData['data'], equals(base64Encode(const [1, 2, 3])));
    });

    test('emits systemInstruction from system PromptMessage', () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-1.5-flash',
      );

      final client = FakeGoogleClient(
        config,
        defaultJsonResponse: {
          'modelVersion': config.model,
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'ok'}
                ],
              },
            },
          ],
        },
      );
      final chat = GoogleChat(client, config);

      final prompt = Prompt(
        messages: [
          const PromptMessage(
            role: ChatRole.system,
            parts: [TextPart('You are concise.')],
          ),
          const PromptMessage(
            role: ChatRole.user,
            parts: [TextPart('Hi')],
          ),
        ],
      );

      await chat.chatPrompt(prompt);

      final systemInstruction = client.lastBody?['systemInstruction'] as Map?;
      expect(systemInstruction, isNotNull);
      expect(
          systemInstruction!['parts'],
          equals([
            {'text': 'You are concise.'},
          ]));
    });

    test('encodes FilePart as inlineData and preserves part text', () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-1.5-flash',
        maxInlineDataSize: 1024,
      );

      final client = FakeGoogleClient(
        config,
        defaultJsonResponse: {
          'modelVersion': config.model,
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'ok'}
                ],
              },
            },
          ],
        },
      );
      final chat = GoogleChat(client, config);

      final prompt = Prompt(
        messages: [
          PromptMessage(
            role: ChatRole.user,
            parts: [
              const TextPart('Here is the document:'),
              FilePart(
                mime: FileMime.pdf,
                data: const [9, 8, 7, 6],
                text: 'A short PDF.',
              ),
            ],
          ),
        ],
      );

      await chat.chatPrompt(prompt);

      final contents = client.lastBody?['contents'] as List?;
      expect(contents, isNotNull);
      expect(contents, hasLength(1));

      final parts = ((contents!.single as Map)['parts'] as List);
      expect(parts, hasLength(3));
      expect((parts[0] as Map)['text'], equals('Here is the document:'));
      expect((parts[1] as Map)['text'], equals('A short PDF.'));

      final inlineData = (parts[2] as Map)['inlineData'] as Map;
      expect(inlineData['mimeType'], equals('application/pdf'));
      expect(inlineData['data'], equals(base64Encode(const [9, 8, 7, 6])));
    });

    test('propagates thoughtSignature for assistant parts (AI SDK parity)',
        () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-2.5-pro',
      );

      final client = FakeGoogleClient(
        config,
        defaultJsonResponse: {
          'modelVersion': config.model,
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'ok'}
                ],
              },
            },
          ],
        },
      );
      final chat = GoogleChat(client, config);

      final prompt = Prompt(
        messages: [
          const PromptMessage(
            role: ChatRole.assistant,
            parts: [
              TextPart(
                'Thinking...',
                providerOptions: {
                  'google': {'thoughtSignature': 'sigA'},
                },
              ),
            ],
          ),
        ],
      );

      await chat.chatPrompt(prompt);

      final contents = client.lastBody?['contents'] as List?;
      expect(contents, isNotNull);
      expect(contents, hasLength(1));

      final entry = contents!.single as Map;
      expect(entry['role'], equals('model'));
      final parts = entry['parts'] as List;
      expect(parts, hasLength(1));
      expect(
        parts.single,
        equals({'text': 'Thinking...', 'thoughtSignature': 'sigA'}),
      );
    });

    test('throws for ImageUrlPart in assistant messages (AI SDK parity)',
        () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-2.5-pro',
      );

      final client = FakeGoogleClient(
        config,
        defaultJsonResponse: {
          'modelVersion': config.model,
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'ok'}
                ],
              },
            },
          ],
        },
      );
      final chat = GoogleChat(client, config);

      final prompt = Prompt(
        messages: [
          const PromptMessage(
            role: ChatRole.assistant,
            parts: [
              ImageUrlPart(url: 'https://example.com/a.png'),
            ],
          ),
        ],
      );

      await expectLater(
        chat.chatPrompt(prompt),
        throwsA(isA<InvalidRequestError>()),
      );
    });

    test('encodes FileUrlPart as fileData and preserves part text', () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-1.5-flash',
      );

      final client = FakeGoogleClient(
        config,
        defaultJsonResponse: {
          'modelVersion': config.model,
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'ok'}
                ],
              },
            },
          ],
        },
      );
      final chat = GoogleChat(client, config);

      final prompt = Prompt(
        messages: [
          PromptMessage(
            role: ChatRole.user,
            parts: [
              const TextPart('Here is the document:'),
              const FileUrlPart(
                mime: FileMime.pdf,
                url: ' https://example.com/a.pdf ',
                text: 'A short PDF.',
              ),
            ],
          ),
        ],
      );

      await chat.chatPrompt(prompt);

      final contents = client.lastBody?['contents'] as List?;
      expect(contents, isNotNull);
      expect(contents, hasLength(1));

      final parts = ((contents!.single as Map)['parts'] as List);
      expect(parts, hasLength(3));
      expect((parts[0] as Map)['text'], equals('Here is the document:'));
      expect((parts[1] as Map)['text'], equals('A short PDF.'));

      final fileData = (parts[2] as Map)['fileData'] as Map;
      expect(fileData['mimeType'], equals('application/pdf'));
      expect(fileData['fileUri'], equals('https://example.com/a.pdf'));
    });

    test('throws for FileUrlPart in assistant messages (AI SDK parity)',
        () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-2.5-pro',
      );

      final client = FakeGoogleClient(
        config,
        defaultJsonResponse: {
          'modelVersion': config.model,
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'ok'}
                ],
              },
            },
          ],
        },
      );
      final chat = GoogleChat(client, config);

      final prompt = Prompt(
        messages: [
          const PromptMessage(
            role: ChatRole.assistant,
            parts: [
              FileUrlPart(
                mime: FileMime.pdf,
                url: 'https://example.com/a.pdf',
              ),
            ],
          ),
        ],
      );

      await expectLater(
        chat.chatPrompt(prompt),
        throwsA(isA<InvalidRequestError>()),
      );
    });

    test('throws for unsupported FileUrlPart URL schemes', () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-1.5-flash',
      );

      final client = FakeGoogleClient(
        config,
        defaultJsonResponse: {
          'modelVersion': config.model,
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'ok'}
                ],
              },
            },
          ],
        },
      );
      final chat = GoogleChat(client, config);

      final prompt = Prompt(
        messages: [
          const PromptMessage(
            role: ChatRole.user,
            parts: [
              FileUrlPart(
                mime: FileMime.pdf,
                url: 'file:///tmp/a.pdf',
              ),
            ],
          ),
        ],
      );

      await expectLater(
        chat.chatPrompt(prompt),
        throwsA(isA<InvalidRequestError>()),
      );
    });
  });
}
