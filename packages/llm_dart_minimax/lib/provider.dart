import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_core/core/capability.dart';

/// MiniMax provider implementation (Anthropic-compatible).
///
/// This provider is intentionally thin and delegates protocol behavior to
/// `llm_dart_anthropic_compatible`.
class MinimaxProvider extends AnthropicCompatibleChatProvider {
  MinimaxProvider(AnthropicConfig config)
      : super(
          AnthropicClient(
            config,
            strategy: AnthropicDioStrategy(providerName: 'MiniMax'),
          ),
          config,
          const {
            LLMCapability.chat,
            LLMCapability.streaming,
            LLMCapability.toolCalling,
          },
          providerName: 'MiniMax',
        );
}
