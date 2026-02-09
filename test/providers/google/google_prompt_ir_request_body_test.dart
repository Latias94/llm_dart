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
  });
}
