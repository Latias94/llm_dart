import 'package:llm_dart_openai/llm_dart_openai.dart' as modern_openai;

import '../../../core/capability.dart';
import '../../../core/config.dart';
import '../../../providers/groq/config.dart';
import '../../../providers/groq/provider.dart';
import '../chat_route_compatibility.dart';
import '../legacy_chat_adapter.dart';
import 'compat_provider_support.dart';
import 'openai_family_compat_chat_bridge.dart';
import 'openai_family_compat_groq_config.dart';

ChatCapability buildCompatGroqProvider(LLMConfig config) {
  final legacyConfig = createLegacyGroqConfig(config);

  return CompatGroqProvider(
    originalConfig: config,
    legacyConfig: legacyConfig,
    adapter: buildOpenAIFamilyLegacyChatAdapter(
      config: config,
      profile: const modern_openai.GroqProfile(),
    ),
  );
}

final class CompatGroqProvider extends GroqProvider
    with CompatChatBridgeRoutingMixin {
  @override
  final CompatChatBridgeRouter compatChatRouter;

  CompatGroqProvider({
    required LLMConfig originalConfig,
    required GroqConfig legacyConfig,
    required LegacyChatCapabilityAdapter adapter,
  })  : compatChatRouter = CompatChatBridgeRouter(
          originalConfig: originalConfig,
          adapter: adapter,
          canUseBridge: canUseGroqChatBridge,
        ),
        super(legacyConfig);
}
