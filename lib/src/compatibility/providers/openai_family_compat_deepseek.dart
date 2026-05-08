import 'package:llm_dart_openai/llm_dart_openai.dart' as modern_openai;

import '../../../core/capability.dart';
import '../../../core/config.dart';
import '../../../models/chat_models.dart';
import '../../../models/tool_models.dart';
import '../../../providers/deepseek/config.dart';
import '../../../providers/deepseek/provider.dart';
import '../chat_route_compatibility.dart';
import '../config/legacy_provider_options.dart';
import '../compat_transport.dart';
import '../legacy_chat_adapter.dart';
import 'compat_provider_support.dart';
import 'openai_family_compat_deepseek_config.dart';

ChatCapability buildCompatDeepSeekProvider(LLMConfig config) {
  final legacyConfig = createLegacyDeepSeekConfig(config);
  final model = modern_openai.OpenAI(
    apiKey: config.apiKey!,
    baseUrl: config.baseUrl,
    transport: createCompatTransport(config),
    profile: const modern_openai.DeepSeekProfile(),
  ).chatModel(config.model);

  return CompatDeepSeekProvider(
    originalConfig: config,
    legacyConfig: legacyConfig,
    adapter: LegacyChatCapabilityAdapter(
      model: model,
      config: config,
      providerOptionsNamespace: LegacyProviderOptionNamespaces.deepseek,
      providerOptions: buildCompatDeepSeekInvocationOptions(legacyConfig),
    ),
  );
}

modern_openai.DeepSeekGenerateTextOptions buildCompatDeepSeekInvocationOptions(
  DeepSeekConfig config,
) {
  return modern_openai.DeepSeekGenerateTextOptions(
    logprobs: config.logprobs,
    topLogprobs: config.topLogprobs,
    frequencyPenalty: config.frequencyPenalty,
    presencePenalty: config.presencePenalty,
    responseFormat: config.responseFormat == null
        ? null
        : Map<String, Object?>.from(config.responseFormat!),
  );
}

final class CompatDeepSeekProvider extends DeepSeekProvider {
  final LLMConfig _originalConfig;
  final LegacyChatCapabilityAdapter _adapter;

  CompatDeepSeekProvider({
    required LLMConfig originalConfig,
    required DeepSeekConfig legacyConfig,
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
      canUseBridge: canUseDeepSeekChatBridge,
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
      canUseBridge: canUseDeepSeekChatBridge,
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
