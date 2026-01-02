library;

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import 'defaults.dart';
import 'xai.dart';

const String xaiProviderId = 'xai';
const String xaiResponsesProviderId = 'xai.responses';

void registerXAI({bool replace = false}) {
  final factory = XAIProviderFactory();
  final responsesFactory = XAIResponsesProviderFactory();

  final hasXai = LLMProviderRegistry.isRegistered(xaiProviderId);
  final hasResponses = LLMProviderRegistry.isRegistered(xaiResponsesProviderId);

  if (!replace && hasXai && hasResponses) return;

  if (replace) {
    LLMProviderRegistry.registerOrReplace(factory);
    LLMProviderRegistry.registerOrReplace(responsesFactory);
    return;
  }

  if (!hasXai) {
    LLMProviderRegistry.register(factory);
  }

  if (!hasResponses) {
    LLMProviderRegistry.register(responsesFactory);
  }
}

/// Factory for creating xAI provider instances.
class XAIProviderFactory extends BaseProviderFactory<ChatCapability> {
  @override
  String get providerId => xaiProviderId;

  @override
  String get displayName => 'xAI (Grok)';

  @override
  String get description =>
      'xAI Grok models with search and reasoning capabilities';

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.toolCalling,
        LLMCapability.reasoning,
        LLMCapability.liveSearch,
        LLMCapability.embedding,
        LLMCapability.vision,
      };

  @override
  ChatCapability create(LLMConfig config) {
    return createProviderSafely<XAIConfig>(
      config,
      () => _transformConfig(config),
      (xaiConfig) => XAIProvider(xaiConfig),
    );
  }

  @override
  Map<String, dynamic> getProviderDefaults() {
    return {
      'baseUrl': xaiBaseUrl,
      'model': xaiDefaultModel,
    };
  }

  XAIConfig _transformConfig(LLMConfig config) {
    return XAIConfig.fromLLMConfig(config);
  }
}

/// Factory for creating xAI Responses provider instances.
class XAIResponsesProviderFactory extends BaseProviderFactory<ChatCapability> {
  @override
  String get providerId => xaiResponsesProviderId;

  @override
  String get displayName => 'xAI (Responses)';

  @override
  String get description =>
      'xAI Grok models via the Responses API (agentic tools)';

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.toolCalling,
        LLMCapability.reasoning,
        LLMCapability.liveSearch,
        LLMCapability.openaiResponses,
        LLMCapability.vision,
      };

  @override
  ChatCapability create(LLMConfig config) {
    return XAIResponsesProvider(config);
  }

  @override
  Map<String, dynamic> getProviderDefaults() {
    return {
      'baseUrl': xaiBaseUrl,
      'model': xaiDefaultModel,
    };
  }
}
