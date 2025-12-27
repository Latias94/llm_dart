import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';

import 'streaming_tool_use_conformance.dart';

void main() {
  registerAnthropicCompatibleToolUseStreamingConformanceTests(
    groupName:
        'AnthropicChat tool_use streaming conformance (Anthropic-compatible)',
    config: const AnthropicConfig(
      apiKey: 'k',
      providerId: 'anthropic',
      stream: true,
    ),
    createChat: (client, config) => AnthropicChat(client, config),
    expectedProviderMetadataKey: 'anthropic',
  );
}
