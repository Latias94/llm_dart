import 'dart:io';

import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_ai/llm_dart_ai.dart' as llm_ai;
import 'package:llm_dart_anthropic_compatible/config.dart' as anthropic_compat;
import 'package:llm_dart_anthropic_compatible/provider.dart'
    as anthropic_compat_provider;
import 'package:test/test.dart';

import '../../utils/fakes/fakes.dart';
import '../../utils/fixture_meta.dart';
import '../../utils/fixture_replay.dart';
import '../../utils/v3_parts_golden.dart';

void main() {
  group('MiniMax v3 parts goldens (vendored Anthropic fixtures)', () {
    const capabilities = {
      LLMCapability.chat,
      LLMCapability.streaming,
      LLMCapability.toolCalling,
    };

    Future<void> runFixtureGolden(
      String baseName, {
      String provider = 'minimax',
    }) async {
      final fixturePath =
          'test/fixtures/anthropic/messages/$baseName.chunks.txt';
      final sessions = sseStreamsFromChunkFileSplitByTerminalEvent(
        fixturePath,
        isTerminalEvent: isAnthropicMessagesTerminalEvent,
      );

      final config = anthropic_compat.AnthropicConfig(
        providerId: 'minimax',
        apiKey: 'test-key',
        baseUrl: 'https://api.minimax.io/anthropic/v1/',
        model: 'MiniMax-M2.1',
        stream: true,
      );

      for (var i = 0; i < sessions.length; i++) {
        final client = FakeAnthropicClient(config)
          ..streamResponse = sessions[i];
        final providerInstance =
            anthropic_compat_provider.AnthropicCompatibleChatProvider(
          client,
          config,
          capabilities,
          providerName: 'MiniMax',
        );

        final providerTools = readProviderToolsFromV3Meta(
          provider: provider,
          scenario: baseName,
        );

        final parts = await llm_ai
            .streamChatParts(
              model: providerInstance,
              messages: [ChatMessage.user('Hi')],
              providerTools: providerTools.isEmpty ? null : providerTools,
            )
            .toList();

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

    final metaDir = Directory('test/fixtures/v3_parts/minimax');
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
