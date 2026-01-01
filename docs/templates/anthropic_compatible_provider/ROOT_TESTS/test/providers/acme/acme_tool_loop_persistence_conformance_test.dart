import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_acme/llm_dart_acme.dart';

import '../../protocols/anthropic_compatible/tool_loop_persistence_conformance.dart';

void main() {
  final llmConfig = const LLMConfig(
    apiKey: 'k',
    baseUrl: acmeAnthropicBaseUrl,
    model: acmeDefaultModel,
  );

  final anthropicConfig = AnthropicConfig.fromLLMConfig(
    llmConfig,
    providerOptionsNamespace: 'acme',
  );

  registerAnthropicCompatibleToolLoopPersistenceConformanceTests(
    groupName: 'Acme tool loop persistence conformance (Anthropic-compatible)',
    config: anthropicConfig,
    createChat: (client, config) => AcmeChat(client, config),
    expectedProviderMetadataKey: 'acme',
    expectedModel: acmeDefaultModel,
  );
}
