import 'dart:convert';
import 'dart:io';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:llm_dart_xai/responses.dart';
import 'package:test/test.dart';

import '../../utils/fixture_replay.dart';
import '../../utils/fakes/fakes.dart';

void main() {
  group('xAI Responses sources (AI SDK parity)', () {
    test('emits url citations as typed source parts', () async {
      const fixturePath =
          'test/fixtures/xai/responses/xai-x-search-tool.chunks.txt';

      final expectedUrls = <String>{};
      for (final line in File(fixturePath).readAsLinesSync()) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        final json = jsonDecode(trimmed) as Map<String, dynamic>;
        if (json['type'] != 'response.output_text.annotation.added') continue;
        final annotation = json['annotation'];
        if (annotation is! Map) continue;
        if (annotation['type'] != 'url_citation') continue;
        final url = annotation['url'];
        if (url is String && url.isNotEmpty) expectedUrls.add(url);
      }

      expect(expectedUrls, isNotEmpty);

      final config = OpenAICompatibleConfig(
        providerId: 'xai.responses',
        providerName: 'xAI (Responses)',
        apiKey: 'test-key',
        baseUrl: 'https://api.x.ai/v1/',
        model: 'grok-4-fast',
      );

      final client = FakeOpenAIClient(config)
        ..streamResponse = sseStreamFromChunkFile(fixturePath);
      final responses = XAIResponses(client, config);

      final parts =
          await responses.chatStreamParts([ChatMessage.user('Hi')]).toList();

      final sources = parts.whereType<LLMSourceUrlPart>().toList();
      expect(sources, isNotEmpty);

      final urls = sources.map((p) => p.url).toSet();
      expect(urls, containsAll(expectedUrls));

      final sourceIds = sources.map((p) => p.sourceId).toSet();
      expect(sourceIds.length, equals(urls.length));
    });
  });
}
