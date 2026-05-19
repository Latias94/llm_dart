import 'dart:async';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'generate_text_loop_continuation.dart';
import 'generate_text_runner_support.dart';
import 'generate_text_stop_condition.dart';
import 'generate_text_step_result.dart';

typedef GenerateTextStepFinisher = FutureOr<List<GenerateTextStepResult>>
    Function(GenerateTextStepResult step);

typedef GenerateTextToolExecutionApplier = FutureOr<GenerateTextStepResult>
    Function(
  GenerateTextStepResult step,
  List<GenerateTextToolExecution> executions,
);

final class GenerateTextStepContinuationDecision {
  final bool shouldContinue;
  final List<PromptMessage> promptHistory;

  GenerateTextStepContinuationDecision.stop({
    required List<PromptMessage> promptHistory,
  })  : shouldContinue = false,
        promptHistory = List.unmodifiable(promptHistory);

  GenerateTextStepContinuationDecision.continueWithPrompt({
    required List<PromptMessage> promptHistory,
  })  : shouldContinue = true,
        promptHistory = List.unmodifiable(promptHistory);
}

final class GenerateTextStepContinuationResolver {
  final Set<String> declaredToolNames;
  final GenerateTextFunctionToolExecutor? functionToolExecutor;
  final GenerateTextOnToolStart? onToolStart;
  final GenerateTextOnToolFinish? onToolFinish;
  final List<GenerateTextStopCondition> stopConditions;
  final String runnerName;

  GenerateTextStepContinuationResolver({
    required Set<String> declaredToolNames,
    required this.functionToolExecutor,
    required this.stopConditions,
    required this.runnerName,
    this.onToolStart,
    this.onToolFinish,
  }) : declaredToolNames = Set.unmodifiable(declaredToolNames);

  Future<GenerateTextStepContinuationDecision> resolve({
    required GenerateTextStepResult step,
    required List<PromptMessage> promptHistory,
    required GenerateTextStepFinisher finishStep,
    GenerateTextToolExecutionApplier? applyToolExecutions,
    void Function()? throwIfCancelled,
  }) async {
    if (step.finishReason != FinishReason.toolCalls) {
      await finishStep(step);
      return GenerateTextStepContinuationDecision.stop(
        promptHistory: promptHistory,
      );
    }

    throwIfCancelled?.call();
    final toolContinuation =
        await GenerateTextRunnerSupport.resolveFunctionToolContinuation(
      step,
      declaredToolNames: declaredToolNames,
      functionToolExecutor: functionToolExecutor,
      onToolStart: onToolStart,
      onToolFinish: onToolFinish,
      runnerName: runnerName,
    );
    throwIfCancelled?.call();

    if (!toolContinuation.shouldContinue) {
      await finishStep(step);
      return GenerateTextStepContinuationDecision.stop(
        promptHistory: promptHistory,
      );
    }

    final finalizedStep = await (applyToolExecutions ??
            GenerateTextRunnerSupport.addToolExecutionsToStep)
        .call(step, toolContinuation.executions);
    final completedSteps = await finishStep(finalizedStep);
    final loopContinuation = await resolveGenerateTextLoopContinuation(
      promptHistory: promptHistory,
      step: finalizedStep,
      completedSteps: completedSteps,
      stopConditions: stopConditions,
      runnerName: runnerName,
    );

    if (!loopContinuation.shouldContinue) {
      return GenerateTextStepContinuationDecision.stop(
        promptHistory: loopContinuation.promptHistory,
      );
    }

    return GenerateTextStepContinuationDecision.continueWithPrompt(
      promptHistory: loopContinuation.promptHistory,
    );
  }
}
