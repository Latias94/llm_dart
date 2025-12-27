import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_core/core/config.dart';
import 'package:llm_dart_minimax/llm_dart_minimax.dart';

import '../../protocols/anthropic_compatible/tool_loop_persistence_conformance.dart';

void main() {
  final llmConfig = const LLMConfig(
    apiKey: 'k',
    baseUrl: minimaxAnthropicBaseUrl,
    model: minimaxDefaultModel,
  );

  final anthropicConfig = AnthropicConfig.fromLLMConfig(
    llmConfig,
    providerOptionsNamespace: 'minimax',
  );

  registerAnthropicCompatibleToolLoopPersistenceConformanceTests(
    groupName:
        'MiniMax tool loop persistence conformance (Anthropic-compatible)',
    config: anthropicConfig,
    createChat: (client, config) => AnthropicChat(client, config),
    expectedProviderMetadataKey: 'minimax',
    expectedModel: minimaxDefaultModel,
  );
}
