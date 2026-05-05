import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'generate_text_step_result.dart';

final class GenerateTextStepStartEvent {
  final int stepNumber;
  final String providerId;
  final String modelId;
  final GenerateTextRequest request;
  final List<GenerateTextStepResult> previousSteps;

  GenerateTextStepStartEvent({
    required this.stepNumber,
    required this.providerId,
    required this.modelId,
    required this.request,
    List<GenerateTextStepResult> previousSteps = const [],
  }) : previousSteps = List.unmodifiable(previousSteps);
}
