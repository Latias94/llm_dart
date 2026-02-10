import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart' as llm_ai;
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

import '../../utils/fixture_replay.dart';
import '../../utils/fakes/fakes.dart';
import '../../utils/v3_parts_golden.dart';

void main() {
  group('Anthropic v3 parts goldens (Vercel fixtures)', () {
    Future<void> runFixtureGolden(
      String baseName, {
      String provider = 'anthropic',
    }) async {
      final fixturePath =
          'test/fixtures/anthropic/messages/$baseName.chunks.txt';

      final sessions = sseStreamsFromChunkFileSplitByTerminalEvent(
        fixturePath,
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

      for (var i = 0; i < sessions.length; i++) {
        final client = FakeAnthropicClient(config)
          ..streamResponse = sessions[i];
        final chat = AnthropicChat(client, config);

        final parts = await llm_ai.streamChatParts(
            model: chat, messages: [ChatMessage.user('Hi')]).toList();

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

    test('anthropic-web-search-tool.1', () async {
      await runFixtureGolden('anthropic-web-search-tool.1');
    });

    test('anthropic-json-tool.1', () async {
      await runFixtureGolden('anthropic-json-tool.1');
    });
  });
}
