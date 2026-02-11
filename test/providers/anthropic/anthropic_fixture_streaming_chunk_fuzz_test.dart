import 'dart:math';

import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_ai/llm_dart_ai.dart' as llm_ai;
import 'package:test/test.dart';

import '../../utils/fixture_replay.dart';
import '../../utils/fakes/fakes.dart';
import '../../utils/v3_parts_golden.dart';

Stream<String> _splitRandom(
  Stream<String> input, {
  required int seed,
  int maxLen = 11,
}) async* {
  final random = Random(seed);
  await for (final chunk in input) {
    if (chunk.isEmpty) continue;
    var i = 0;
    while (i < chunk.length) {
      final remaining = chunk.length - i;
      final size = min(remaining, 1 + random.nextInt(maxLen));
      yield chunk.substring(i, i + size);
      i += size;
    }
  }
}

void main() {
  group('Anthropic fixture fuzz (chunk boundaries)', () {
    Future<void> runFixtureFuzz(
      String baseName, {
      required List<int> seeds,
    }) async {
      final fixturePath =
          'test/fixtures/anthropic/messages/$baseName.chunks.txt';

      final sessions = splitJsonLinesIntoSessions(
        readFixtureLines(fixturePath),
        isTerminalEvent: isAnthropicMessagesTerminalEvent,
      );
      expect(sessions, isNotEmpty, reason: 'Expected at least one session.');

      final config = AnthropicConfig(
        providerId: 'anthropic',
        apiKey: 'test-key',
        model: 'claude-sonnet-4-20250514',
        baseUrl: 'https://api.anthropic.com/v1/',
        stream: true,
      );

      for (var sessionIndex = 0;
          sessionIndex < sessions.length;
          sessionIndex++) {
        final goldenBasePath = 'test/fixtures/v3_parts/anthropic/$baseName';
        final goldenPath = sessions.length == 1
            ? '$goldenBasePath.jsonl'
            : '$goldenBasePath.session${sessionIndex + 1}.jsonl';

        for (final seed in seeds) {
          final baseStream = sseStreamFromJsonLines(sessions[sessionIndex]);
          final fuzzed = _splitRandom(baseStream, seed: seed);

          final client = FakeAnthropicClient(config)..streamResponse = fuzzed;
          final chat = AnthropicChat(client, config);

          final parts = await llm_ai.streamChatParts(
            model: chat,
            messages: [ChatMessage.user('Hi')],
          ).toList();

          final actual = encodeV3StreamParts(parts);
          expectStableJsonlGolden(
            goldenPath: goldenPath,
            actualObjects: actual,
          );
        }
      }
    }

    test('web-search server tool survives arbitrary splits', () async {
      await runFixtureFuzz(
        'anthropic-web-search-tool.1',
        seeds: const [1, 7, 42],
      );
    });
  });
}
