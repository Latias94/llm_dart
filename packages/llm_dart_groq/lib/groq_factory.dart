library;

import 'package:llm_dart_core/core/capability.dart';
import 'package:llm_dart_core/core/config.dart';
import 'package:llm_dart_core/core/provider_defaults.dart';
import 'package:llm_dart_core/core/registry.dart';
import 'package:llm_dart_provider_utils/factories/base_factory.dart';

import 'groq.dart';

const String groqProviderId = 'groq';

void registerGroq({bool replace = false}) {
  if (!replace && LLMProviderRegistry.isRegistered(groqProviderId)) return;
  final factory = GroqProviderFactory();
  if (replace) {
    LLMProviderRegistry.registerOrReplace(factory);
    return;
  }
  LLMProviderRegistry.register(factory);
}

class GroqProviderFactory extends BaseProviderFactory<ChatCapability> {
  @override
  String get providerId => groqProviderId;

  @override
  String get displayName => 'Groq';

  @override
  String get description => 'Groq AI models for ultra-fast inference';

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.toolCalling,
        LLMCapability.vision,
        LLMCapability.reasoning,
      };

  @override
  ChatCapability create(LLMConfig config) {
    return createProviderSafely<GroqConfig>(
      config,
      () => _transformConfig(config),
      (groqConfig) => GroqProvider(groqConfig),
    );
  }

  @override
  Map<String, dynamic> getProviderDefaults() {
    return ProviderDefaults.getDefaults(groqProviderId);
  }

  GroqConfig _transformConfig(LLMConfig config) {
    return GroqConfig.fromLLMConfig(config);
  }
}
