import 'dart:async';

import '../common/call_options.dart';
import '../common/provider_metadata.dart';
import '../content/content_part.dart';
import '../prompt/prompt_message.dart';
import '../tool/tool_definition.dart';
import 'generate_text_run_result.dart';
import 'generate_text_step_result.dart';
import 'generate_text_step_start_event.dart';
import 'language_model.dart';

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

final class GenerateTextRunner {
  final LanguageModel model;
  final List<PromptMessage> prompt;
  final List<FunctionToolDefinition> tools;
  final ToolChoice? toolChoice;
  final GenerateTextOptions options;
  final CallOptions callOptions;
  final GenerateTextFunctionToolExecutor? functionToolExecutor;
  final int maxSteps;
  final GenerateTextOnStepStart? onStepStart;
  final GenerateTextOnStepFinish? onStepFinish;
  final GenerateTextOnFinish? onFinish;

  GenerateTextRunner({
    required this.model,
    required List<PromptMessage> prompt,
    List<FunctionToolDefinition> tools = const [],
    this.toolChoice,
    this.options = const GenerateTextOptions(),
    this.callOptions = const CallOptions(),
    this.functionToolExecutor,
    this.maxSteps = 8,
    this.onStepStart,
    this.onStepFinish,
    this.onFinish,
  })  : prompt = List.unmodifiable(prompt),
        tools = List.unmodifiable(tools) {
    if (maxSteps < 1) {
      throw ArgumentError.value(
        maxSteps,
        'maxSteps',
        'GenerateTextRunner.maxSteps must be at least 1.',
      );
    }
  }

  Future<GenerateTextRunResult> run() async {
    final previousSteps = <GenerateTextStepResult>[];
    var promptHistory = List<PromptMessage>.from(prompt);
    final declaredToolNames = {
      for (final tool in tools) tool.name,
    };

    while (true) {
      final stepNumber = previousSteps.length;
      if (stepNumber >= maxSteps) {
        throw StateError(
          'GenerateTextRunner exceeded maxSteps ($maxSteps).',
        );
      }

      final request = GenerateTextRequest(
        prompt: promptHistory,
        tools: tools,
        toolChoice: toolChoice,
        options: options,
        callOptions: callOptions,
      );

      final stepStartEvent = GenerateTextStepStartEvent(
        stepNumber: stepNumber,
        providerId: model.providerId,
        modelId: model.modelId,
        request: request,
        previousSteps: previousSteps,
      );
      await onStepStart?.call(stepStartEvent);

      final result = await model.generate(request);
      final step = GenerateTextStepResult(
        stepNumber: stepNumber,
        providerId: model.providerId,
        modelId: model.modelId,
        request: request,
        result: result,
      );
      await onStepFinish?.call(step);
      previousSteps.add(step);

      if (step.finishReason != FinishReason.toolCalls) {
        break;
      }

      final toolContinuation = await _buildFunctionToolContinuation(
        step,
        declaredToolNames: declaredToolNames,
      );
      if (toolContinuation == null) {
        break;
      }

      promptHistory = [
        ...promptHistory,
        ..._stepToPromptMessages(step),
        ...toolContinuation,
      ];
    }

    final runResult = GenerateTextRunResult(
      steps: previousSteps,
    );
    await onFinish?.call(runResult);

    return runResult;
  }

  Future<List<PromptMessage>?> _buildFunctionToolContinuation(
    GenerateTextStepResult step, {
    required Set<String> declaredToolNames,
  }) async {
    final executor = functionToolExecutor;
    if (executor == null) {
      return null;
    }

    if (step.toolApprovalRequests.isNotEmpty) {
      throw UnsupportedError(
        'GenerateTextRunner does not support tool approval continuation yet.',
      );
    }

    if (step.toolCalls.isEmpty) {
      throw StateError(
        'GenerateTextRunner received finishReason.toolCalls without tool calls.',
      );
    }

    final toolMessages = <PromptMessage>[];

    for (final toolCall in step.toolCalls) {
      if (toolCall.providerExecuted) {
        throw UnsupportedError(
          'GenerateTextRunner only supports client-executed common function tools.',
        );
      }

      if (toolCall.isDynamic) {
        throw UnsupportedError(
          'GenerateTextRunner does not support dynamic tool calls yet.',
        );
      }

      if (!declaredToolNames.contains(toolCall.toolName)) {
        throw StateError(
          'Tool "${toolCall.toolName}" was not declared in GenerateTextRunner.tools.',
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
              providerMetadata: _toolCallProviderMetadata(
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

  ProviderMetadata? _toolCallProviderMetadata(
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
}

Future<GenerateTextRunResult> runTextGeneration({
  required LanguageModel model,
  required List<PromptMessage> prompt,
  List<FunctionToolDefinition> tools = const [],
  ToolChoice? toolChoice,
  GenerateTextOptions options = const GenerateTextOptions(),
  CallOptions callOptions = const CallOptions(),
  GenerateTextFunctionToolExecutor? functionToolExecutor,
  int maxSteps = 8,
  GenerateTextOnStepStart? onStepStart,
  GenerateTextOnStepFinish? onStepFinish,
  GenerateTextOnFinish? onFinish,
}) {
  return GenerateTextRunner(
    model: model,
    prompt: prompt,
    tools: tools,
    toolChoice: toolChoice,
    options: options,
    callOptions: callOptions,
    functionToolExecutor: functionToolExecutor,
    maxSteps: maxSteps,
    onStepStart: onStepStart,
    onStepFinish: onStepFinish,
    onFinish: onFinish,
  ).run();
}

List<PromptMessage> _stepToPromptMessages(GenerateTextStepResult step) {
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
          'GenerateTextRunner prompt replay does not support '
          '${part.runtimeType} parts.',
        );
    }
  }

  flushAssistantParts();
  return prompt;
}
