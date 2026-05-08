import 'package:llm_dart_openai/llm_dart_openai.dart' as modern_openai;

import '../../../core/capability.dart';
import '../../../core/config.dart';
import '../../../providers/openai/config.dart';
import '../config/legacy_config_keys.dart';
import '../config/legacy_provider_options.dart';
import '../chat_route_compatibility.dart';
import '../compat_transport.dart';
import '../legacy_chat_adapter.dart';
import 'compat_provider_support.dart';
import 'openai/provider_compat.dart';
import 'openai_family_compat_openrouter_config.dart';

ChatCapability buildCompatOpenRouterProvider(LLMConfig config) {
  final legacyConfig = toCompatLegacyOpenRouterConfig(config);
  final options = legacyProviderOptionView(
    config,
    LegacyProviderOptionNamespaces.openrouter,
  );
  final model = modern_openai.OpenAI(
    apiKey: config.apiKey!,
    baseUrl: config.baseUrl,
    transport: createCompatTransport(config),
    profile: const modern_openai.OpenRouterProfile(),
  ).chatModel(
    config.model,
    settings: buildCompatOpenRouterModelSettings(config),
  );

  return CompatOpenRouterProvider(
    originalConfig: config,
    legacyConfig: legacyConfig,
    adapter: LegacyChatCapabilityAdapter(
      model: model,
      config: config,
      providerOptionsNamespace: LegacyProviderOptionNamespaces.openrouter,
      providerOptions: modern_openai.OpenRouterGenerateTextOptions(
        common: modern_openai.OpenAIGenerateTextOptions(
          parallelToolCalls: options.getWithFlatFallback<bool>(
            LegacyExtensionKeys.parallelToolCalls,
          ),
          serviceTier: config.serviceTier?.value,
          verbosity: options.getWithFlatFallback<String>(
            LegacyExtensionKeys.verbosity,
          ),
        ),
      ),
    ),
  );
}

final class CompatOpenRouterProvider extends OpenAIProvider
    with CompatChatBridgeRoutingMixin {
  @override
  final CompatChatBridgeRouter compatChatRouter;

  CompatOpenRouterProvider({
    required LLMConfig originalConfig,
    required OpenAIConfig legacyConfig,
    required LegacyChatCapabilityAdapter adapter,
  })  : compatChatRouter = CompatChatBridgeRouter(
          originalConfig: originalConfig,
          adapter: adapter,
          canUseBridge: canUseOpenRouterChatBridge,
        ),
        super(legacyConfig);
}
