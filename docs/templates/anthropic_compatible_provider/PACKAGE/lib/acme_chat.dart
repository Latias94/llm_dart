library;

import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_anthropic_compatible/client.dart';

/// Acme chat provider implemented via the Anthropic-compatible Messages API.
class AcmeChat extends AnthropicChat {
  AcmeChat(
    AnthropicClient client,
    AnthropicConfig config,
  ) : super(client, config);
}
