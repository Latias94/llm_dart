import 'package:llm_dart_provider/llm_dart_provider.dart' hide ErrorEvent;

import '../stream/text_stream_event.dart';
import 'generate_text_result_accumulator.dart';
import 'generate_text_step_planner.dart';
import 'generate_text_step_result.dart';
import 'generate_text_tool_execution_projection.dart';
import 'language_model_stream_adapter.dart';
import 'stream_text_cancellation.dart';
import 'stream_text_event_emitter.dart';

final class StreamTextStepExecution {
  final GenerateTextStepResult step;
  final GenerateTextResultAccumulator accumulator;

  const StreamTextStepExecution({
    required this.step,
    required this.accumulator,
  });
}

final class StreamTextStepExecutor {
  final LanguageModel model;
  final CallOptions callOptions;
  final StreamTextEventEmitter emitter;
  final String Function(int stepNumber) stepId;

  const StreamTextStepExecutor({
    required this.model,
    required this.callOptions,
    required this.emitter,
    required this.stepId,
  });

  Future<StreamTextStepExecution> executeStep(
    GenerateTextStepPlan plan, {
    required void Function(GenerateTextResultAccumulator accumulator) beginStep,
    Future<void> Function()? onStepStart,
    required void Function() markStepOpen,
    required void Function() throwIfCancelled,
  }) async {
    final accumulator = GenerateTextResultAccumulator();
    beginStep(accumulator);

    await onStepStart?.call();
    await emitter.add(
      StepStartEvent(stepId: stepId(plan.stepNumber)),
    );
    markStepOpen();
    throwIfCancelled();

    final events = adaptLanguageModelStreamEvents(
      cancelOnProviderCancellation(
        model.doStream(plan.request),
        callOptions.cancellation,
      ),
      context: 'StreamTextRunner.modelStream',
    );
    await for (final event in events) {
      accumulator.apply(event);
      await emitter.add(event);
    }
    throwIfCancelled();

    return StreamTextStepExecution(
      step: GenerateTextStepResult(
        stepNumber: plan.stepNumber,
        providerId: model.providerId,
        modelId: model.modelId,
        request: plan.request,
        result: accumulator.build(),
      ),
      accumulator: accumulator,
    );
  }

  Future<GenerateTextStepResult> applyToolExecutions(
    GenerateTextStepResult step,
    List<GenerateTextToolExecution> executions,
    GenerateTextResultAccumulator accumulator,
  ) async {
    for (final execution in executions) {
      final event = execution.toTextStreamEvent();
      accumulator.apply(event);
      await emitter.add(event);
    }

    return GenerateTextStepResult(
      stepNumber: step.stepNumber,
      providerId: step.providerId,
      modelId: step.modelId,
      request: step.request,
      result: accumulator.build(),
    );
  }
}
