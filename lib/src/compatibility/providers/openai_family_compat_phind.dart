import 'package:llm_dart_openai/llm_dart_openai.dart' as modern_openai;

import '../../../core/capability.dart';
import '../../../core/config.dart';
import '../../../models/chat_models.dart';
import '../../../models/tool_models.dart';
import '../../../providers/phind/config.dart';
import '../../../providers/phind/provider.dart';
import '../chat_route_compatibility.dart';
import '../compat_transport.dart';
import '../legacy_chat_adapter.dart';
import 'compat_provider_support.dart';

ChatCapability buildCompatPhindProvider(LLMConfig config) {
  final legacyConfig = PhindConfig.fromLLMConfig(config);
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

final class CompatPhindProvider extends PhindProvider {
  final LLMConfig _originalConfig;
  final LegacyChatCapabilityAdapter _adapter;

  CompatPhindProvider({
    required LLMConfig originalConfig,
    required PhindConfig legacyConfig,
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
    return executeCompatChat(
      originalConfig: _originalConfig,
      messages: messages,
      tools: tools,
      canUseBridge: canUsePhindChatBridge,
      bridge: () => _adapter.chatWithTools(
        messages,
        tools,
        cancelToken: cancelToken,
      ),
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
    return executeCompatChatStream(
      originalConfig: _originalConfig,
      messages: messages,
      tools: tools,
      canUseBridge: canUsePhindChatBridge,
      bridge: () => _adapter.chatStream(
        messages,
        tools: tools,
        cancelToken: cancelToken,
      ),
      fallback: () => super.chatStream(
        messages,
        tools: tools,
        cancelToken: cancelToken,
      ),
    );
  }
}
