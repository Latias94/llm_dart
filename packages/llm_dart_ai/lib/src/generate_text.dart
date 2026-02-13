import 'package:llm_dart_core/llm_dart_core.dart';

import 'prompt_input.dart';
import 'metadata_fallbacks.dart';
import 'response_messages.dart';
import 'types.dart';

/// Generate text (Vercel-style prompt input).
///
/// Provide exactly one of:
/// - [prompt] (plain text prompt)
/// - [messages] (legacy chat message model)
/// - [promptIr] (Prompt IR)
///
/// You can also pass [system] alongside any of them.
Future<GenerateTextResult> generateText({
  required ChatCapability model,
  String? system,
  String? prompt,
  List<ChatMessage>? messages,
  Prompt? promptIr,
  List<Tool>? tools,
  IncludeOptions include = const IncludeOptions(),
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) async {
  final startedAt = DateTime.now().toUtc();
  final defaultModelId = model is ModelIdentityCapability
      ? (model as ModelIdentityCapability).modelId
      : null;
  final input = standardizePromptInput(
    system: system,
    prompt: prompt,
    messages: messages,
    promptIr: promptIr,
  );

  final ChatResponse response;
  switch (input) {
    case StandardizedChatMessages(:final messages):
      if (callOptions.isEmpty) {
        response = await model.chatWithTools(
          messages,
          tools,
          cancelToken: cancelToken,
        );
      } else {
        if (model is! ChatCallOptionsCapability) {
          throw const InvalidRequestError(
            'This model does not support call-level overrides (headers/body). '
            'Implement `ChatCallOptionsCapability` (or use a provider that does).',
          );
        }
        response = await (model as ChatCallOptionsCapability)
            .chatWithToolsWithCallOptions(
          messages,
          tools,
          callOptions: callOptions,
          cancelToken: cancelToken,
        );
      }

    case StandardizedPromptIr(:final prompt):
      if (model is PromptChatCapability) {
        if (callOptions.isEmpty) {
          response = await (model as PromptChatCapability).chatPrompt(
            prompt,
            tools: tools,
            cancelToken: cancelToken,
          );
        } else {
          if (model is! PromptChatCallOptionsCapability) {
            throw const InvalidRequestError(
              'This model does not support call-level overrides for Prompt IR. '
              'Implement `PromptChatCallOptionsCapability` (or use a provider that does).',
            );
          }
          response = await (model as PromptChatCallOptionsCapability)
              .chatPromptWithCallOptions(
            prompt,
            tools: tools,
            callOptions: callOptions,
            cancelToken: cancelToken,
          );
        }
      } else {
        requirePromptCapabilityForFileReferenceParts(
          prompt: prompt,
          requiredCapabilityName: '`PromptChatCapability`',
        );
        if (callOptions.isEmpty) {
          response = await model.chatWithTools(
            prompt.toChatMessages(),
            tools,
            cancelToken: cancelToken,
          );
        } else {
          if (model is! ChatCallOptionsCapability) {
            throw const InvalidRequestError(
              'This model does not support call-level overrides (headers/body). '
              'Implement `ChatCallOptionsCapability` (or use a provider that does).',
            );
          }
          response = await (model as ChatCallOptionsCapability)
              .chatWithToolsWithCallOptions(
            prompt.toChatMessages(),
            tools,
            callOptions: callOptions,
            cancelToken: cancelToken,
          );
        }
      }
  }

  return GenerateTextResult(
    rawResponse: response,
    text: response.text,
    thinking: response.thinking,
    toolCalls: response.toolCalls,
    usage: response.usage,
    finishReason:
        response is ChatResponseWithFinishReason ? response.finishReason : null,
    requestMetadata: requestMetadataWithInclude(
      response is ChatResponseWithRequestMetadata
          ? response.requestMetadata
          : null,
      include,
    ),
    responseMetadata: responseMetadataWithInclude(
      responseMetadataWithDefaults(
        response is ChatResponseWithResponseMetadata
            ? response.responseMetadata
            : null,
        startedAt,
        defaultModelId: defaultModelId,
      ),
      include,
    ),
    responseMessages: buildResponseMessagesBestEffort(response),
    responsePromptMessages: buildResponsePromptMessagesBestEffort(response),
  );
}
