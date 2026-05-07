import 'package:llm_dart_google/llm_dart_google.dart' as modern_google;

import '../../../core/capability.dart';
import '../../../core/config.dart';
import '../../../core/web_search.dart';
import '../../../models/chat_models.dart';
import '../../../models/tool_models.dart';
import '../../../providers/google/config.dart';
import '../chat_route_compatibility.dart';
import '../compat_transport.dart';
import '../legacy_chat_adapter.dart';
import 'compat_provider_support.dart';
import 'google_config_adapter.dart';
import 'google/provider_compat.dart';

part 'google_compat_provider_adapter_support.dart';
part 'google_compat_provider_chat_router.dart';

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

final class CompatGoogleProvider extends GoogleProvider {
  final LLMConfig _originalConfig;
  final LegacyChatCapabilityAdapter _adapter;
  late final _GoogleCompatChatRouter _chatRouter = _GoogleCompatChatRouter(
    originalConfig: _originalConfig,
    adapter: _adapter,
    fallbackChatWithTools: _fallbackChatWithTools,
    fallbackChatStream: _fallbackChatStream,
  );

  CompatGoogleProvider({
    required LLMConfig originalConfig,
    required GoogleConfig legacyConfig,
    required LegacyChatCapabilityAdapter adapter,
  })  : _originalConfig = originalConfig,
        _adapter = adapter,
        super(legacyConfig);

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    TransportCancellation? cancelToken,
  }) {
    return chatWithTools(messages, null, cancelToken: cancelToken);
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    TransportCancellation? cancelToken,
  }) {
    return _chatRouter.chatWithTools(
      messages,
      tools,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    TransportCancellation? cancelToken,
  }) {
    return _chatRouter.chatStream(
      messages,
      tools: tools,
      cancelToken: cancelToken,
    );
  }

  Future<ChatResponse> _fallbackChatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    TransportCancellation? cancelToken,
  }) {
    return super.chatWithTools(
      messages,
      tools,
      cancelToken: cancelToken,
    );
  }

  Stream<ChatStreamEvent> _fallbackChatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    TransportCancellation? cancelToken,
  }) {
    return super.chatStream(
      messages,
      tools: tools,
      cancelToken: cancelToken,
    );
  }
}
