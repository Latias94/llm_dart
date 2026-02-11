import 'dart:math';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:llm_dart_xai/responses.dart';
import 'package:test/test.dart';

import '../../utils/fixture_replay.dart';
import '../../utils/fakes/fakes.dart';
import '../../utils/v3_parts_golden.dart';

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

String _asSse(String line) => 'data: $line\n\n';

void main() {
  group('xAI Responses fixture fuzz (chunk boundaries)', () {
    Future<void> runFixtureFuzz(
      String baseName, {
      required List<int> seeds,
    }) async {
      final fixturePath = 'test/fixtures/xai/responses/$baseName.chunks.txt';

      final sessions = splitJsonLinesIntoSessions(
        readFixtureLines(fixturePath),
        isTerminalEvent: isOpenAIResponsesTerminalEvent,
      );
      expect(sessions, isNotEmpty, reason: 'Expected at least one session.');

      final config = OpenAICompatibleConfig(
        providerId: 'xai.responses',
        providerName: 'xAI (Responses)',
        apiKey: 'test-key',
        baseUrl: 'https://api.x.ai/v1/',
        model: 'grok-4-fast',
      );

      for (var sessionIndex = 0;
          sessionIndex < sessions.length;
          sessionIndex++) {
        final goldenBasePath = 'test/fixtures/v3_parts/xai/$baseName';
        final goldenPath = sessions.length == 1
            ? '$goldenBasePath.jsonl'
            : '$goldenBasePath.session${sessionIndex + 1}.jsonl';

        final sse = sessions[sessionIndex].map(_asSse).join();

        for (final seed in seeds) {
          final client = FakeOpenAIClient(config)
            ..streamResponse = Stream<String>.fromIterable(
              _splitRandom(sse, seed: seed),
            );
          final responses = XAIResponses(client, config);

          final parts = await responses
              .chatStreamParts([ChatMessage.user('Hi')]).toList();

          final actual = encodeV3StreamParts(parts);
          expectStableJsonlGolden(
            goldenPath: goldenPath,
            actualObjects: actual,
          );
        }
      }
    }

    test('web-search tool survives arbitrary splits', () async {
      await runFixtureFuzz(
        'xai-web-search-tool.1',
        seeds: const [1, 7, 42],
      );
    });
  });
}
