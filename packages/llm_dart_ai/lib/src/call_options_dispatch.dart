import 'package:llm_dart_core/llm_dart_core.dart';

import 'prompt_input.dart';

/// Best-effort dispatch for chat calls with optional per-call overrides.
///
/// This centralizes the "if callOptions.isEmpty then use base capability else
/// require CallOptionsCapability" pattern so that higher-level APIs (generate,
/// tool loops, etc.) do not need to duplicate the branching logic.
Future<ChatResponse> chatWithToolsBestEffort({
  required ChatCapability model,
  required StandardizedPromptInput input,
  List<Tool>? tools,
  List<ProviderTool>? providerTools,
  required LLMCallOptions callOptions,
  CancelToken? cancelToken,
}) {
  switch (input) {
    case StandardizedChatMessages(:final messages):
      if (callOptions.isEmpty) {
        return model.chatWithTools(
          messages,
          tools,
          providerTools: providerTools,
          cancelToken: cancelToken,
        );
      }

      if (model is! ChatCallOptionsCapability) {
        throw const InvalidRequestError(
          'This model does not support call-level overrides (headers/body). '
          'Implement `ChatCallOptionsCapability` (or use a provider that does).',
        );
      }

      return (model as ChatCallOptionsCapability).chatWithToolsWithCallOptions(
        messages,
        tools,
        providerTools: providerTools,
        callOptions: callOptions,
        cancelToken: cancelToken,
      );

    case StandardizedPromptIr(:final prompt):
      if (model is PromptChatCapability) {
        if (callOptions.isEmpty) {
          return (model as PromptChatCapability).chatPrompt(
            prompt,
            providerTools: providerTools,
            tools: tools,
            cancelToken: cancelToken,
          );
        }

        if (model is! PromptChatCallOptionsCapability) {
          throw const InvalidRequestError(
            'This model does not support call-level overrides for Prompt IR. '
            'Implement `PromptChatCallOptionsCapability` (or use a provider that does).',
          );
        }

        return (model as PromptChatCallOptionsCapability)
            .chatPromptWithCallOptions(
          prompt,
          providerTools: providerTools,
          tools: tools,
          callOptions: callOptions,
          cancelToken: cancelToken,
        );
      }

      requirePromptCapabilityForFileReferenceParts(
        prompt: prompt,
        requiredCapabilityName: '`PromptChatCapability`',
      );

      return chatWithToolsBestEffort(
        model: model,
        input: StandardizedChatMessages(prompt.toChatMessages()),
        tools: tools,
        providerTools: providerTools,
        callOptions: callOptions,
        cancelToken: cancelToken,
      );
  }
}

/// Best-effort dispatch for parts-first streaming with optional per-call overrides.
Stream<LLMStreamPart> chatStreamPartsBestEffort({
  required ChatCapability model,
  required StandardizedPromptInput input,
  List<Tool>? tools,
  List<ProviderTool>? providerTools,
  required LLMCallOptions callOptions,
  CancelToken? cancelToken,
}) {
  switch (input) {
    case StandardizedChatMessages(:final messages):
      if (callOptions.isEmpty) {
        if (model is! ChatStreamPartsCapability) {
          throw UnsupportedError(
            'Model does not support parts-first streaming. Implement '
            '`ChatStreamPartsCapability.chatStreamParts()` (or use a provider that does).',
          );
        }
        return (model as ChatStreamPartsCapability).chatStreamParts(
          messages,
          tools: tools,
          providerTools: providerTools,
          cancelToken: cancelToken,
        );
      }

      if (model is! ChatStreamPartsCallOptionsCapability) {
        throw const InvalidRequestError(
          'This model does not support call-level overrides (headers/body) for streaming. '
          'Implement `ChatStreamPartsCallOptionsCapability` (or use a provider that does).',
        );
      }

      return (model as ChatStreamPartsCallOptionsCapability)
          .chatStreamPartsWithCallOptions(
        messages,
        tools: tools,
        providerTools: providerTools,
        callOptions: callOptions,
        cancelToken: cancelToken,
      );

    case StandardizedPromptIr(:final prompt):
      if (model is PromptChatStreamPartsCapability) {
        if (callOptions.isEmpty) {
          return (model as PromptChatStreamPartsCapability)
              .chatPromptStreamParts(
            prompt,
            tools: tools,
            providerTools: providerTools,
            cancelToken: cancelToken,
          );
        }

        if (model is! PromptChatStreamPartsCallOptionsCapability) {
          throw const InvalidRequestError(
            'This model does not support call-level overrides (headers/body) for Prompt IR streaming. '
            'Implement `PromptChatStreamPartsCallOptionsCapability` (or use a provider that does).',
          );
        }

        return (model as PromptChatStreamPartsCallOptionsCapability)
            .chatPromptStreamPartsWithCallOptions(
          prompt,
          tools: tools,
          providerTools: providerTools,
          callOptions: callOptions,
          cancelToken: cancelToken,
        );
      }

      requirePromptCapabilityForFileReferenceParts(
        prompt: prompt,
        requiredCapabilityName: '`PromptChatStreamPartsCapability`',
      );

      return chatStreamPartsBestEffort(
        model: model,
        input: StandardizedChatMessages(prompt.toChatMessages()),
        tools: tools,
        providerTools: providerTools,
        callOptions: callOptions,
        cancelToken: cancelToken,
      );
  }
}
