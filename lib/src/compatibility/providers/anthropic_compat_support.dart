import 'package:llm_dart_anthropic/llm_dart_anthropic.dart' as modern_anthropic;
import 'package:llm_dart_provider/llm_dart_provider.dart' as core;

import '../../../models/chat_models.dart';
import '../../../models/tool_models.dart';
import '../anthropic_legacy_extensions.dart';

part 'anthropic_compat_message_converter.dart';
part 'anthropic_compat_message_roles.dart';
part 'anthropic_compat_prompt_parts.dart';
part 'anthropic_compat_request_planner.dart';
part 'anthropic_compat_tool_results.dart';

/// Provider-local support for Anthropic compatibility request planning and
/// role-aware prompt conversion.
///
/// This keeps the adapter focused on bridging `LegacyChatCapabilityAdapter`
/// while localizing Anthropic-specific cache, tool replay, and prompt shaping
/// rules in one provider-owned place.
final class AnthropicCompatAdapterSupport {
  static const _requestPlanner = _AnthropicCompatRequestPlanner();
  static const _messageConverter = _AnthropicCompatMessageConverter();

  const AnthropicCompatAdapterSupport();

  AnthropicCompatRequestPlan buildRequestPlan({
    required List<ChatMessage> messages,
    required List<Tool>? tools,
    required List<Tool>? configTools,
    required core.ProviderInvocationOptions? providerOptions,
  }) {
    return _requestPlanner.buildRequestPlan(
      messages: messages,
      tools: tools,
      configTools: configTools,
      providerOptions: providerOptions,
    );
  }

  List<core.PromptMessage> convertMessages({
    required List<ChatMessage> messages,
    required String? systemPrompt,
    required List<core.PromptMessage> Function(ChatMessage message)
        convertTrackedMessage,
  }) {
    return _messageConverter.convertMessages(
      messages: messages,
      systemPrompt: systemPrompt,
      convertTrackedMessage: convertTrackedMessage,
    );
  }
}

final class AnthropicCompatRequestPlan {
  final List<Tool> effectiveTools;
  final modern_anthropic.AnthropicGenerateTextOptions providerOptions;

  const AnthropicCompatRequestPlan({
    required this.effectiveTools,
    required this.providerOptions,
  });
}
