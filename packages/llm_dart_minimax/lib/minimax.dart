library;

import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

import 'minimax_models.dart';
import 'provider.dart';

export 'minimax_models.dart';
export 'provider.dart';

/// MiniMax Anthropic-compatible base URL (international).
///
/// Reference: https://platform.minimax.io/docs/api-reference/text-anthropic-api
const String minimaxAnthropicBaseUrl = 'https://api.minimax.io/anthropic/';

/// MiniMax Anthropic-compatible base URL (international, Messages API).
///
/// This matches the Vercel MiniMax provider default:
/// `https://api.minimax.io/anthropic/v1/`
const String minimaxAnthropicV1BaseUrl = 'https://api.minimax.io/anthropic/v1/';

/// MiniMax Anthropic-compatible base URL (China).
///
/// Reference: https://platform.minimax.io/docs/api-reference/text-anthropic-api
const String minimaxiAnthropicBaseUrl = 'https://api.minimaxi.com/anthropic/';

/// MiniMax Anthropic-compatible base URL (China, Messages API).
///
/// `https://api.minimaxi.com/anthropic/v1/`
const String minimaxiAnthropicV1BaseUrl =
    'https://api.minimaxi.com/anthropic/v1/';

/// Create a MiniMax chat provider using the Anthropic-compatible Messages API.
MinimaxProvider createMinimaxProvider({
  required String apiKey,
  String model = minimaxDefaultModel,
  String baseUrl = minimaxAnthropicV1BaseUrl,
  int? maxTokens,
  double? temperature,
  String? systemPrompt,
  Duration? timeout,
}) {
  final normalizedConfig = LLMConfig(
    apiKey: apiKey,
    baseUrl: normalizeMinimaxAnthropicBaseUrl(baseUrl),
    model: model,
    maxTokens: maxTokens,
    temperature: temperature,
    systemPrompt: systemPrompt,
    timeout: timeout,
  );

  final anthropicConfig = AnthropicConfig.fromLLMConfig(
    normalizedConfig,
    providerOptionsNamespace: 'minimax',
  );

  return MinimaxProvider(anthropicConfig);
}

String normalizeMinimaxAnthropicBaseUrl(String baseUrl) {
  return normalizeAnthropicCompatibleBaseUrl(baseUrl);
}

/// Default capability set for MiniMax text generation via Anthropic-compatible API.
const Set<LLMCapability> minimaxSupportedCapabilities = {
  LLMCapability.chat,
  LLMCapability.streaming,
  LLMCapability.toolCalling,
};
