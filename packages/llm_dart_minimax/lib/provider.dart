import 'package:llm_dart_anthropic_compatible/client.dart';
import 'package:llm_dart_anthropic_compatible/config.dart';
import 'package:llm_dart_anthropic_compatible/dio_strategy.dart';
import 'package:llm_dart_anthropic_compatible/provider.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

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
