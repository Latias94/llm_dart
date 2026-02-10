import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

import '../../utils/fakes/fakes.dart';
import '../../utils/fixture_replay.dart';

void main() {
  group('Azure provider metadata alias (stream parts)', () {
    test('adds azure.responses alias to providerMetadata maps', () async {
      const fixturePath =
          'test/fixtures/openai/responses/openai-web-search-tool.1.chunks.txt';

      final config = AzureOpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://example.openai.azure.com/openai/v1/',
        model: 'deployment_1',
        apiVersion: '2024-10-01-preview',
        useDeploymentBasedUrls: false,
        useResponsesAPI: true,
      );

      final client = FakeOpenAIClient(config)
        ..streamResponse = sseStreamFromChunkFile(fixturePath);
      final provider = AzureOpenAIProvider(config, client: client);

      final parts =
          await provider.chatStreamParts([ChatMessage.user('Hi')]).toList();

      Map<String, dynamic>? providerMetadataForPart(LLMStreamPart part) {
        return switch (part) {
          LLMProviderToolCallPart(:final providerMetadata) => providerMetadata,
          LLMProviderToolDeltaPart(:final providerMetadata) => providerMetadata,
          LLMProviderToolResultPart(:final providerMetadata) =>
            providerMetadata,
          LLMProviderToolApprovalRequestPart(:final providerMetadata) =>
            providerMetadata,
          LLMReasoningStartPart(:final providerMetadata) => providerMetadata,
          LLMReasoningEndPart(:final providerMetadata) => providerMetadata,
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
        expect(meta['azure.responses'], equals(meta['azure']));
      }

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(
        finish.response.providerMetadata?['azure.responses'],
        equals(finish.response.providerMetadata?['azure']),
      );
    });
  });
}
