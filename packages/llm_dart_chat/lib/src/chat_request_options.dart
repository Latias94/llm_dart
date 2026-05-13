import 'package:llm_dart_ai/llm_dart_ai.dart';

final class ChatRequestOptions {
  final GenerateTextOptions generateOptions;
  final List<FunctionToolDefinition> tools;
  final ToolChoice? toolChoice;
  final CallOptions callOptions;
  final GenerateTextFunctionToolExecutor? functionToolExecutor;
  final int maxSteps;
  final List<GenerateTextStopCondition> stopWhen;
  final GenerateTextOnStepStart? onStepStart;
  final GenerateTextOnStepFinish? onStepFinish;
  final GenerateTextOnToolStart? onToolStart;
  final GenerateTextOnToolFinish? onToolFinish;
  final GenerateTextOnFinish? onFinish;
  final StreamTextOnChunk? onChunk;
  final GenerateTextOnError? onError;
  final Map<String, Object?> metadata;

  const ChatRequestOptions({
    this.generateOptions = const GenerateTextOptions(),
    this.tools = const [],
    this.toolChoice,
    this.callOptions = const CallOptions(),
    this.functionToolExecutor,
    this.maxSteps = 8,
    this.stopWhen = const [],
    this.onStepStart,
    this.onStepFinish,
    this.onToolStart,
    this.onToolFinish,
    this.onFinish,
    this.onChunk,
    this.onError,
    this.metadata = const {},
  });

  bool get hasLocalRuntimeHooks =>
      functionToolExecutor != null ||
      stopWhen.isNotEmpty ||
      onStepStart != null ||
      onStepFinish != null ||
      onToolStart != null ||
      onToolFinish != null ||
      onFinish != null ||
      onChunk != null ||
      onError != null;
}
