import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

import '../../utils/fakes/google_fake_client.dart';

void main() {
  group('Google chatStreamParts grounding sources', () {
    test('emits LLMSourceUrlPart from groundingMetadata', () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-2.5-flash',
        stream: true,
      );

      final client = FakeGoogleClient(config);
      client.streamResponse = Stream<String>.fromIterable(const [
        'data: {"modelVersion":"gemini-2.5-flash","candidates":[{"content":{"parts":[{"text":"Hi"}]},"groundingMetadata":{"groundingChunks":[{"web":{"uri":"https://example.com","title":"Example"}}]}}]}\n\n',
        'data: {"candidates":[{"content":{"parts":[{"text":"!"}]},"finishReason":"STOP"}]}\n\n',
      ]);

      final chat = GoogleChat(client, config);
      final parts = await chat.chatStreamParts([ChatMessage.user('hello')],
          tools: const []).toList();

      final responseMetadata =
          parts.whereType<LLMResponseMetadataPart>().single;
      expect(responseMetadata.model, equals('gemini-2.5-flash'));
      expect(
        parts.indexOf(responseMetadata),
        lessThan(parts.indexWhere((p) => p is LLMSourceUrlPart)),
      );

      final sources = parts.whereType<LLMSourceUrlPart>().toList();
      expect(sources, hasLength(1));
      expect(sources.single.url, equals('https://example.com'));
      expect(sources.single.title, equals('Example'));

      final finish = parts.whereType<LLMFinishPart>().single;
      final meta = finish.response.providerMetadata;
      expect(meta, isNotNull);

      final google = meta!['google'] as Map<String, dynamic>;
      expect(google['groundingMetadata'], isNotNull);
      expect(google['finishReason'], equals('STOP'));
    });
  });
}
