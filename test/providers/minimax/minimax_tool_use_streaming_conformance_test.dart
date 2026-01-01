import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_minimax/llm_dart_minimax.dart';

import '../../protocols/anthropic_compatible/streaming_tool_use_conformance.dart';

void main() {
  final llmConfig = const LLMConfig(
    apiKey: 'k',
    baseUrl: minimaxAnthropicBaseUrl,
    model: minimaxDefaultModel,
  );

  final anthropicConfig = AnthropicConfig.fromLLMConfig(
    llmConfig,
    providerOptionsNamespace: 'minimax',
  ).copyWith(stream: true);

  registerAnthropicCompatibleToolUseStreamingConformanceTests(
    groupName: 'MiniMax tool_use streaming conformance (Anthropic-compatible)',
    config: anthropicConfig,
    createChat: (client, config) => AnthropicChat(client, config),
    expectedProviderMetadataKey: 'minimax',
  );
}
