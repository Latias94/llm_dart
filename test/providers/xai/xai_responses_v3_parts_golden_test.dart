import 'dart:io';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:llm_dart_xai/responses.dart';
import 'package:test/test.dart';

import '../../utils/fixture_replay.dart';
import '../../utils/fakes/fakes.dart';
import '../../utils/v3_parts_golden.dart';

void main() {
  group('xAI Responses v3 parts goldens (fixtures)', () {
    Future<void> runFixtureGolden(
      String baseName, {
      String provider = 'xai',
    }) async {
      final fixturePath = 'test/fixtures/xai/responses/$baseName.chunks.txt';

      final sessions = sseStreamsFromChunkFileSplitByTerminalEvent(
        fixturePath,
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

      for (var i = 0; i < sessions.length; i++) {
        final client = FakeOpenAIClient(config)..streamResponse = sessions[i];
        final responses = XAIResponses(client, config);

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

    test('xai-text-streaming.1', () async {
      await runFixtureGolden('xai-text-streaming.1');
    });

    test('xai-text-with-reasoning-streaming.1', () async {
      await runFixtureGolden('xai-text-with-reasoning-streaming.1');
    });

    test('xai-text-with-reasoning-streaming-store-false.1', () async {
      await runFixtureGolden('xai-text-with-reasoning-streaming-store-false.1');
    });

    test('xai-web-search-tool.1', () async {
      await runFixtureGolden('xai-web-search-tool.1');
    });

    test('xai-x-search-tool', () async {
      await runFixtureGolden('xai-x-search-tool');
    });
  });
}
