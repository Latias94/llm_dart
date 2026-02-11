import 'dart:io';

import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_ai/llm_dart_ai.dart' as llm_ai;
import 'package:llm_dart_google/chat.dart';
import 'package:llm_dart_google/config.dart';
import 'package:test/test.dart';

import '../../utils/fakes/fakes.dart';
import '../../utils/fixture_replay.dart';
import '../../utils/v3_parts_golden.dart';

void main() {
  group('Google Vertex v3 parts goldens (contract fixtures)', () {
    Future<void> runFixtureGolden(
      String baseName, {
      String provider = 'google_vertex',
    }) async {
      final fixturePath =
          'test/fixtures/google_vertex/chat/$baseName.chunks.txt';
      final sessions = [sseStreamFromChunkFile(fixturePath)];

      final config = GoogleConfig(
        providerId: 'google-vertex',
        providerOptionsName: 'google-vertex',
        apiKey: 'test-key',
        baseUrl: 'https://us-central1-aiplatform.googleapis.com/v1/',
        model: 'gemini-2.5-pro',
        stream: true,
      );

      for (var i = 0; i < sessions.length; i++) {
        final client = FakeGoogleClient(config)..streamResponse = sessions[i];
        final chat = GoogleChat(client, config);

        final parts = await llm_ai.streamChatParts(
          model: chat,
          messages: [ChatMessage.user('Hi')],
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

    final metaDir = Directory('test/fixtures/v3_parts/google_vertex');
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

