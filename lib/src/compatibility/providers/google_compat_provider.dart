import 'package:llm_dart_google/llm_dart_google.dart' as modern_google;

import '../../../core/capability.dart';
import '../../../core/config.dart';
import '../../../core/web_search.dart';
import '../../../models/chat_models.dart';
import '../../../providers/google/config.dart';
import '../chat_route_compatibility.dart';
import '../compat_transport.dart';
import '../legacy_chat_adapter.dart';
import 'compat_provider_support.dart';
import 'google_config_adapter.dart';
import 'google/provider_compat.dart';

part 'google_compat_provider_adapter_support.dart';

ChatCapability buildCompatGoogleProvider(LLMConfig config) {
  final legacyConfig = createLegacyGoogleConfig(config);
  final modernProvider = modern_google.Google(
    apiKey: config.apiKey!,
    baseUrl: config.baseUrl,
    transport: createCompatTransport(config),
  );

  return CompatGoogleProvider(
    originalConfig: config,
    legacyConfig: legacyConfig,
    adapter: const _GoogleCompatAdapterSupport().buildAdapter(
      originalConfig: config,
      legacyConfig: legacyConfig,
      modernProvider: modernProvider,
    ),
  );
}

final class CompatGoogleProvider extends GoogleProvider
    with CompatChatBridgeRoutingMixin {
  @override
  final CompatChatBridgeRouter compatChatRouter;

  CompatGoogleProvider({
    required LLMConfig originalConfig,
    required GoogleConfig legacyConfig,
    required LegacyChatCapabilityAdapter adapter,
  })  : compatChatRouter = CompatChatBridgeRouter(
          originalConfig: originalConfig,
          adapter: adapter,
          canUseBridge: canUseGoogleChatBridge,
        ),
        super(legacyConfig);
}
