import 'dart:io';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai_client;
import 'package:llm_dart_openai/responses.dart' as openai_responses;
import 'package:test/test.dart';

import '../../utils/fixture_meta.dart';
import '../../utils/fixture_replay.dart';
import '../../utils/fakes/fakes.dart';
import '../../utils/v3_parts_golden.dart';

void main() {
  group('OpenAI Responses v3 parts goldens (Vercel fixtures)', () {
    Future<void> runFixtureGolden(
      String baseName, {
      String provider = 'openai',
    }) async {
      final fixturePath = 'test/fixtures/openai/responses/$baseName.chunks.txt';

      final sessions = sseStreamsFromChunkFileSplitByTerminalEvent(
        fixturePath,
        isTerminalEvent: isOpenAIResponsesTerminalEvent,
      );
      expect(sessions, isNotEmpty, reason: 'Expected at least one session.');

      const baseUrl = 'https://api.openai.com/v1/';
      const model = 'gpt-5-mini';
      final providerTools = readProviderToolsFromV3Meta(
        provider: provider,
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

      for (var i = 0; i < sessions.length; i++) {
        final client = FakeOpenAIClient(config)..streamResponse = sessions[i];
        final responses = openai_responses.OpenAIResponses(client, config);

        final parts = await responses.chatStreamParts(
          [ChatMessage.user('Hi')],
          providerTools: providerTools.isEmpty ? null : providerTools,
        ).toList();

        final goldenBasePath = 'test/fixtures/v3_parts/$provider/$baseName';
        final goldenPath = sessions.length == 1
            ? '$goldenBasePath.jsonl'
            : '$goldenBasePath.session${i + 1}.jsonl';

        final actual = encodeV3StreamParts(parts);
        expectStableJsonlGolden(
          goldenPath: goldenPath,
          actualObjects: actual,
        );
      }

      final meta = File('test/fixtures/v3_parts/$provider/$baseName.meta.json');
      expect(meta.existsSync(), isTrue);
    }

    final metaDir = Directory('test/fixtures/v3_parts/openai');
    final baseNames = metaDir
        .listSync(followLinks: false)
        .whereType<File>()
        .where((f) => f.path.endsWith('.meta.json'))
        .map((f) => f.uri.pathSegments.last.replaceAll('.meta.json', ''))
        .toList()
      ..sort();

    for (final baseName in baseNames) {
      test(baseName, () async {
        await runFixtureGolden(baseName);
      });
    }
  });
}
