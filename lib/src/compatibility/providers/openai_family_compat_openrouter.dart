import 'package:llm_dart_openai/llm_dart_openai.dart' as modern_openai;

import '../../../core/capability.dart';
import '../../../core/config.dart';
import '../../../providers/openai/config.dart';
import '../chat_route_compatibility.dart';
import '../config/legacy_openai_options.dart';
import '../config/legacy_provider_options.dart';
import '../legacy_chat_adapter.dart';
import 'compat_provider_support.dart';
import 'openai/provider_compat.dart';
import 'openai_family_compat_chat_bridge.dart';
import 'openai_family_compat_openrouter_config.dart';

ChatCapability buildCompatOpenRouterProvider(LLMConfig config) {
  final legacyConfig = toCompatLegacyOpenRouterConfig(config);
  final options = legacyProviderOptionView(
    config,
    LegacyProviderOptionNamespaces.openrouter,
  );
  final familyOptions = legacyOpenAIFamilyOptions(options);

  return CompatOpenRouterProvider(
    originalConfig: config,
    legacyConfig: legacyConfig,
    adapter: buildOpenAIFamilyLegacyChatAdapter(
      config: config,
      profile: const modern_openai.OpenRouterProfile(),
      modelSettings: buildCompatOpenRouterModelSettings(config),
      providerOptionsNamespace: LegacyProviderOptionNamespaces.openrouter,
      providerOptions: modern_openai.OpenRouterGenerateTextOptions(
        common: modern_openai.OpenAIGenerateTextOptions(
          parallelToolCalls: familyOptions.parallelToolCalls,
          serviceTier: config.serviceTier?.value,
          verbosity: familyOptions.verbosity,
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
