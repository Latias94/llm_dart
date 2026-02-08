import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

import '../../utils/fixture_replay.dart';
import '../../utils/fakes/fakes.dart';

void main() {
  group('Anthropic citations -> source parts', () {
    test('emits unique source url parts from citations_delta', () async {
      final config = AnthropicConfig(
        providerId: 'anthropic',
        apiKey: 'test-key',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'claude-sonnet-4-20250514',
      );

      final client = FakeAnthropicClient(config)
        ..streamResponse = sseStreamFromChunkFile(
          'test/fixtures/anthropic/messages/anthropic-web-search-tool.1.chunks.txt',
        );
      final chat = AnthropicChat(client, config);

      final parts =
          await chat.chatStreamParts([ChatMessage.user('Hi')]).toList();

      final sources = parts.whereType<LLMSourceUrlPart>().toList();
      final urls = sources.map((s) => s.url).toSet();

      // Fixture contains repeated citations for these URLs; we dedupe per URL.
      expect(
          urls,
          contains(
              'https://future.forem.com/om_shree_0709/major-tech-news-september-25-2025-5h38'));
      expect(urls, contains('https://9to5mac.com/2025/09/22/ios-26-1-beta-1/'));
      expect(urls.length, equals(sources.length));

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.response.providerMetadata?['anthropic'], isNotNull);
    });
  });
}
