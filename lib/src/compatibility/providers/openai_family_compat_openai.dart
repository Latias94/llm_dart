import '../../../core/capability.dart';
import '../../../core/config.dart';
import '../../../models/chat_models.dart';
import '../../../models/tool_models.dart';
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

final class CompatOpenAIProvider extends OpenAIProvider {
  final CompatChatBridgeRouter _chatRouter;

  CompatOpenAIProvider({
    required LLMConfig originalConfig,
    required OpenAIConfig legacyConfig,
    required LegacyChatCapabilityAdapter adapter,
  })  : _chatRouter = CompatChatBridgeRouter(
          originalConfig: originalConfig,
          adapter: adapter,
          canUseBridge: canUseOpenAIChatBridge,
        ),
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
      messages: messages,
      tools: tools,
      cancelToken: cancelToken,
      fallback: () => super.chatWithTools(
        messages,
        tools,
        cancelToken: cancelToken,
      ),
    );
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    TransportCancellation? cancelToken,
  }) {
    return _chatRouter.chatStream(
      messages: messages,
      tools: tools,
      cancelToken: cancelToken,
      fallback: () => super.chatStream(
        messages,
        tools: tools,
        cancelToken: cancelToken,
      ),
    );
  }
}
