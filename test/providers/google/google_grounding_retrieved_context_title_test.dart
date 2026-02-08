import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

import '../../utils/fakes/google_fake_client.dart';

void main() {
  group('Google grounding retrievedContext sources', () {
    test('does not default URL source title to Unknown Document', () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-2.5-flash',
        stream: true,
      );

      final client = FakeGoogleClient(config);
      client.streamResponse = Stream<String>.fromIterable(const [
        'data: {"candidates":[{"content":{"parts":[{"text":"Hi"}]},"groundingMetadata":{"groundingChunks":[{"retrievedContext":{"uri":"https://source.example.com"}}]}}]}\n\n',
        'data: {"candidates":[{"content":{"parts":[{"text":"!"}]},"finishReason":"STOP"}]}\n\n',
      ]);

      final chat = GoogleChat(client, config);
      final parts = await chat.chatStreamParts([ChatMessage.user('hello')],
          tools: const []).toList();

      final sources = parts.whereType<LLMSourceUrlPart>().toList();
      expect(sources, hasLength(1));
      expect(sources.single.url, equals('https://source.example.com'));
      expect(sources.single.title, isNull);
    });
  });
}
