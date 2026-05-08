import '../../../core/capability.dart';
import '../../../core/config.dart';
import '../../../providers/openai/config.dart';
import '../chat_route_compatibility.dart';
import '../legacy_chat_adapter.dart';
import 'compat_provider_support.dart';
import 'openai/bridge_support.dart';
import 'openai/provider_compat.dart';
import 'openai_family_compat_openai_config.dart';

ChatCapability buildCompatOpenAIProvider(LLMConfig config) {
  final legacyConfig = toCompatLegacyOpenAIConfig(config);

  return CompatOpenAIProvider(
    originalConfig: config,
    legacyConfig: legacyConfig,
    adapter: buildCompatOpenAIChatBridge(
      legacyConfig: legacyConfig,
      bridgeConfig: config,
    ),
  );
}

final class CompatOpenAIProvider extends OpenAIProvider
    with CompatChatBridgeRoutingMixin {
  @override
  final CompatChatBridgeRouter compatChatRouter;

  CompatOpenAIProvider({
    required LLMConfig originalConfig,
    required OpenAIConfig legacyConfig,
    required LegacyChatCapabilityAdapter adapter,
  })  : compatChatRouter = CompatChatBridgeRouter(
          originalConfig: originalConfig,
          adapter: adapter,
          canUseBridge: canUseOpenAIChatBridge,
        ),
        super(legacyConfig);
}
