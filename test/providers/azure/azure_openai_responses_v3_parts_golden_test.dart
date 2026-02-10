import 'dart:io';

import 'package:llm_dart_azure/config.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/responses.dart' as openai_responses;
import 'package:test/test.dart';

import '../../utils/fixture_replay.dart';
import '../../utils/fakes/fakes.dart';
import '../../utils/v3_parts_golden.dart';

void main() {
  group('Azure OpenAI Responses v3 parts goldens (Vercel fixtures)', () {
    Future<void> runFixtureGolden(
      String baseName, {
      String provider = 'azure',
    }) async {
      final fixturePath = 'test/fixtures/azure/responses/$baseName.chunks.txt';

      final sessions = sseStreamsFromChunkFileSplitByTerminalEvent(
        fixturePath,
        isTerminalEvent: isOpenAIResponsesTerminalEvent,
      );
      expect(sessions, isNotEmpty, reason: 'Expected at least one session.');

      final config = AzureOpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://example.azure.com/openai/',
        model: 'gpt-4.1-mini',
        useResponsesAPI: true,
      );

      for (var i = 0; i < sessions.length; i++) {
        final client = FakeOpenAIClient(config)..streamResponse = sessions[i];
        final responses = openai_responses.OpenAIResponses(client, config);

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

    test('azure-code-interpreter-tool.1', () async {
      await runFixtureGolden('azure-code-interpreter-tool.1');
    });

    test('azure-web-search-preview-tool.1', () async {
      await runFixtureGolden('azure-web-search-preview-tool.1');
    });

    test('azure-reasoning-encrypted-content.1', () async {
      await runFixtureGolden('azure-reasoning-encrypted-content.1');
    });

    // Large fixture (base64 image). Golden normalization redacts large base64
    // strings to keep repo size manageable.
    test('azure-image-generation-tool.1', () async {
      await runFixtureGolden('azure-image-generation-tool.1');
    });
  });
}
