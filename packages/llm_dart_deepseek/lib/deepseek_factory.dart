library;

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import 'defaults.dart';
import 'deepseek.dart';

/// DeepSeek provider id used in the core registry.
const String deepseekProviderId = 'deepseek';

/// Register the DeepSeek provider in the global [LLMProviderRegistry].
///
/// - If [replace] is false (default), registration is idempotent and will
///   not override an existing provider registered under the same id.
/// - If [replace] is true, the existing registration (if any) is replaced.
void registerDeepSeek({bool replace = false}) {
  if (!replace && LLMProviderRegistry.isRegistered(deepseekProviderId)) return;
  final factory = DeepSeekProviderFactory();
  if (replace) {
    LLMProviderRegistry.registerOrReplace(factory);
    return;
  }
  LLMProviderRegistry.register(factory);
}

/// Factory for creating DeepSeek provider instances.
class DeepSeekProviderFactory extends BaseProviderFactory<ChatCapability> {
  @override
  String get providerId => deepseekProviderId;

  @override
  String get displayName => 'DeepSeek';

  @override
  String get description =>
      'DeepSeek AI models including DeepSeek Chat and reasoning models';

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.toolCalling,
        LLMCapability.reasoning,
        LLMCapability.vision,
        LLMCapability.modelListing,
      };

  @override
  ChatCapability create(LLMConfig config) {
    return createProviderSafely<DeepSeekConfig>(
      config,
      () => _transformConfig(config),
      (deepseekConfig) => DeepSeekProvider(deepseekConfig),
    );
  }

  @override
  Map<String, dynamic> getProviderDefaults() {
    return {
      'baseUrl': deepseekBaseUrl,
      'model': deepseekDefaultModel,
    };
  }

  /// Transform unified config to DeepSeek-specific config.
  DeepSeekConfig _transformConfig(LLMConfig config) {
    return DeepSeekConfig.fromLLMConfig(config);
  }
}
