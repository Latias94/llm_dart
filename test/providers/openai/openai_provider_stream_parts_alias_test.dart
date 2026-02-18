import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai_client;
import 'package:test/test.dart';

import '../../utils/fakes/fakes.dart';
import '../../utils/fixture_replay.dart';

void main() {
  group('OpenAI provider metadata alias (stream parts)', () {
    test('adds openai.responses alias to providerMetadata maps', () async {
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

      Map<String, dynamic>? providerMetadataForPart(LLMStreamPart part) {
        return switch (part) {
          LLMProviderMetadataPart(:final providerMetadata) => providerMetadata,
          LLMProviderToolCallPart(:final providerMetadata) => providerMetadata,
          LLMProviderToolDeltaPart(:final providerMetadata) => providerMetadata,
          LLMProviderToolResultPart(:final providerMetadata) =>
            providerMetadata,
          LLMProviderToolApprovalRequestPart(:final providerMetadata) =>
            providerMetadata,
          LLMReasoningStartPart(:final providerMetadata) => providerMetadata,
          LLMReasoningEndPart(:final providerMetadata) => providerMetadata,
          LLMSourceUrlPart(:final providerMetadata) => providerMetadata,
          LLMSourceDocumentPart(:final providerMetadata) => providerMetadata,
          _ => null,
        };
      }

      final metas = parts
          .map(providerMetadataForPart)
          .whereType<Map<String, dynamic>>()
          .toList();
      expect(metas, isNotEmpty);

      for (final meta in metas) {
        expect(meta['openai.responses'], equals(meta['openai']));
      }

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(
        finish.response.providerMetadata?['openai.responses'],
        equals(finish.response.providerMetadata?['openai']),
      );
    });
  });
}
