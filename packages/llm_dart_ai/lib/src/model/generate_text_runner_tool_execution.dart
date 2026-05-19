import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'generate_text_runner_prompt_replay.dart';
import 'generate_text_step_result.dart';
import 'generate_text_tool_continuation_support.dart';
import 'generate_text_tool_execution_contract.dart';
import 'generate_text_tool_execution_projection.dart';

export 'generate_text_tool_execution_contract.dart'
    show
        GenerateTextFunctionToolExecutionRequest,
        GenerateTextFunctionToolExecutor,
        GenerateTextOnToolFinish,
        GenerateTextOnToolStart,
        GenerateTextToolExecutionFinishEvent,
        GenerateTextToolExecutionResult,
        GenerateTextToolExecutionStartEvent;
export 'generate_text_tool_execution_projection.dart'
    show GenerateTextToolExecution, addToolExecutionsToStep;

enum GenerateTextToolContinuationKind {
  stop,
  continueWithExecutions,
}

final class GenerateTextToolContinuation {
  final GenerateTextToolContinuationKind kind;
  final List<GenerateTextToolExecution> executions;

  const GenerateTextToolContinuation.stop()
      : kind = GenerateTextToolContinuationKind.stop,
        executions = const [];

  GenerateTextToolContinuation.continueWithExecutions(
    List<GenerateTextToolExecution> executions,
  )   : kind = GenerateTextToolContinuationKind.continueWithExecutions,
        executions = List.unmodifiable(executions);

  bool get shouldContinue =>
      kind == GenerateTextToolContinuationKind.continueWithExecutions;
}

Future<GenerateTextToolContinuation> resolveFunctionToolContinuation(
  GenerateTextStepResult step, {
  required Set<String> declaredToolNames,
  required GenerateTextFunctionToolExecutor? functionToolExecutor,
  GenerateTextOnToolStart? onToolStart,
  GenerateTextOnToolFinish? onToolFinish,
  required String runnerName,
}) async {
  final executor = functionToolExecutor;
  if (executor == null) {
    return const GenerateTextToolContinuation.stop();
  }

  final clientToolCalls = unresolvedClientToolCallsForStep(step);
  validateToolCallContinuationStep(step, runnerName: runnerName);

  if (step.toolApprovalRequests.isNotEmpty) {
    return const GenerateTextToolContinuation.stop();
  }

  if (clientToolCalls.isEmpty) {
    return step.toolResults.isEmpty
        ? const GenerateTextToolContinuation.stop()
        : GenerateTextToolContinuation.continueWithExecutions(
            const <GenerateTextToolExecution>[],
          );
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

  return GenerateTextToolContinuation.continueWithExecutions(executions);
}

Future<List<GenerateTextToolExecution>?> executeFunctionTools(
  GenerateTextStepResult step, {
  required Set<String> declaredToolNames,
  required GenerateTextFunctionToolExecutor? functionToolExecutor,
  GenerateTextOnToolStart? onToolStart,
  GenerateTextOnToolFinish? onToolFinish,
  required String runnerName,
}) async {
  final continuation = await resolveFunctionToolContinuation(
    step,
    declaredToolNames: declaredToolNames,
    functionToolExecutor: functionToolExecutor,
    onToolStart: onToolStart,
    onToolFinish: onToolFinish,
    runnerName: runnerName,
  );
  return continuation.shouldContinue ? continuation.executions : null;
}

Future<List<PromptMessage>?> buildFunctionToolContinuation(
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
