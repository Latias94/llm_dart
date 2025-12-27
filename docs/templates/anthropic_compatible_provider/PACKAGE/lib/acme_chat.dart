library;

import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';

/// Acme chat provider implemented via the Anthropic-compatible Messages API.
class AcmeChat extends AnthropicChat {
  AcmeChat(
    AnthropicClient client,
    AnthropicConfig config,
  ) : super(client, config);
}
