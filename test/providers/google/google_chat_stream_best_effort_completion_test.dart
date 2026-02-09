import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_google/llm_dart_google.dart';
import 'package:test/test.dart';

import '../../utils/fakes/google_fake_client.dart';

void main() {
  group('GoogleChat chatStream best-effort completion (json mode)', () {
    test('emits completion when stream ends without finishReason', () async {
      final config = const GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-2.5-pro',
      );

      final client = FakeGoogleClient(config)
        ..streamResponse = Stream.fromIterable([
          '{"candidates":[{"content":{"parts":[{"text":"Hello"}],"role":"model"},"index":0}]}\n',
        ]);

      final chat = GoogleChat(client, config);

      final parts =
          await chat.chatStreamParts([ChatMessage.user('hi')]).toList();

      expect(
        parts.whereType<LLMTextDeltaPart>().map((p) => p.delta).join(),
        equals('Hello'),
      );
      expect(parts.whereType<LLMFinishPart>(), hasLength(1));

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.response.providerMetadata, isNotNull);
    });
  });
}
