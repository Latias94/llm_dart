import 'package:llm_dart_openai/llm_dart_openai.dart' as modern_openai;

import '../../../core/capability.dart';
import '../../../core/config.dart';
import '../../../providers/xai/config.dart';
import '../../../providers/xai/provider.dart';
import '../chat_route_compatibility.dart';
import '../config/legacy_provider_options.dart';
import '../legacy_chat_adapter.dart';
import 'compat_provider_support.dart';
import 'openai_family_compat_chat_bridge.dart';
import 'openai_family_compat_xai_config.dart';

ChatCapability buildCompatXAIProvider(LLMConfig config) {
  final legacyConfig = createLegacyXAIConfig(config);

  return CompatXAIProvider(
    originalConfig: config,
    legacyConfig: legacyConfig,
    adapter: buildOpenAIFamilyLegacyChatAdapter(
      config: config,
      profile: const modern_openai.XAIProfile(),
      providerOptionsNamespace: LegacyProviderOptionNamespaces.xai,
      providerOptions: modern_openai.XAIGenerateTextOptions(
        common: const modern_openai.OpenAIGenerateTextOptions(),
        search: buildCompatXAILiveSearchOptions(legacyConfig),
      ),
    ),
  );
}

final class CompatXAIProvider extends XAIProvider
    with CompatChatBridgeRoutingMixin {
  @override
  final CompatChatBridgeRouter compatChatRouter;

  CompatXAIProvider({
    required LLMConfig originalConfig,
    required XAIConfig legacyConfig,
    required LegacyChatCapabilityAdapter adapter,
  })  : compatChatRouter = CompatChatBridgeRouter(
          originalConfig: originalConfig,
          adapter: adapter,
          canUseBridge: canUseXAIChatBridge,
        ),
        super(legacyConfig);
}
