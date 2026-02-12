import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_google/llm_dart_google.dart';
import 'package:test/test.dart';

import '../../utils/fakes/google_fake_client.dart';

void main() {
  group('GoogleChat response headers in response-metadata', () {
    test('exposes response headers when available', () async {
      final config = const GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-2.5-pro',
      );

      final client = FakeGoogleClient(config)
        ..streamHeaders = const {'x-test': '1'}
        ..streamResponse = Stream.fromIterable(const [
          'data: {"modelVersion":"gemini-2.5-pro","candidates":[{"content":{"parts":[{"text":"Hello"}],"role":"model"},"finishReason":"STOP","index":0}]}\n\n',
          'data: [DONE]\n\n',
        ]);

      final chat = GoogleChat(client, config);
      final parts =
          await chat.chatStreamParts([ChatMessage.user('hi')]).toList();

      final meta = parts.whereType<LLMResponseMetadataPart>().single;
      expect(meta.headers, isNotNull);
      expect(meta.headers, containsPair('x-test', '1'));
    });
  });
}
