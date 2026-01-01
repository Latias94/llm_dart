library;

import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import 'minimax.dart';
import 'provider.dart';

/// MiniMax provider id used in the core registry.
const String minimaxProviderId = 'minimax';

/// Register the MiniMax provider in the global [LLMProviderRegistry].
///
/// - If [replace] is false (default), registration is idempotent and will
///   not override an existing provider registered under the same id.
/// - If [replace] is true, the existing registration (if any) is replaced.
void registerMinimax({bool replace = false}) {
  if (!replace && LLMProviderRegistry.isRegistered(minimaxProviderId)) return;
  final factory = MinimaxProviderFactory();
  if (replace) {
    LLMProviderRegistry.registerOrReplace(factory);
    return;
  }
  LLMProviderRegistry.register(factory);
}

/// Factory for creating MiniMax provider instances (Anthropic-compatible).
class MinimaxProviderFactory extends BaseProviderFactory<ChatCapability> {
  @override
  String get providerId => minimaxProviderId;

  @override
  Set<LLMCapability> get supportedCapabilities => minimaxSupportedCapabilities;

  @override
  String get displayName => 'MiniMax';

  @override
  String get description =>
      'MiniMax models via Anthropic-compatible Messages API';

  @override
  ChatCapability create(LLMConfig config) {
    return createProviderSafely<AnthropicConfig>(
      config,
      () => _transformConfig(config),
      (anthropicConfig) => MinimaxProvider(anthropicConfig),
    );
  }

  @override
  Map<String, dynamic> getProviderDefaults() {
    return {
      'baseUrl': minimaxAnthropicV1BaseUrl,
      'model': minimaxDefaultModel,
    };
  }

  AnthropicConfig _transformConfig(LLMConfig config) {
    final normalized = config.copyWith(
      baseUrl: normalizeMinimaxAnthropicBaseUrl(config.baseUrl),
    );
    return AnthropicConfig.fromLLMConfig(
      normalized,
      providerOptionsNamespace: minimaxProviderId,
    );
  }
}
