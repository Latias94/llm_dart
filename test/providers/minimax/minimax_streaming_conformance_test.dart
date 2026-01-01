import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_minimax/llm_dart_minimax.dart';

import '../../protocols/anthropic_compatible/streaming_reasoning_text_conformance.dart';

void main() {
  final llmConfig = const LLMConfig(
    apiKey: 'k',
    baseUrl: minimaxAnthropicBaseUrl,
    model: minimaxDefaultModel,
    providerOptions: {
      'minimax': {
        'reasoning': true,
      },
    },
  );

  final anthropicConfig = AnthropicConfig.fromLLMConfig(
    llmConfig,
    providerOptionsNamespace: 'minimax',
  ).copyWith(stream: true);

  registerAnthropicCompatibleReasoningTextStreamingConformanceTests(
    groupName: 'MiniMax streaming conformance (Anthropic-compatible)',
    config: anthropicConfig,
    createChat: (client, config) => AnthropicChat(client, config),
    expectedProviderMetadataKey: 'minimax',
  );
}
