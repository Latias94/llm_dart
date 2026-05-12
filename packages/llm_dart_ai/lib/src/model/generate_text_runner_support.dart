import 'dart:async';

import 'package:llm_dart_provider/llm_dart_provider.dart';

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

typedef GenerateTextOnError = FutureOr<void> Function(
  Object error,
  StackTrace stackTrace,
);

typedef StreamTextOnChunk = FutureOr<void> Function(
  TextStreamEvent event,
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
  final Object? _output;
  final bool _isError;
  final ToolOutput? _toolOutput;

  const GenerateTextToolExecutionResult.output(Object? output)
      : _output = output,
        _isError = false,
        _toolOutput = null;

  const GenerateTextToolExecutionResult.error(Object? output)
      : _output = output,
        _isError = true,
        _toolOutput = null;

  const GenerateTextToolExecutionResult.toolOutput(ToolOutput toolOutput)
      : _output = null,
        _isError = false,
        _toolOutput = toolOutput;

  ToolOutput get toolOutput =>
      _toolOutput ?? ToolOutput.fromValue(_output, isError: _isError);

  Object? get output => toolOutput.value;

  bool get isError => toolOutput.isError;
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

    final clientToolCalls = step.toolCalls
        .where((toolCall) => !toolCall.providerExecuted)
        .toList(growable: false);

    if (step.toolCalls.isEmpty && step.toolApprovalRequests.isEmpty) {
      throw StateError(
        '$runnerName received finishReason.toolCalls without tool calls.',
      );
    }

    if (clientToolCalls.isEmpty) {
      return null;
    }

    if (step.toolApprovalRequests.isNotEmpty) {
      throw UnsupportedError(
        '$runnerName cannot continue while provider tool approval requests '
        'are waiting for approval responses.',
      );
    }

    final toolMessages = <PromptMessage>[];

    for (final toolCall in clientToolCalls) {
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
              toolOutput: executionResult.toolOutput,
              providerOptions: replayProviderOptions(
                toolCallProviderMetadata(
                  step,
                  toolCall.toolCallId,
                ),
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

  static ProviderReplayPromptPartOptions? replayProviderOptions(
    ProviderMetadata? metadata,
  ) {
    return ProviderReplayPromptPartOptions.fromMetadata(metadata);
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
              providerOptions: replayProviderOptions(providerMetadata),
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
              providerOptions: replayProviderOptions(providerMetadata),
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
              data: file.data,
              providerOptions: replayProviderOptions(providerMetadata),
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
              data: file.data,
              providerOptions: replayProviderOptions(providerMetadata),
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
              providerOptions: replayProviderOptions(providerMetadata),
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
              providerOptions: replayProviderOptions(providerMetadata),
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
              providerOptions: replayProviderOptions(providerMetadata),
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
                  toolOutput: toolResult.toolOutput,
                  providerOptions: replayProviderOptions(providerMetadata),
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
