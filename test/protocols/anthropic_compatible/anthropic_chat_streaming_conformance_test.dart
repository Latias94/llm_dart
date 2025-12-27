import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';

import 'streaming_reasoning_text_conformance.dart';

void main() {
  registerAnthropicCompatibleReasoningTextStreamingConformanceTests(
    groupName: 'AnthropicChat streaming conformance (Anthropic-compatible)',
    config: const AnthropicConfig(
      apiKey: 'k',
      providerId: 'anthropic',
      stream: true,
    ),
    createChat: (client, config) => AnthropicChat(client, config),
    expectedProviderMetadataKey: 'anthropic',
  );
}
