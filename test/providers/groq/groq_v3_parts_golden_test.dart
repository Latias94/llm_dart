import 'dart:io';

import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:test/test.dart';

import '../../utils/fakes/fakes.dart';
import '../../utils/fixture_replay.dart';
import '../../utils/v3_parts_golden.dart';

void main() {
  group('Groq v3 parts goldens (contract fixtures)', () {
    Future<void> runFixtureGolden(
      String baseName, {
      String provider = 'groq',
    }) async {
      final fixturePath = 'test/fixtures/groq/chat/$baseName.chunks.txt';
      final sessions = [sseStreamFromChunkFile(fixturePath)];

      const capabilities = {LLMCapability.chat, LLMCapability.streaming};
      final config = OpenAICompatibleConfig(
        providerId: 'groq',
        providerName: 'Groq',
        apiKey: 'test-key',
        baseUrl: 'https://api.groq.com/openai/v1/',
        model: 'llama-3.3-70b-versatile',
      );

      for (var i = 0; i < sessions.length; i++) {
        final client = FakeOpenAIClient(config)..streamResponse = sessions[i];
        final providerInstance =
            OpenAICompatibleChatProvider(client, config, capabilities);

        final parts = await providerInstance
            .chatStreamParts([ChatMessage.user('Hi')]).toList();

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

    final metaDir = Directory('test/fixtures/v3_parts/groq');
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
