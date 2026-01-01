import 'package:llm_dart_core/core/capability.dart';
import 'package:llm_dart_core/core/config.dart';
import 'package:llm_dart_core/core/registry.dart';
import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import 'provider.dart';

/// Anthropic provider id used in the core registry.
const String anthropicProviderId = 'anthropic';

/// Register the Anthropic provider in the global [LLMProviderRegistry].
///
/// This enables building providers via `LLMBuilder().provider('anthropic')`
/// or `LLMProviderRegistry.createProvider('anthropic', config)`.
///
/// - If [replace] is false (default), registration is idempotent and will
///   not override an existing provider registered under the same id.
/// - If [replace] is true, the existing registration (if any) is replaced.
void registerAnthropic({bool replace = false}) {
  if (!replace && LLMProviderRegistry.isRegistered(anthropicProviderId)) return;
  final factory = AnthropicProviderFactory();
  if (replace) {
    LLMProviderRegistry.registerOrReplace(factory);
    return;
  }
  LLMProviderRegistry.register(factory);
}

/// Factory for creating Anthropic provider instances.
class AnthropicProviderFactory extends BaseProviderFactory<ChatCapability> {
  @override
  String get providerId => anthropicProviderId;

  @override
  String get displayName => 'Anthropic';

  @override
  String get description => 'Anthropic Claude models (Messages API)';

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.toolCalling,
        LLMCapability.reasoning,
        LLMCapability.vision,
        LLMCapability.modelListing,
        LLMCapability.fileManagement,
      };

  @override
  ChatCapability create(LLMConfig config) {
    return createProviderSafely<AnthropicConfig>(
      config,
      () => AnthropicConfig.fromLLMConfig(config),
      (anthropicConfig) => AnthropicProvider(anthropicConfig),
    );
  }

  @override
  bool validateConfig(LLMConfig config) {
    return validateApiKey(config) &&
        config.baseUrl.isNotEmpty &&
        config.model.isNotEmpty;
  }

  @override
  Map<String, dynamic> getProviderDefaults() {
    return {
      'baseUrl': anthropicBaseUrl,
      'model': anthropicDefaultModel,
    };
  }
}
