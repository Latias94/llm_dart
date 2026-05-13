import 'dart:async';

import 'generate_text_step_result.dart';

typedef GenerateTextStopCondition = FutureOr<bool> Function(
  GenerateTextStopConditionContext context,
);

final class GenerateTextStopConditionContext {
  final List<GenerateTextStepResult> steps;

  GenerateTextStopConditionContext({
    required List<GenerateTextStepResult> steps,
  }) : steps = List.unmodifiable(steps);
}

GenerateTextStopCondition isStepCount(int stepCount) {
  if (stepCount < 1) {
    throw ArgumentError.value(
      stepCount,
      'stepCount',
      'isStepCount requires a positive step count.',
    );
  }

  return (context) => context.steps.length == stepCount;
}

GenerateTextStopCondition isLoopFinished() {
  return (_) => false;
}

GenerateTextStopCondition hasToolCall(
  String toolName, [
  Iterable<String> additionalToolNames = const [],
]) {
  final toolNames = {
    toolName,
    ...additionalToolNames,
  };
  if (toolNames.any((name) => name.isEmpty)) {
    throw ArgumentError.value(
      toolNames,
      'toolNames',
      'hasToolCall requires non-empty tool names.',
    );
  }

  return (context) {
    final steps = context.steps;
    if (steps.isEmpty) {
      return false;
    }

    return steps.last.toolCalls.any(
      (toolCall) => toolNames.contains(toolCall.toolName),
    );
  };
}

Future<bool> isStopConditionMet({
  required List<GenerateTextStopCondition> stopConditions,
  required List<GenerateTextStepResult> steps,
}) async {
  final context = GenerateTextStopConditionContext(steps: steps);
  for (final condition in stopConditions) {
    if (await condition(context)) {
      return true;
    }
  }

  return false;
}
