import 'dart:convert';
import 'dart:math';

import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

import '../../utils/fixture_replay.dart';
import '../../utils/fakes/fakes.dart';

List<String> _splitRandom(String input, {required int seed, int maxLen = 17}) {
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

String _asSse(String line) => 'data: $line\n\n';

void main() {
  group('Anthropic chatStreamParts fuzz (chunk boundaries)', () {
    test('handles arbitrary chunk splits without losing tool calls', () async {
      const fixturePath = 'test/fixtures/anthropic/messages/'
          'anthropic-tool-no-args.chunks.txt';
      final lines = readFixtureLines(fixturePath);

      final sse = lines.map(_asSse).join();

      final config = AnthropicConfig(
        providerId: 'anthropic',
        apiKey: 'test-key',
        model: 'claude-sonnet-4-5-20250929',
        baseUrl: 'https://api.anthropic.com/v1/',
      );

      for (final seed in [1, 7, 42]) {
        final client = FakeAnthropicClient(config)
          ..streamResponse =
              Stream<String>.fromIterable(_splitRandom(sse, seed: seed));

        final chat = AnthropicChat(client, config);
        final parts = await chat.chatStreamParts([ChatMessage.user('Hi')],
            tools: const []).toList();

        final text =
            parts.whereType<LLMTextDeltaPart>().map((p) => p.delta).join();
        expect(text, equals("I'll update the issue list for you."));

        expect(parts.whereType<LLMToolCallStartPart>(), hasLength(1));
        expect(parts.whereType<LLMToolCallEndPart>(), hasLength(1));

        final finish = parts.whereType<LLMFinishPart>().single;
        expect(finish.response.toolCalls, isNotNull);
        expect(finish.response.toolCalls, hasLength(1));
        expect(finish.response.toolCalls!.single.function.name,
            equals('updateIssueList'));
        expect(
            finish.response.toolCalls!.single.function.arguments, equals('{}'));
      }
    });

    test('handles arbitrary chunk splits without losing tool input deltas',
        () async {
      const fixturePath = 'test/fixtures/anthropic/messages/'
          'anthropic-json-tool.1.chunks.txt';
      final lines = readFixtureLines(fixturePath);

      final sse = lines.map(_asSse).join();

      final config = AnthropicConfig(
        providerId: 'anthropic',
        apiKey: 'test-key',
        model: 'claude-sonnet-4-5-20250929',
        baseUrl: 'https://api.anthropic.com/v1/',
      );

      for (final seed in [1, 7, 42]) {
        final client = FakeAnthropicClient(config)
          ..streamResponse =
              Stream<String>.fromIterable(_splitRandom(sse, seed: seed));

        final chat = AnthropicChat(client, config);
        final parts = await chat.chatStreamParts([ChatMessage.user('Hi')],
            tools: const []).toList();

        final toolStarts = parts.whereType<LLMToolCallStartPart>().toList();
        final toolDeltas = parts.whereType<LLMToolCallDeltaPart>().toList();
        final toolEnds = parts.whereType<LLMToolCallEndPart>().toList();

        expect(toolStarts, hasLength(1));
        expect(toolDeltas.length, greaterThanOrEqualTo(1));
        expect(toolEnds, hasLength(1));

        final id = toolStarts.single.toolCall.id;
        expect(id, isNotEmpty);
        expect(toolEnds.single.toolCallId, equals(id));
        expect(toolDeltas.every((d) => d.toolCall.id == id), isTrue);

        final emittedArgs = <String>[
          toolStarts.single.toolCall.function.arguments,
          ...toolDeltas.map((d) => d.toolCall.function.arguments),
        ].where((s) => s.isNotEmpty).join();

        final finish = parts.whereType<LLMFinishPart>().single;
        expect(finish.response.toolCalls, isNotNull);
        expect(finish.response.toolCalls, hasLength(1));

        final expectedArgs =
            finish.response.toolCalls!.single.function.arguments;

        expect(jsonDecode(emittedArgs), equals(jsonDecode(expectedArgs)));
      }
    });
  });
}
