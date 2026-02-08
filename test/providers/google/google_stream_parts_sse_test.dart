import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

import '../../utils/fakes/google_fake_client.dart';

void main() {
  group('Google chatStreamParts (Gemini SSE stream)', () {
    test('streams text deltas and finishes', () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-2.5-flash',
        stream: true,
      );

      final client = FakeGoogleClient(config);
      client.streamResponse = Stream<String>.fromIterable(const [
        'data: {"candidates":[{"content":{"parts":[{"text":"Hi "}]}}]}\n\n',
        'data: {"candidates":[{"content":{"parts":[{"text":"there"}]},"finishReason":"STOP"}]}\n\n',
      ]);

      final chat = GoogleChat(client, config);
      final parts = await chat
          .chatStreamParts([ChatMessage.user('hello')], tools: const [])
          .toList();

      expect(
        client.lastEndpoint,
        equals('models/${config.model}:streamGenerateContent?alt=sse'),
      );

      expect(parts.whereType<LLMTextStartPart>(), hasLength(1));
      expect(
        parts.whereType<LLMTextDeltaPart>().map((p) => p.delta).join(),
        equals('Hi there'),
      );
      expect(parts.whereType<LLMTextEndPart>().single.text, equals('Hi there'));

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.response.text, equals('Hi there'));
      expect(finish.response.providerMetadata, isNotNull);
    });

    test('handles chunks split between event and data lines', () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-2.5-flash',
        stream: true,
      );

      final client = FakeGoogleClient(config);
      client.streamResponse = Stream<String>.fromIterable(const [
        'event: message\n',
        'data: {"candidates":[{"content":{"parts":[{"text":"Hi"}]}}]}\n\n',
        'data: {"candidates":[{"content":{"parts":[{"text":"!"}]}}]}\n\n',
      ]);

      final chat = GoogleChat(client, config);
      final parts = await chat
          .chatStreamParts([ChatMessage.user('hello')], tools: const [])
          .toList();

      expect(
        parts.whereType<LLMTextDeltaPart>().map((p) => p.delta).join(),
        equals('Hi!'),
      );
      expect(parts.whereType<LLMFinishPart>(), hasLength(1));
    });
  });
}
