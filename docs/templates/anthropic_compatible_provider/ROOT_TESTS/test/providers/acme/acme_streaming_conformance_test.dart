import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_core/core/config.dart';
import 'package:llm_dart_acme/llm_dart_acme.dart';

import '../../protocols/anthropic_compatible/streaming_reasoning_text_conformance.dart';

void main() {
  final llmConfig = const LLMConfig(
    apiKey: 'k',
    baseUrl: acmeAnthropicBaseUrl,
    model: acmeDefaultModel,
    providerOptions: {
      'acme': {
        'reasoning': true,
      },
    },
  );

  final anthropicConfig = AnthropicConfig.fromLLMConfig(
    llmConfig,
    providerOptionsNamespace: 'acme',
  ).copyWith(stream: true);

  registerAnthropicCompatibleReasoningTextStreamingConformanceTests(
    groupName: 'Acme streaming conformance (Anthropic-compatible)',
    config: anthropicConfig,
    createChat: (client, config) => AcmeChat(client, config),
    expectedProviderMetadataKey: 'acme',
  );
}
