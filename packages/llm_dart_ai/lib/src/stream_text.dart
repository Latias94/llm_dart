import 'package:llm_dart_core/llm_dart_core.dart';

import 'prompt_input.dart';
import 'stream_parts.dart';
import 'types.dart';

/// Stream text generation as provider-agnostic stream parts.
Stream<TextStreamPart> streamText({
  required ChatCapability model,
  String? system,
  String? prompt,
  List<ChatMessage>? messages,
  Prompt? promptIr,
  List<Tool>? tools,
  CancelToken? cancelToken,
}) async* {
  final input = standardizePromptInput(
    system: system,
    prompt: prompt,
    messages: messages,
    promptIr: promptIr,
  );

  final Stream<LLMStreamPart> parts;
  switch (input) {
    case StandardizedChatMessages(:final messages):
      parts = streamChatParts(
        model: model,
        messages: messages,
        tools: tools,
        cancelToken: cancelToken,
      );
    case StandardizedPromptIr(:final prompt):
      parts = streamChatParts(
        model: model,
        promptIr: prompt,
        tools: tools,
        cancelToken: cancelToken,
      );
  }

  await for (final part in parts) {
    switch (part) {
      case LLMTextDeltaPart(:final delta):
        yield TextDeltaPart(delta);

      case LLMReasoningDeltaPart(:final delta):
        yield ThinkingDeltaPart(delta);

      case LLMToolCallStartPart(:final toolCall):
        yield ToolCallDeltaPart(toolCall);

      case LLMToolCallDeltaPart(:final toolCall):
        yield ToolCallDeltaPart(toolCall);

      case LLMProviderToolCallPart(
          toolCallId: final toolCallId,
          toolName: final toolName,
          input: final input,
          isDynamic: final isDynamic,
          providerMetadata: final providerMetadata,
        ):
        yield ProviderToolCallPart(
          toolCallId: toolCallId,
          toolName: toolName,
          input: input,
          isDynamic: isDynamic,
          providerMetadata: providerMetadata,
        );

      case LLMProviderToolDeltaPart(
          toolCallId: final toolCallId,
          toolName: final toolName,
          status: final status,
          data: final data,
          providerMetadata: final providerMetadata,
        ):
        yield ProviderToolDeltaPart(
          toolCallId: toolCallId,
          toolName: toolName,
          status: status,
          data: data,
          providerMetadata: providerMetadata,
        );

      case LLMProviderToolApprovalRequestPart(
          approvalId: final approvalId,
          toolCallId: final toolCallId,
          toolName: final toolName,
          input: final input,
          providerMetadata: final providerMetadata,
        ):
        yield ProviderToolApprovalRequestPart(
          approvalId: approvalId,
          toolCallId: toolCallId,
          toolName: toolName,
          input: input,
          providerMetadata: providerMetadata,
        );

      case LLMProviderToolResultPart(
          toolCallId: final toolCallId,
          toolName: final toolName,
          result: final result,
          isError: final isError,
          preliminary: final preliminary,
          isDynamic: final isDynamic,
          providerMetadata: final providerMetadata,
        ):
        yield ProviderToolResultPart(
          toolCallId: toolCallId,
          toolName: toolName,
          result: result,
          isError: isError,
          preliminary: preliminary,
          isDynamic: isDynamic,
          providerMetadata: providerMetadata,
        );

      case LLMSourceUrlPart(
          sourceId: final sourceId,
          url: final url,
          title: final title,
          providerMetadata: final providerMetadata,
        ):
        yield SourceUrlPart(
          sourceId: sourceId,
          url: url,
          title: title,
          providerMetadata: providerMetadata,
        );

      case LLMSourceDocumentPart(
          sourceId: final sourceId,
          mediaType: final mediaType,
          title: final title,
          filename: final filename,
          providerMetadata: final providerMetadata,
        ):
        yield SourceDocumentPart(
          sourceId: sourceId,
          mediaType: mediaType,
          title: title,
          filename: filename,
          providerMetadata: providerMetadata,
        );

      case LLMFinishPart(:final response):
        yield FinishPart(
          GenerateTextResult(
            rawResponse: response,
            text: response.text,
            thinking: response.thinking,
            toolCalls: response.toolCalls,
            usage: response.usage,
            finishReason: response is ChatResponseWithFinishReason
                ? response.finishReason
                : null,
          ),
        );

      case LLMErrorPart(:final error):
        yield ErrorPart(error);

      case LLMStreamStartPart():
      case LLMTextStartPart():
      case LLMTextEndPart():
      case LLMReasoningStartPart():
      case LLMReasoningEndPart():
      case LLMToolCallEndPart():
      case LLMProviderMetadataPart():
      case LLMResponseMetadataPart():
      case LLMToolResultPart():
        // Not represented in legacy TextStreamPart.
        break;
    }
  }
}

/// Stream text generation from a `Prompt` IR (legacy helper).
@Deprecated('Use streamText(model: ..., promptIr: ...) instead.')
Stream<TextStreamPart> streamTextFromPromptIr({
  required ChatCapability model,
  required Prompt prompt,
  List<Tool>? tools,
  CancelToken? cancelToken,
}) =>
    streamText(
      model: model,
      promptIr: prompt,
      tools: tools,
      cancelToken: cancelToken,
    );

/// Stream text generation from a plain prompt (legacy helper).
@Deprecated('Use streamText(model: ..., system: ..., prompt: ...) instead.')
Stream<TextStreamPart> streamTextFromPrompt({
  required ChatCapability model,
  required String prompt,
  String? systemPrompt,
  List<Tool>? tools,
  CancelToken? cancelToken,
}) {
  return streamText(
    model: model,
    system: systemPrompt,
    prompt: prompt,
    tools: tools,
    cancelToken: cancelToken,
  );
}
