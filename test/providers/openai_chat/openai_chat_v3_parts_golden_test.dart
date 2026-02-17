import 'dart:io';

import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai_client;
import 'package:test/test.dart';

import '../../utils/fakes/fakes.dart';
import '../../utils/fixture_meta.dart';
import '../../utils/fixture_replay.dart';
import '../../utils/v3_parts_golden.dart';

void main() {
  group('OpenAI Chat v3 parts goldens (Vercel fixtures)', () {
    Future<void> runFixtureGolden(
      String baseName, {
      String provider = 'openai_chat',
    }) async {
      final fixturePath = 'test/fixtures/openai/chat/$baseName.chunks.txt';
      final sessions = [sseStreamFromChunkFile(fixturePath)];

      final config = openai_client.OpenAIConfig(
        providerId: 'openai.chat',
        providerName: 'OpenAI (Chat)',
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-5-mini',
        useResponsesAPI: false,
      );

      final providerTools = readProviderToolsFromV3Meta(
        provider: provider,
        scenario: baseName,
      );

      for (var i = 0; i < sessions.length; i++) {
        final client = FakeOpenAIClient(config)..streamResponse = sessions[i];
        final providerInstance = openai_client.OpenAIProvider(
          config,
          client: client,
        );

        final parts = await providerInstance.chatStreamParts(
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

    final metaDir = Directory('test/fixtures/v3_parts/openai_chat');
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
