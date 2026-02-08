import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

class RecordingGoogleClient extends GoogleClient {
  String? lastPostJsonEndpoint;
  String? lastPostStreamRawEndpoint;

  RecordingGoogleClient(super.config);

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async {
    lastPostJsonEndpoint = endpoint;

    return {
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': 'ok'}
            ]
          }
        }
      ],
    };
  }

  @override
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async* {
    lastPostStreamRawEndpoint = endpoint;
    yield 'data: {"candidates":[{"content":{"parts":[{"text":"hi"}]}}]}\n\n';
  }
}

void main() {
  group('Google streaming endpoints', () {
    test('chat uses generateContent endpoint even when stream=true in config',
        () async {
      final config = const GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-1.5-flash',
        stream: true,
      );

      final client = RecordingGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat.chat([ChatMessage.user('hello')]);

      expect(
        client.lastPostJsonEndpoint,
        equals('models/gemini-1.5-flash:generateContent'),
      );
    });

    test('chatStream uses streamGenerateContent endpoint', () async {
      final config = const GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-1.5-flash',
      );

      final client = RecordingGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat.chatStream([ChatMessage.user('hello')]).first;

      expect(
        client.lastPostStreamRawEndpoint,
        equals('models/gemini-1.5-flash:streamGenerateContent'),
      );
    });
  });
}
