import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai_client;
import 'package:test/test.dart';

import '../../utils/fakes/fakes.dart';
import '../../utils/fixture_replay.dart';

void main() {
  group('OpenAI provider metadata alias (stream parts)', () {
    test('adds openai.responses alias to provider tool parts', () async {
      const fixturePath =
          'test/fixtures/openai/responses/openai-web-search-tool.1.chunks.txt';

      final config = openai_client.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-5-mini',
        useResponsesAPI: true,
      );

      final client = FakeOpenAIClient(config)
        ..streamResponse = sseStreamFromChunkFile(fixturePath);
      final provider = OpenAIProvider(config, client: client);

      final parts =
          await provider.chatStreamParts([ChatMessage.user('Hi')]).toList();

      final toolParts = [
        ...parts.whereType<LLMProviderToolCallPart>(),
        ...parts.whereType<LLMProviderToolDeltaPart>(),
        ...parts.whereType<LLMProviderToolResultPart>(),
      ];
      expect(toolParts, isNotEmpty);

      for (final part in toolParts) {
        final meta = switch (part) {
          LLMProviderToolCallPart(:final providerMetadata) => providerMetadata,
          LLMProviderToolDeltaPart(:final providerMetadata) => providerMetadata,
          LLMProviderToolResultPart(:final providerMetadata) =>
            providerMetadata,
          _ => null,
        };
        expect(meta, isNotNull);
        expect(meta!['openai.responses'], equals(meta['openai']));
      }

      final metadataPart = parts.whereType<LLMProviderMetadataPart>().last;
      expect(
        metadataPart.providerMetadata['openai.responses'],
        equals(metadataPart.providerMetadata['openai']),
      );

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(
        finish.response.providerMetadata?['openai.responses'],
        equals(finish.response.providerMetadata?['openai']),
      );
    });
  });
}
