library;

import 'package:llm_dart_core/core/capability.dart';
import 'package:llm_dart_core/core/config.dart';
import 'package:llm_dart_core/core/provider_defaults.dart';
import 'package:llm_dart_core/core/registry.dart';
import 'package:llm_dart_provider_utils/factories/base_factory.dart';

import 'config.dart';
import 'provider.dart';

const String ollamaProviderId = 'ollama';

void registerOllama({bool replace = false}) {
  if (!replace && LLMProviderRegistry.isRegistered(ollamaProviderId)) return;
  final factory = OllamaProviderFactory();
  if (replace) {
    LLMProviderRegistry.registerOrReplace(factory);
    return;
  }
  LLMProviderRegistry.register(factory);
}

class OllamaProviderFactory extends LocalProviderFactory<ChatCapability> {
  @override
  String get providerId => ollamaProviderId;

  @override
  String get displayName => 'Ollama';

  @override
  String get description =>
      'Ollama local LLM provider for self-hosted open source models';

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.completion,
        LLMCapability.embedding,
        LLMCapability.modelListing,
        LLMCapability.reasoning,
        LLMCapability.toolCalling,
        LLMCapability.vision,
      };

  @override
  ChatCapability create(LLMConfig config) {
    return createProviderSafely<OllamaConfig>(
      config,
      () => _transformConfig(config),
      (ollamaConfig) => OllamaProvider(ollamaConfig),
    );
  }

  @override
  Map<String, dynamic> getProviderDefaults() {
    return ProviderDefaults.getDefaults(ollamaProviderId);
  }

  OllamaConfig _transformConfig(LLMConfig config) {
    return OllamaConfig.fromLLMConfig(config);
  }
}
