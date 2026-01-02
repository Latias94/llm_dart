library;

import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_anthropic_compatible/client.dart';
import 'package:llm_dart_anthropic_compatible/dio_strategy.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

import 'acme_chat.dart';

/// Provider id used for registry + providerOptions namespace.
const String acmeProviderId = 'acme';

/// Acme Anthropic-compatible base URL (example).
const String acmeAnthropicBaseUrl = 'https://api.acme.com/anthropic/v1/';

/// Default model (example).
const String acmeDefaultModel = 'Acme-M2';

/// Default capability set for Acme text generation via Anthropic-compatible API.
const Set<LLMCapability> acmeSupportedCapabilities = {
  LLMCapability.chat,
  LLMCapability.streaming,
  LLMCapability.toolCalling,
};

/// Create an Acme chat provider using the Anthropic-compatible Messages API.
ChatCapability createAcmeProvider({
  required String apiKey,
  String model = acmeDefaultModel,
  String baseUrl = acmeAnthropicBaseUrl,
  int? maxTokens,
  double? temperature,
  String? systemPrompt,
  Duration? timeout,
}) {
  final normalizedConfig = LLMConfig(
    apiKey: apiKey,
    baseUrl: normalizeAcmeAnthropicBaseUrl(baseUrl),
    model: model,
    maxTokens: maxTokens,
    temperature: temperature,
    systemPrompt: systemPrompt,
    timeout: timeout,
  );

  final anthropicConfig = AnthropicConfig.fromLLMConfig(
    normalizedConfig,
    providerOptionsNamespace: acmeProviderId,
  );

  final client = AnthropicClient(
    anthropicConfig,
    strategy: AnthropicDioStrategy(providerName: 'Acme'),
  );
  return AcmeChat(client, anthropicConfig);
}

/// Normalize an Anthropic-compatible base URL.
///
/// Many docs use `.../anthropic` (without `/v1`). Our protocol implementation
/// expects a `/v1/` base and uses paths like `messages`.
String normalizeAcmeAnthropicBaseUrl(String baseUrl) {
  return normalizeAnthropicCompatibleBaseUrl(baseUrl);
}
