import 'package:llm_dart_openai/llm_dart_openai.dart' as modern_openai;

import '../../../core/capability.dart';
import '../../../core/config.dart';
import '../../../providers/phind/config.dart';
import '../../../providers/phind/provider.dart';
import '../chat_route_compatibility.dart';
import '../compat_transport.dart';
import '../legacy_chat_adapter.dart';
import 'compat_provider_support.dart';
import 'openai_family_compat_phind_config.dart';

ChatCapability buildCompatPhindProvider(LLMConfig config) {
  final legacyConfig = createLegacyPhindConfig(config);
  final model = modern_openai.OpenAI(
    apiKey: config.apiKey!,
    baseUrl: config.baseUrl,
    transport: createCompatTransport(config),
    profile: const modern_openai.PhindProfile(),
  ).chatModel(config.model);

  return CompatPhindProvider(
    originalConfig: config,
    legacyConfig: legacyConfig,
    adapter: LegacyChatCapabilityAdapter(
      model: model,
      config: config,
    ),
  );
}

final class CompatPhindProvider extends PhindProvider
    with CompatChatBridgeRoutingMixin {
  @override
  final CompatChatBridgeRouter compatChatRouter;

  CompatPhindProvider({
    required LLMConfig originalConfig,
    required PhindConfig legacyConfig,
    required LegacyChatCapabilityAdapter adapter,
  })  : compatChatRouter = CompatChatBridgeRouter(
          originalConfig: originalConfig,
          adapter: adapter,
          canUseBridge: canUsePhindChatBridge,
        ),
        super(legacyConfig);
}
