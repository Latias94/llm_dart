import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';

import 'tool_loop_persistence_conformance.dart';

void main() {
  registerAnthropicCompatibleToolLoopPersistenceConformanceTests(
    groupName:
        'AnthropicChat tool loop persistence conformance (Anthropic-compatible)',
    config: const AnthropicConfig(
      apiKey: 'k',
      model: 'test-model',
      providerId: 'anthropic',
    ),
    createChat: (client, config) => AnthropicChat(client, config),
    expectedProviderMetadataKey: 'anthropic',
    expectedModel: 'test-model',
  );
}
