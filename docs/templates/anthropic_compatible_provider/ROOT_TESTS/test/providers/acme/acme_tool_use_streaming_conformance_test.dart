import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_acme/llm_dart_acme.dart';

import '../../protocols/anthropic_compatible/streaming_tool_use_conformance.dart';

void main() {
  final llmConfig = const LLMConfig(
    apiKey: 'k',
    baseUrl: acmeAnthropicBaseUrl,
    model: acmeDefaultModel,
  );

  final anthropicConfig = AnthropicConfig.fromLLMConfig(
    llmConfig,
    providerOptionsNamespace: 'acme',
  ).copyWith(stream: true);

  registerAnthropicCompatibleToolUseStreamingConformanceTests(
    groupName: 'Acme tool_use streaming conformance (Anthropic-compatible)',
    config: anthropicConfig,
    createChat: (client, config) => AcmeChat(client, config),
    expectedProviderMetadataKey: 'acme',
  );
}
