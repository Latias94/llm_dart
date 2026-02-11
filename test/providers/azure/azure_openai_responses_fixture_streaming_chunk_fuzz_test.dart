import 'dart:convert';
import 'dart:math';

import 'package:llm_dart_azure/config.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/responses.dart' as openai_responses;
import 'package:test/test.dart';

import '../../utils/fixture_meta.dart';
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
  group('Azure OpenAI Responses fixture fuzz (chunk boundaries)', () {
    Future<void> runFixtureFuzz(
      String baseName, {
      required List<int> seeds,
    }) async {
      final fixturePath = 'test/fixtures/azure/responses/$baseName.chunks.txt';

      final sessions = splitJsonLinesIntoSessions(
        readFixtureLines(fixturePath),
        isTerminalEvent: isOpenAIResponsesTerminalEvent,
      );
      expect(sessions, isNotEmpty, reason: 'Expected at least one session.');

      const baseUrl = 'https://example.azure.com/openai/';
      const model = 'gpt-4.1-mini';
      final providerTools = readProviderToolsFromV3Meta(
        provider: 'azure',
        scenario: baseName,
      );

      final config = AzureOpenAIConfig(
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
        final goldenBasePath = 'test/fixtures/v3_parts/azure/$baseName';
        final goldenPath = sessions.length == 1
            ? '$goldenBasePath.jsonl'
            : '$goldenBasePath.session${sessionIndex + 1}.jsonl';

        final sse = sessions[sessionIndex].map(_asSse).join();

        for (final seed in seeds) {
          final client = FakeOpenAIClient(config)
            ..streamResponse = Stream<String>.fromIterable(
              _splitRandom(sse, seed: seed),
            );
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

    test('web_search_preview tool survives arbitrary splits', () async {
      await runFixtureFuzz(
        'azure-web-search-preview-tool.1',
        seeds: const [1, 7, 42],
      );
    });

    test('code-interpreter tool-input deltas survive arbitrary splits',
        () async {
      await runFixtureFuzz(
        'azure-code-interpreter-tool.1',
        seeds: const [1, 7, 42],
      );
    });

    test('reasoning-encrypted-content survives arbitrary splits', () async {
      await runFixtureFuzz(
        'azure-reasoning-encrypted-content.1',
        seeds: const [1, 7, 42],
      );
    });
  });
}
