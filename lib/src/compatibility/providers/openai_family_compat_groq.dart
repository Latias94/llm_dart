import 'package:llm_dart_openai/llm_dart_openai.dart' as modern_openai;

import '../../../core/capability.dart';
import '../../../core/config.dart';
import '../../../providers/groq/config.dart';
import '../../../providers/groq/provider.dart';
import '../chat_route_compatibility.dart';
import '../compat_transport.dart';
import '../legacy_chat_adapter.dart';
import 'compat_provider_support.dart';
import 'openai_family_compat_groq_config.dart';

ChatCapability buildCompatGroqProvider(LLMConfig config) {
  final legacyConfig = createLegacyGroqConfig(config);
  final model = modern_openai.OpenAI(
    apiKey: config.apiKey!,
    baseUrl: config.baseUrl,
    transport: createCompatTransport(config),
    profile: const modern_openai.GroqProfile(),
  ).chatModel(config.model);

  return CompatGroqProvider(
    originalConfig: config,
    legacyConfig: legacyConfig,
    adapter: LegacyChatCapabilityAdapter(
      model: model,
      config: config,
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
