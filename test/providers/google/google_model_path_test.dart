import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_google/client.dart';
import 'package:test/test.dart';

class _CapturingGoogleClient extends GoogleClient {
  String? lastEndpoint;
  Map<String, dynamic>? lastBody;

  _CapturingGoogleClient(super.config);

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastBody = data;

    if (endpoint.endsWith(':embedContent')) {
      return {
        'embedding': {
          'values': [0.1, 0.2],
        },
      };
    }

    return {
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': 'ok'}
            ],
          },
        },
      ],
    };
  }
}

void main() {
  group('Google model path normalization (AI SDK parity)', () {
    test('chat passes through models/*', () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'models/gemini-1.5-flash',
      );
      final client = _CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat.chat([ChatMessage.user('hi')]);
      expect(client.lastEndpoint, 'models/gemini-1.5-flash:generateContent');
    });

    test('chat passes through tunedModels/*', () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'tunedModels/my-model',
      );
      final client = _CapturingGoogleClient(config);
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
      final client = _CapturingGoogleClient(config);
      final embeddings = GoogleEmbeddings(client, config);

      await embeddings.embed(['hi']);
      expect(client.lastEndpoint, 'models/text-embedding-004:embedContent');
    });
  });
}
