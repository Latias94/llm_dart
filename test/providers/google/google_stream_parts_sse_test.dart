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
      final parts = await chat.chatStreamParts([ChatMessage.user('hello')],
          tools: const []).toList();

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

      final start = parts.whereType<LLMTextStartPart>().single;
      final deltas = parts.whereType<LLMTextDeltaPart>().toList();
      final end = parts.whereType<LLMTextEndPart>().single;
      expect(start.blockId, isNotNull);
      expect(deltas, isNotEmpty);
      for (final d in deltas) {
        expect(d.blockId, equals(start.blockId));
      }
      expect(end.blockId, equals(start.blockId));

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.response.text, equals('Hi there'));
      expect(finish.response.providerMetadata, isNotNull);
      expect(finish.finishReason, isNotNull);
      expect(
        finish.finishReason!.unified,
        equals(LLMUnifiedFinishReason.stop),
      );
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
      final parts = await chat.chatStreamParts([ChatMessage.user('hello')],
          tools: const []).toList();

      expect(
        parts.whereType<LLMTextDeltaPart>().map((p) => p.delta).join(),
        equals('Hi!'),
      );
      expect(parts.whereType<LLMFinishPart>(), hasLength(1));
    });

    test('propagates thoughtSignature on text/reasoning parts', () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-2.5-flash',
        stream: true,
      );

      final client = FakeGoogleClient(config);
      client.streamResponse = Stream<String>.fromIterable(const [
        'data: {"candidates":[{"content":{"parts":[{"text":"Think","thought":true,"thoughtSignature":"sigA"}]}}]}\n\n',
        'data: {"candidates":[{"content":{"parts":[{"text":"Answer","thoughtSignature":"sigB"}]},"finishReason":"STOP"}]}\n\n',
      ]);

      final chat = GoogleChat(client, config);
      final parts = await chat.chatStreamParts([ChatMessage.user('hello')],
          tools: const []).toList();

      final rStart = parts.whereType<LLMReasoningStartPart>().single;
      final rDelta = parts.whereType<LLMReasoningDeltaPart>().single;
      expect(
        rStart.providerMetadata?['google']?['thoughtSignature'],
        equals('sigA'),
      );
      expect(
        rDelta.providerMetadata?['google']?['thoughtSignature'],
        equals('sigA'),
      );
      expect(rStart.blockId, isNotNull);
      expect(rDelta.blockId, equals(rStart.blockId));

      final tStart = parts.whereType<LLMTextStartPart>().single;
      final tDelta = parts.whereType<LLMTextDeltaPart>().single;
      expect(
        tStart.providerMetadata?['google']?['thoughtSignature'],
        equals('sigB'),
      );
      expect(
        tDelta.providerMetadata?['google']?['thoughtSignature'],
        equals('sigB'),
      );
      expect(tStart.blockId, isNotNull);
      expect(tDelta.blockId, equals(tStart.blockId));
    });
  });
}
