import 'dart:async';

import 'package:llm_dart_provider/llm_dart_provider.dart' hide ToolResultEvent;

import '../stream/text_stream_event.dart';
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

typedef GenerateTextOnToolStart = FutureOr<void> Function(
  GenerateTextToolExecutionStartEvent event,
);

typedef GenerateTextOnToolFinish = FutureOr<void> Function(
  GenerateTextToolExecutionFinishEvent event,
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

final class GenerateTextToolExecutionStartEvent {
  final int stepNumber;
  final GenerateTextStepResult step;
  final ToolCallContent toolCall;

  const GenerateTextToolExecutionStartEvent({
    required this.stepNumber,
    required this.step,
    required this.toolCall,
  });
}

final class GenerateTextToolExecutionFinishEvent {
  final int stepNumber;
  final GenerateTextStepResult step;
  final ToolCallContent toolCall;
  final GenerateTextToolExecutionResult result;

  const GenerateTextToolExecutionFinishEvent({
    required this.stepNumber,
    required this.step,
    required this.toolCall,
    required this.result,
  });
}

final class GenerateTextToolExecution {
  final ToolCallContent toolCall;
  final GenerateTextToolExecutionResult result;
  final ProviderMetadata? providerMetadata;

  const GenerateTextToolExecution({
    required this.toolCall,
    required this.result,
    this.providerMetadata,
  });

  ToolPromptMessage toPromptMessage() {
    return ToolPromptMessage(
      toolName: toolCall.toolName,
      parts: [
        ToolResultPromptPart(
          toolCallId: toolCall.toolCallId,
          toolName: toolCall.toolName,
          toolOutput: result.toolOutput,
          providerOptions: GenerateTextRunnerSupport.replayProviderOptions(
            providerMetadata,
          ),
        ),
      ],
    );
  }

  ToolResultEvent toTextStreamEvent() {
    return ToolResultEvent(
      toolResult: ToolResultContent(
        toolCallId: toolCall.toolCallId,
        toolName: toolCall.toolName,
        toolOutput: result.toolOutput,
        isDynamic: toolCall.isDynamic,
      ),
      providerMetadata: providerMetadata,
    );
  }
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
  static Future<List<GenerateTextToolExecution>?> executeFunctionTools(
    GenerateTextStepResult step, {
    required Set<String> declaredToolNames,
    required GenerateTextFunctionToolExecutor? functionToolExecutor,
    GenerateTextOnToolStart? onToolStart,
    GenerateTextOnToolFinish? onToolFinish,
    required String runnerName,
  }) async {
    final executor = functionToolExecutor;
    if (executor == null) {
      return null;
    }

    final resolvedToolCallIds = {
      for (final toolResult in step.toolResults) toolResult.toolCallId,
    };
    final clientToolCalls = step.toolCalls
        .where(
          (toolCall) =>
              !toolCall.providerExecuted &&
              !resolvedToolCallIds.contains(toolCall.toolCallId),
        )
        .toList(growable: false);

    if (step.toolCalls.isEmpty && step.toolApprovalRequests.isEmpty) {
      throw StateError(
        '$runnerName received finishReason.toolCalls without tool calls.',
      );
    }

    if (step.toolApprovalRequests.isNotEmpty) {
      return null;
    }

    if (clientToolCalls.isEmpty) {
      return step.toolResults.isEmpty
          ? null
          : const <GenerateTextToolExecution>[];
    }

    final executions = <GenerateTextToolExecution>[];

    for (final toolCall in clientToolCalls) {
      if (!declaredToolNames.contains(toolCall.toolName)) {
        throw StateError(
          'Tool "${toolCall.toolName}" was not declared in $runnerName.tools.',
        );
      }

      final startEvent = GenerateTextToolExecutionStartEvent(
        stepNumber: step.stepNumber,
        step: step,
        toolCall: toolCall,
      );
      await onToolStart?.call(startEvent);

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
      await onToolFinish?.call(
        GenerateTextToolExecutionFinishEvent(
          stepNumber: step.stepNumber,
          step: step,
          toolCall: toolCall,
          result: executionResult,
        ),
      );

      executions.add(
        GenerateTextToolExecution(
          toolCall: toolCall,
          result: executionResult,
          providerMetadata: toolCallProviderMetadata(
            step,
            toolCall.toolCallId,
          ),
        ),
      );
    }

    return executions;
  }

  static Future<List<PromptMessage>?> buildFunctionToolContinuation(
    GenerateTextStepResult step, {
    required Set<String> declaredToolNames,
    required GenerateTextFunctionToolExecutor? functionToolExecutor,
    GenerateTextOnToolStart? onToolStart,
    GenerateTextOnToolFinish? onToolFinish,
    required String runnerName,
  }) async {
    final executions = await executeFunctionTools(
      step,
      declaredToolNames: declaredToolNames,
      functionToolExecutor: functionToolExecutor,
      onToolStart: onToolStart,
      onToolFinish: onToolFinish,
      runnerName: runnerName,
    );
    return executions
        ?.map((execution) => execution.toPromptMessage())
        .toList(growable: false);
  }

  static GenerateTextStepResult addToolExecutionsToStep(
    GenerateTextStepResult step,
    List<GenerateTextToolExecution> executions,
  ) {
    if (executions.isEmpty) {
      return step;
    }

    return GenerateTextStepResult(
      stepNumber: step.stepNumber,
      providerId: step.providerId,
      modelId: step.modelId,
      request: step.request,
      result: GenerateTextResult(
        content: [
          ...step.content,
          for (final execution in executions)
            ToolResultContentPart(
              ToolResultContent(
                toolCallId: execution.toolCall.toolCallId,
                toolName: execution.toolCall.toolName,
                toolOutput: execution.result.toolOutput,
                isDynamic: execution.toolCall.isDynamic,
              ),
              providerMetadata: execution.providerMetadata,
            ),
        ],
        finishReason: step.finishReason,
        rawFinishReason: step.rawFinishReason,
        responseId: step.responseId,
        responseTimestamp: step.responseTimestamp,
        responseModelId: step.responseModelId,
        usage: step.usage,
        providerMetadata: step.providerMetadata,
        warnings: step.warnings,
      ),
    );
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
