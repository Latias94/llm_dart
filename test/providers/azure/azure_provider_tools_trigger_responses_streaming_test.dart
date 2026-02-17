import 'package:llm_dart_azure/llm_dart_azure.dart';
import 'package:llm_dart_azure/provider_tools.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

import '../../utils/fakes/fakes.dart';

void main() {
  group('Azure providerTools require Responses API (streaming)', () {
    test('throws when providerTools are provided on azure.chat', () async {
      final config = AzureOpenAIConfig(
        providerId: azureChatProviderId,
        providerName: 'Azure OpenAI (Chat)',
        apiKey: 'test-key',
        baseUrl: 'https://example.openai.azure.com/openai/v1/',
        model: 'deployment_1',
        apiVersion: '2024-10-01-preview',
        useDeploymentBasedUrls: false,
        useResponsesAPI: false,
      );

      final client = FakeOpenAIClient(config);
      final provider = AzureOpenAIProvider(config, client: client);

      expect(
        () => provider.chatStreamParts(
          [ChatMessage.user('Hi')],
          providerTools: [
            AzureOpenAIProviderTools.webSearchPreview(),
          ],
        ),
        throwsA(isA<UnsupportedCapabilityError>()),
      );
    });
  });
}
