import 'dart:io';

import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/responses.dart' as openai_compat;
import 'package:test/test.dart';

import '../../utils/fakes/fakes.dart';
import '../../utils/fixture_replay.dart';
import '../../utils/v3_parts_golden.dart';

void main() {
  group('Open Responses v3 parts goldens (Vercel fixtures)', () {
    Future<void> runFixtureGolden(
      String baseName, {
      String provider = 'open_responses',
    }) async {
      final fixturePath =
          'test/fixtures/open_responses/responses/$baseName.chunks.txt';

      final sessions = sseStreamsFromChunkFileSplitByTerminalEvent(
        fixturePath,
        isTerminalEvent: isOpenAIResponsesTerminalEvent,
      );
      expect(sessions, isNotEmpty, reason: 'Expected at least one session.');

      final config = OpenResponsesConfig(
        apiKey: 'test-key',
        baseUrl: 'https://example.local/v1/',
        model: 'gemma-7b-it',
      );

      for (var i = 0; i < sessions.length; i++) {
        final client = FakeOpenAIClient(config)..streamResponse = sessions[i];
        final responses = openai_compat.OpenAIResponses(client, config);

        final parts =
            await responses.chatStreamParts([ChatMessage.user('Hi')]).toList();

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

    final metaDir = Directory('test/fixtures/v3_parts/open_responses');
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
