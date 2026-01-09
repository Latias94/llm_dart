import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_google/client.dart';
import 'package:test/test.dart';

import '../../utils/fakes/fakes.dart';

void main() {
  group('Google model path normalization (AI SDK parity)', () {
    test('chat passes through models/*', () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'models/gemini-1.5-flash',
      );
      final client = FakeGoogleClient(
        config,
        defaultJsonResponse: {
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

      await chat.chat([ChatMessage.user('hi')]);
      expect(client.lastEndpoint, 'models/gemini-1.5-flash:generateContent');
    });

    test('chat passes through tunedModels/*', () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'tunedModels/my-model',
      );
      final client = FakeGoogleClient(
        config,
        defaultJsonResponse: {
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

      await chat.chat([ChatMessage.user('hi')]);
      expect(client.lastEndpoint, 'tunedModels/my-model:generateContent');
    });

    test('embeddings passes through models/* and avoids double prefix',
        () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'models/text-embedding-004',
      );
      final embedEndpoint = 'models/text-embedding-004:embedContent';
      final client = FakeGoogleClient(
        config,
        defaultJsonResponse: {
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
        responsesByEndpoint: {
          embedEndpoint: {
            'embedding': {
              'values': [0.1, 0.2],
            },
          },
        },
      );
      final embeddings = GoogleEmbeddings(client, config);

      await embeddings.embed(['hi']);
      expect(client.lastEndpoint, embedEndpoint);
    });
  });
}
