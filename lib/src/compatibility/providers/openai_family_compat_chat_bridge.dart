import 'package:llm_dart_openai/llm_dart_openai.dart' as modern_openai;
import 'package:llm_dart_provider/llm_dart_provider.dart' as provider_core;

import '../../../core/config.dart';
import '../compat_transport.dart';
import '../legacy_chat_adapter.dart';

LegacyChatCapabilityAdapter buildOpenAIFamilyLegacyChatAdapter({
  required LLMConfig config,
  required modern_openai.OpenAIFamilyProfile profile,
  provider_core.ProviderModelOptions? modelSettings,
  provider_core.ProviderInvocationOptions? providerOptions,
  String? providerOptionsNamespace,
}) {
  final openAI = modern_openai.OpenAI(
    apiKey: config.apiKey!,
    baseUrl: config.baseUrl,
    transport: createCompatTransport(config),
    profile: profile,
  );
  final model = modelSettings == null
      ? openAI.chatModel(config.model)
      : openAI.chatModel(config.model, settings: modelSettings);

  return LegacyChatCapabilityAdapter(
    model: model,
    config: config,
    providerOptionsNamespace: providerOptionsNamespace,
    providerOptions: providerOptions,
  );
}
