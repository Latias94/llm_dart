import 'package:llm_dart_azure/llm_dart_azure.dart';
import 'package:llm_dart_azure/provider_tools.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

import '../../utils/fakes/fakes.dart';
import '../../utils/fixture_replay.dart';

void main() {
  group('Azure providerTools trigger Responses API (streaming)', () {
    test('uses responses endpoint when providerTools are provided', () async {
      const fixturePath =
          'test/fixtures/openai/responses/openai-web-search-tool.1.chunks.txt';

      final config = AzureOpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://example.openai.azure.com/openai/v1/',
        model: 'deployment_1',
        apiVersion: '2024-10-01-preview',
        useDeploymentBasedUrls: false,
        useResponsesAPI: false,
      );

      final client = FakeOpenAIClient(config)
        ..streamResponse = sseStreamFromChunkFile(fixturePath);
      final provider = AzureOpenAIProvider(config, client: client);

      final parts = await provider.chatStreamParts(
        [ChatMessage.user('Hi')],
        providerTools: [
          AzureOpenAIProviderTools.webSearchPreview(),
        ],
      ).toList();

      expect(client.lastEndpoint, equals('responses'));
      expect(parts.whereType<LLMProviderToolCallPart>(), isNotEmpty);
      expect(parts.whereType<LLMFinishPart>(), isNotEmpty);
    });
  });
}
