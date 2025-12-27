library;

import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_core/core/capability.dart';
import 'package:llm_dart_core/core/config.dart';
import 'package:llm_dart_core/core/llm_error.dart';
import 'package:llm_dart_core/core/registry.dart';

import 'acme.dart';
import 'acme_chat.dart';

/// Register the Acme provider in the global [LLMProviderRegistry].
void registerAcme({bool replace = false}) {
  if (!replace && LLMProviderRegistry.isRegistered(acmeProviderId)) return;
  final factory = AcmeProviderFactory();
  if (replace) {
    LLMProviderRegistry.registerOrReplace(factory);
    return;
  }
  LLMProviderRegistry.register(factory);
}

/// Factory for creating Acme provider instances (Anthropic-compatible).
class AcmeProviderFactory extends LLMProviderFactory<ChatCapability> {
  @override
  String get providerId => acmeProviderId;

  @override
  Set<LLMCapability> get supportedCapabilities => acmeSupportedCapabilities;

  @override
  ChatCapability create(LLMConfig config) {
    if (!validateConfig(config)) {
      throw InvalidRequestError(
        'Invalid configuration for provider: $providerId',
      );
    }

    final normalized = config.copyWith(
      baseUrl: normalizeAcmeAnthropicBaseUrl(config.baseUrl),
    );

    final anthropicConfig = AnthropicConfig.fromLLMConfig(
      normalized,
      providerOptionsNamespace: providerId,
    );

    final client = AnthropicClient(
      anthropicConfig,
      strategy: AnthropicDioStrategy(providerName: 'Acme'),
    );
    return AcmeChat(client, anthropicConfig);
  }

  @override
  bool validateConfig(LLMConfig config) {
    return config.apiKey != null &&
        config.apiKey!.isNotEmpty &&
        config.baseUrl.isNotEmpty &&
        config.model.isNotEmpty;
  }

  @override
  LLMConfig getDefaultConfig() {
    return const LLMConfig(
      baseUrl: acmeAnthropicBaseUrl,
      model: acmeDefaultModel,
    );
  }
}
