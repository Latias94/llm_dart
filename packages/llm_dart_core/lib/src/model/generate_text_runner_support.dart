import 'dart:async';

import '../common/provider_metadata.dart';
import '../content/content_part.dart';
import '../prompt/prompt_message.dart';
import 'generate_text_run_result.dart';
import 'generate_text_step_result.dart';
import 'generate_text_step_start_event.dart';

typedef GenerateTextOnStepStart = FutureOr<void> Function(
  GenerateTextStepStartEvent event,
);

typedef GenerateTextOnStepFinish = FutureOr<void> Function(
  GenerateTextStepResult step,
);

typedef GenerateTextOnFinish = FutureOr<void> Function(
  GenerateTextRunResult result,
);

typedef GenerateTextFunctionToolExecutor
    = FutureOr<GenerateTextToolExecutionResult> Function(
  GenerateTextFunctionToolExecutionRequest request,
);

final class GenerateTextFunctionToolExecutionRequest {
  final int stepNumber;
  final GenerateTextStepResult step;
  final ToolCallContent toolCall;

  const GenerateTextFunctionToolExecutionRequest({
    required this.stepNumber,
    required this.step,
    required this.toolCall,
  });
}

final class GenerateTextToolExecutionResult {
  final Object? output;
  final bool isError;

  const GenerateTextToolExecutionResult.output(this.output) : isError = false;

  const GenerateTextToolExecutionResult.error(this.output) : isError = true;
}

final class GenerateTextRunnerSupport {
  static Future<List<PromptMessage>?> buildFunctionToolContinuation(
    GenerateTextStepResult step, {
    required Set<String> declaredToolNames,
    required GenerateTextFunctionToolExecutor? functionToolExecutor,
    required String runnerName,
  }) async {
    final executor = functionToolExecutor;
    if (executor == null) {
      return null;
    }

    if (step.toolApprovalRequests.isNotEmpty) {
      throw UnsupportedError(
        '$runnerName does not support tool approval continuation yet.',
      );
    }

    if (step.toolCalls.isEmpty) {
      throw StateError(
        '$runnerName received finishReason.toolCalls without tool calls.',
      );
    }

    final toolMessages = <PromptMessage>[];

    for (final toolCall in step.toolCalls) {
      if (toolCall.providerExecuted) {
        throw UnsupportedError(
          '$runnerName only supports client-executed common function tools.',
        );
      }

      if (toolCall.isDynamic) {
        throw UnsupportedError(
          '$runnerName does not support dynamic tool calls yet.',
        );
      }

      if (!declaredToolNames.contains(toolCall.toolName)) {
        throw StateError(
          'Tool "${toolCall.toolName}" was not declared in $runnerName.tools.',
        );
      }

      GenerateTextToolExecutionResult executionResult;
      try {
        executionResult = await executor(
          GenerateTextFunctionToolExecutionRequest(
            stepNumber: step.stepNumber,
            step: step,
            toolCall: toolCall,
          ),
        );
      } catch (error) {
        executionResult = GenerateTextToolExecutionResult.error(
          'Function tool "${toolCall.toolName}" execution failed: $error',
        );
      }

      toolMessages.add(
        ToolPromptMessage(
          toolName: toolCall.toolName,
          parts: [
            ToolResultPromptPart(
              toolCallId: toolCall.toolCallId,
              toolName: toolCall.toolName,
              output: executionResult.output,
              isError: executionResult.isError,
              providerMetadata: toolCallProviderMetadata(
                step,
                toolCall.toolCallId,
              ),
            ),
          ],
        ),
      );
    }

    return toolMessages;
  }

  static ProviderMetadata? toolCallProviderMetadata(
    GenerateTextStepResult step,
    String toolCallId,
  ) {
    for (final part in step.result.content.whereType<ToolCallContentPart>()) {
      if (part.toolCall.toolCallId == toolCallId) {
        return part.providerMetadata;
      }
    }

    return null;
  }

  static List<PromptMessage> stepToPromptMessages(
    GenerateTextStepResult step, {
    required String runnerName,
  }) {
    final prompt = <PromptMessage>[];
    final assistantParts = <PromptPart>[];

    void flushAssistantParts() {
      if (assistantParts.isEmpty) {
        return;
      }

      prompt.add(
        AssistantPromptMessage(
          parts: List<PromptPart>.from(assistantParts),
        ),
      );
      assistantParts.clear();
    }

    for (final part in step.content) {
      switch (part) {
        case TextContentPart(
              :final text,
              :final providerMetadata,
            )
            when text.isNotEmpty || providerMetadata != null:
          assistantParts.add(
            TextPromptPart(
              text,
              providerMetadata: providerMetadata,
            ),
          );
        case ReasoningContentPart(
              :final text,
              :final providerMetadata,
            )
            when text.isNotEmpty || providerMetadata != null:
          assistantParts.add(
            ReasoningPromptPart(
              text,
              providerMetadata: providerMetadata,
            ),
          );
        case FileContentPart(
            :final file,
            :final providerMetadata,
          ):
          assistantParts.add(
            FilePromptPart(
              mediaType: file.mediaType,
              filename: file.filename,
              uri: file.uri,
              bytes: file.bytes,
              providerMetadata: providerMetadata,
            ),
          );
        case ReasoningFileContentPart(
            :final file,
            :final providerMetadata,
          ):
          assistantParts.add(
            ReasoningFilePromptPart(
              mediaType: file.mediaType,
              filename: file.filename,
              uri: file.uri,
              bytes: file.bytes,
              providerMetadata: providerMetadata,
            ),
          );
        case CustomContentPart(
            :final kind,
            :final data,
            :final providerMetadata,
          ):
          assistantParts.add(
            CustomPromptPart(
              kind: kind,
              data: data,
              providerMetadata: providerMetadata,
            ),
          );
        case ToolCallContentPart(
            :final toolCall,
            :final providerMetadata,
          ):
          assistantParts.add(
            ToolCallPromptPart(
              toolCallId: toolCall.toolCallId,
              toolName: toolCall.toolName,
              input: toolCall.input,
              providerExecuted: toolCall.providerExecuted,
              isDynamic: toolCall.isDynamic,
              title: toolCall.title,
              providerMetadata: providerMetadata,
            ),
          );
        case ToolApprovalRequestContentPart(
            :final approvalRequest,
            :final providerMetadata,
          ):
          assistantParts.add(
            ToolApprovalRequestPromptPart(
              approvalId: approvalRequest.approvalId,
              toolCallId: approvalRequest.toolCallId,
              providerMetadata: providerMetadata,
            ),
          );
        case ToolResultContentPart(
            :final toolResult,
            :final providerMetadata,
          ):
          flushAssistantParts();
          prompt.add(
            ToolPromptMessage(
              toolName: toolResult.toolName,
              parts: [
                ToolResultPromptPart(
                  toolCallId: toolResult.toolCallId,
                  toolName: toolResult.toolName,
                  output: toolResult.output,
                  isError: toolResult.isError,
                  providerMetadata: providerMetadata,
                ),
              ],
            ),
          );
        case SourceContentPart():
          break;
        case _:
          throw UnsupportedError(
            '$runnerName prompt replay does not support '
            '${part.runtimeType} parts.',
          );
      }
    }

    flushAssistantParts();
    return prompt;
  }
}
