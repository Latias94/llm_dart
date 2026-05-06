import 'package:llm_dart_core/model.dart' as core;

import '../../../models/chat_models.dart';
import '../../../models/tool_models.dart';
import '../legacy_chat_adapter.dart';
import 'anthropic_compat_support.dart';

final class AnthropicLegacyChatCapabilityAdapter
    extends LegacyChatCapabilityAdapter {
  final AnthropicCompatAdapterSupport _support =
      const AnthropicCompatAdapterSupport();

  const AnthropicLegacyChatCapabilityAdapter({
    required super.model,
    required super.config,
    super.providerOptions,
  });

  @override
  core.GenerateTextRequest buildRequest(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    core.ProviderInvocationOptions? providerOptionsOverride,
  }) {
    final requestPlan = _support.buildRequestPlan(
      messages: messages,
      tools: tools,
      configTools: config.tools,
      providerOptions: providerOptionsOverride ?? providerOptions,
    );

    return super.buildRequest(
      messages,
      requestPlan.effectiveTools,
      providerOptionsOverride: requestPlan.providerOptions,
    );
  }

  @override
  List<core.PromptMessage> convertMessages(List<ChatMessage> messages) {
    List<core.PromptMessage> convertTrackedMessage(ChatMessage message) {
      return super.convertMessage(message);
    }

    return _support.convertMessages(
      messages: messages,
      systemPrompt: config.systemPrompt,
      convertTrackedMessage: convertTrackedMessage,
    );
  }
}
