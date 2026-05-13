import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../prompt/model_message.dart';
import '../stream/text_stream_event.dart';
import 'generate_text_runner.dart';
import 'generate_text_runner_support.dart';
import 'stream_text_runner.dart';

export 'package:llm_dart_provider/llm_dart_provider.dart'
    show
        FinishReason,
        GenerateTextOptions,
        GenerateTextRequest,
        GenerateTextResult,
        LanguageModel;

Future<GenerateTextResult> generateText({
  required LanguageModel model,
  List<PromptMessage>? prompt,
  List<ModelMessage>? messages,
  List<FunctionToolDefinition> tools = const [],
  ToolChoice? toolChoice,
  GenerateTextOptions options = const GenerateTextOptions(),
  CallOptions callOptions = const CallOptions(),
  GenerateTextFunctionToolExecutor? functionToolExecutor,
  int maxSteps = 8,
  GenerateTextOnStepStart? onStepStart,
  GenerateTextOnStepFinish? onStepFinish,
  GenerateTextOnFinish? onFinish,
  GenerateTextOnError? onError,
}) async {
  final runResult = await runTextGeneration(
    model: model,
    prompt: prompt,
    messages: messages,
    tools: tools,
    toolChoice: toolChoice,
    options: options,
    callOptions: callOptions,
    functionToolExecutor: functionToolExecutor,
    maxSteps: maxSteps,
    onStepStart: onStepStart,
    onStepFinish: onStepFinish,
    onFinish: onFinish,
    onError: onError,
  );

  return runResult.lastStep.result;
}

Stream<TextStreamEvent> streamText({
  required LanguageModel model,
  List<PromptMessage>? prompt,
  List<ModelMessage>? messages,
  List<FunctionToolDefinition> tools = const [],
  ToolChoice? toolChoice,
  GenerateTextOptions options = const GenerateTextOptions(),
  CallOptions callOptions = const CallOptions(),
  GenerateTextFunctionToolExecutor? functionToolExecutor,
  int maxSteps = 8,
  GenerateTextOnStepStart? onStepStart,
  GenerateTextOnStepFinish? onStepFinish,
  GenerateTextOnFinish? onFinish,
  StreamTextOnChunk? onChunk,
  GenerateTextOnError? onError,
}) {
  return streamTextRun(
    model: model,
    prompt: prompt,
    messages: messages,
    tools: tools,
    toolChoice: toolChoice,
    options: options,
    callOptions: callOptions,
    functionToolExecutor: functionToolExecutor,
    maxSteps: maxSteps,
    onStepStart: onStepStart,
    onStepFinish: onStepFinish,
    onFinish: onFinish,
    onChunk: onChunk,
    onError: onError,
  ).eventStream;
}
