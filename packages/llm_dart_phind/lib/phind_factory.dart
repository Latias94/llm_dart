library;

import 'package:llm_dart_core/core/capability.dart';
import 'package:llm_dart_core/core/config.dart';
import 'package:llm_dart_core/core/registry.dart';
import 'package:llm_dart_provider_utils/factories/base_factory.dart';

import 'defaults.dart';
import 'phind.dart';

const String phindProviderId = 'phind';

void registerPhind({bool replace = false}) {
  if (!replace && LLMProviderRegistry.isRegistered(phindProviderId)) return;
  final factory = PhindProviderFactory();
  if (replace) {
    LLMProviderRegistry.registerOrReplace(factory);
    return;
  }
  LLMProviderRegistry.register(factory);
}

class PhindProviderFactory extends BaseProviderFactory<ChatCapability> {
  @override
  String get providerId => phindProviderId;

  @override
  String get displayName => 'Phind';

  @override
  String get description =>
      'Phind AI models specialized for coding assistance and development tasks';

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.toolCalling,
      };

  @override
  ChatCapability create(LLMConfig config) {
    return createProviderSafely<PhindConfig>(
      config,
      () => _transformConfig(config),
      (phindConfig) => PhindProvider(phindConfig),
    );
  }

  @override
  Map<String, dynamic> getProviderDefaults() {
    return {
      'baseUrl': phindBaseUrl,
      'model': phindDefaultModel,
    };
  }

  PhindConfig _transformConfig(LLMConfig config) {
    return PhindConfig.fromLLMConfig(config);
  }
}
