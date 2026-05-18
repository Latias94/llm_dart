import 'dart:async';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../stream/text_stream_event.dart';
import 'generate_text_run_result.dart';
import 'generate_text_runner_prompt_replay.dart' as prompt_replay;
import 'generate_text_runner_tool_execution.dart' as tool_execution;
import 'generate_text_step_result.dart';
import 'generate_text_step_start_event.dart';

export 'generate_text_runner_tool_execution.dart'
    show
        GenerateTextFunctionToolExecutionRequest,
        GenerateTextFunctionToolExecutor,
        GenerateTextOnToolFinish,
        GenerateTextOnToolStart,
        GenerateTextToolContinuation,
        GenerateTextToolContinuationKind,
        GenerateTextToolExecution,
        GenerateTextToolExecutionFinishEvent,
        GenerateTextToolExecutionResult,
        GenerateTextToolExecutionStartEvent;

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

final class GenerateTextRunnerSupport {
  static Future<List<tool_execution.GenerateTextToolExecution>?>
      executeFunctionTools(
    GenerateTextStepResult step, {
    required Set<String> declaredToolNames,
    required tool_execution.GenerateTextFunctionToolExecutor?
        functionToolExecutor,
    tool_execution.GenerateTextOnToolStart? onToolStart,
    tool_execution.GenerateTextOnToolFinish? onToolFinish,
    required String runnerName,
  }) {
    return tool_execution.executeFunctionTools(
      step,
      declaredToolNames: declaredToolNames,
      functionToolExecutor: functionToolExecutor,
      onToolStart: onToolStart,
      onToolFinish: onToolFinish,
      runnerName: runnerName,
    );
  }

  static Future<tool_execution.GenerateTextToolContinuation>
      resolveFunctionToolContinuation(
    GenerateTextStepResult step, {
    required Set<String> declaredToolNames,
    required tool_execution.GenerateTextFunctionToolExecutor?
        functionToolExecutor,
    tool_execution.GenerateTextOnToolStart? onToolStart,
    tool_execution.GenerateTextOnToolFinish? onToolFinish,
    required String runnerName,
  }) {
    return tool_execution.resolveFunctionToolContinuation(
      step,
      declaredToolNames: declaredToolNames,
      functionToolExecutor: functionToolExecutor,
      onToolStart: onToolStart,
      onToolFinish: onToolFinish,
      runnerName: runnerName,
    );
  }

  static Future<List<PromptMessage>?> buildFunctionToolContinuation(
    GenerateTextStepResult step, {
    required Set<String> declaredToolNames,
    required tool_execution.GenerateTextFunctionToolExecutor?
        functionToolExecutor,
    tool_execution.GenerateTextOnToolStart? onToolStart,
    tool_execution.GenerateTextOnToolFinish? onToolFinish,
    required String runnerName,
  }) {
    return tool_execution.buildFunctionToolContinuation(
      step,
      declaredToolNames: declaredToolNames,
      functionToolExecutor: functionToolExecutor,
      onToolStart: onToolStart,
      onToolFinish: onToolFinish,
      runnerName: runnerName,
    );
  }

  static GenerateTextStepResult addToolExecutionsToStep(
    GenerateTextStepResult step,
    List<tool_execution.GenerateTextToolExecution> executions,
  ) {
    return tool_execution.addToolExecutionsToStep(step, executions);
  }

  static ProviderMetadata? toolCallProviderMetadata(
    GenerateTextStepResult step,
    String toolCallId,
  ) {
    return prompt_replay.toolCallProviderMetadata(step, toolCallId);
  }

  static ProviderReplayPromptPartOptions? replayProviderOptions(
    ProviderMetadata? metadata,
  ) {
    return prompt_replay.replayProviderOptions(metadata);
  }

  static List<PromptMessage> stepToPromptMessages(
    GenerateTextStepResult step, {
    required String runnerName,
  }) {
    return prompt_replay.stepToPromptMessages(
      step,
      runnerName: runnerName,
    );
  }
}
