import 'dart:async';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'generate_text_step_result.dart';

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
