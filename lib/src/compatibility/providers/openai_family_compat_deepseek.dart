import 'package:llm_dart_openai/llm_dart_openai.dart' as modern_openai;

import '../../../core/capability.dart';
import '../../../core/config.dart';
import '../../../providers/deepseek/config.dart';
import '../../../providers/deepseek/provider.dart';
import '../chat_route_compatibility.dart';
import '../config/legacy_provider_options.dart';
import '../compat_transport.dart';
import '../legacy_chat_adapter.dart';
import 'compat_provider_support.dart';
import 'openai_family_compat_deepseek_config.dart';

ChatCapability buildCompatDeepSeekProvider(LLMConfig config) {
  final legacyConfig = createLegacyDeepSeekConfig(config);
  final model = modern_openai.OpenAI(
    apiKey: config.apiKey!,
    baseUrl: config.baseUrl,
    transport: createCompatTransport(config),
    profile: const modern_openai.DeepSeekProfile(),
  ).chatModel(config.model);

  return CompatDeepSeekProvider(
    originalConfig: config,
    legacyConfig: legacyConfig,
    adapter: LegacyChatCapabilityAdapter(
      model: model,
      config: config,
      providerOptionsNamespace: LegacyProviderOptionNamespaces.deepseek,
      providerOptions: buildCompatDeepSeekInvocationOptions(legacyConfig),
    ),
  );
}

modern_openai.DeepSeekGenerateTextOptions buildCompatDeepSeekInvocationOptions(
  DeepSeekConfig config,
) {
  return modern_openai.DeepSeekGenerateTextOptions(
    logprobs: config.logprobs,
    topLogprobs: config.topLogprobs,
    frequencyPenalty: config.frequencyPenalty,
    presencePenalty: config.presencePenalty,
    responseFormat: config.responseFormat == null
        ? null
        : Map<String, Object?>.from(config.responseFormat!),
  );
}

final class CompatDeepSeekProvider extends DeepSeekProvider
    with CompatChatBridgeRoutingMixin {
  @override
  final CompatChatBridgeRouter compatChatRouter;

  CompatDeepSeekProvider({
    required LLMConfig originalConfig,
    required DeepSeekConfig legacyConfig,
    required LegacyChatCapabilityAdapter adapter,
  })  : compatChatRouter = CompatChatBridgeRouter(
          originalConfig: originalConfig,
          adapter: adapter,
          canUseBridge: canUseDeepSeekChatBridge,
        ),
        super(legacyConfig);
}
