import 'dart:math';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai_client;
import 'package:llm_dart_openai/responses.dart' as openai_responses;
import 'package:test/test.dart';

import '../../utils/fixture_meta.dart';
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
  group('OpenAI Responses fixture fuzz (chunk boundaries)', () {
    Future<void> runFixtureFuzz(
      String baseName, {
      required List<int> seeds,
    }) async {
      final fixturePath = 'test/fixtures/openai/responses/$baseName.chunks.txt';

      final sessions = splitJsonLinesIntoSessions(
        readFixtureLines(fixturePath),
        isTerminalEvent: isOpenAIResponsesTerminalEvent,
      );
      expect(sessions, isNotEmpty, reason: 'Expected at least one session.');

      const baseUrl = 'https://api.openai.com/v1/';
      const model = 'gpt-5-mini';
      final providerTools = readProviderToolsFromV3Meta(
        provider: 'openai',
        scenario: baseName,
      );

      final config = openai_client.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: baseUrl,
        model: model,
        useResponsesAPI: true,
        originalConfig: providerTools.isEmpty
            ? null
            : LLMConfig(
                baseUrl: baseUrl,
                model: model,
                providerTools: providerTools,
              ),
      );

      for (var sessionIndex = 0;
          sessionIndex < sessions.length;
          sessionIndex++) {
        final goldenBasePath = 'test/fixtures/v3_parts/openai/$baseName';
        final goldenPath = sessions.length == 1
            ? '$goldenBasePath.jsonl'
            : '$goldenBasePath.session${sessionIndex + 1}.jsonl';

        for (final seed in seeds) {
          final baseStream = sseStreamFromJsonLines(sessions[sessionIndex]);
          final fuzzed = _splitRandom(baseStream, seed: seed);

          final client = FakeOpenAIClient(config)..streamResponse = fuzzed;
          final responses = openai_responses.OpenAIResponses(client, config);

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

    test('tool-input deltas survive arbitrary splits', () async {
      await runFixtureFuzz(
        'openai-code-interpreter-tool.1',
        seeds: const [1, 7, 42],
      );
    });

    test('mcp tool approval survives arbitrary splits', () async {
      await runFixtureFuzz(
        'openai-mcp-tool-approval.1',
        seeds: const [1, 7, 42],
      );
    });
  });
}
