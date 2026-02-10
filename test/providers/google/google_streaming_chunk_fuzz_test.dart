import 'dart:math';

import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

import '../../utils/fakes/google_fake_client.dart';

List<String> _splitRandom(String input, {required int seed, int maxLen = 11}) {
  final random = Random(seed);
  final chunks = <String>[];
  var i = 0;
  while (i < input.length) {
    final remaining = input.length - i;
    final size = min(remaining, 1 + random.nextInt(maxLen));
    chunks.add(input.substring(i, i + size));
    i += size;
  }
  return chunks;
}

void main() {
  group('Google chatStreamParts fuzz (chunk boundaries)', () {
    test('handles arbitrary chunk splits without losing parts', () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-2.5-flash',
        stream: true,
      );

      final sse = [
        'data: {"candidates":[{"groundingMetadata":{"groundingChunks":[{"web":{"uri":"https://example.com/grounding","title":"Grounding"}}]},"content":{"parts":[{"text":"思考","thought":true},{"text":"Hello "},{"executableCode":{"code":"print(1+1)"}}]}}]}\n\n',
        'data: {"candidates":[{"groundingMetadata":{"groundingChunks":[{"web":{"uri":"https://example.com/grounding","title":"Grounding"}}]},"content":{"parts":[{"codeExecutionResult":{"outcome":"OUTCOME_OK","output":"2"}},{"text":"world"},{"functionCall":{"name":"get_weather","args":{"location":"London"}}}]},"finishReason":"STOP"}],"usageMetadata":{"promptTokenCount":10,"candidatesTokenCount":5,"totalTokenCount":15,"thoughtsTokenCount":1}}\n\n',
      ].join();

      for (final seed in [1, 7, 42]) {
        final client = FakeGoogleClient(config)
          ..streamResponse =
              Stream<String>.fromIterable(_splitRandom(sse, seed: seed));
        final chat = GoogleChat(client, config);

        final parts =
            await chat.chatStreamParts([ChatMessage.user('Hi')]).toList();

        final text =
            parts.whereType<LLMTextDeltaPart>().map((p) => p.delta).join();
        final thinking =
            parts.whereType<LLMReasoningDeltaPart>().map((p) => p.delta).join();

        expect(text, equals('Hello world'));
        expect(thinking, equals('思考'));

        expect(parts.whereType<LLMToolCallStartPart>(), hasLength(1));
        expect(parts.whereType<LLMToolCallEndPart>(), hasLength(1));

        final providerToolCalls =
            parts.whereType<LLMProviderToolCallPart>().toList();
        final providerToolResults =
            parts.whereType<LLMProviderToolResultPart>().toList();
        expect(providerToolCalls, hasLength(1));
        expect(providerToolResults, hasLength(1));
        expect(providerToolCalls.single.toolName, equals('code_execution'));
        expect(providerToolResults.single.toolName, equals('code_execution'));
        expect(providerToolResults.single.toolCallId,
            equals(providerToolCalls.single.toolCallId));

        // Grounding sources should survive arbitrary chunk splits and be deduped.
        final sources = parts.whereType<LLMSourceUrlPart>().toList();
        expect(sources, hasLength(1));
        expect(sources.single.url, equals('https://example.com/grounding'));

        final finish = parts.whereType<LLMFinishPart>().single;
        expect(finish.response.text, equals('Hello world'));
        expect(finish.response.thinking, equals('思考'));
        expect(finish.response.toolCalls, isNotNull);
        expect(
            finish.response.toolCalls!.single.id, equals('call_get_weather'));
      }
    });
  });
}
