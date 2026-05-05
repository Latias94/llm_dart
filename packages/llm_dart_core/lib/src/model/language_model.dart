import 'package:llm_dart_provider/llm_dart_provider.dart';

export 'package:llm_dart_provider/llm_dart_provider.dart'
    show
        FinishReason,
        GenerateTextOptions,
        GenerateTextRequest,
        GenerateTextResult,
        LanguageModel;

Future<GenerateTextResult> generateText({
  required LanguageModel model,
  required List<PromptMessage> prompt,
  List<FunctionToolDefinition> tools = const [],
  ToolChoice? toolChoice,
  GenerateTextOptions options = const GenerateTextOptions(),
  CallOptions callOptions = const CallOptions(),
}) {
  return model.generate(
    GenerateTextRequest(
      prompt: prompt,
      tools: tools,
      toolChoice: toolChoice,
      options: options,
      callOptions: callOptions,
    ),
  );
}

Stream<TextStreamEvent> streamText({
  required LanguageModel model,
  required List<PromptMessage> prompt,
  List<FunctionToolDefinition> tools = const [],
  ToolChoice? toolChoice,
  GenerateTextOptions options = const GenerateTextOptions(),
  CallOptions callOptions = const CallOptions(),
}) {
  return model.stream(
    GenerateTextRequest(
      prompt: prompt,
      tools: tools,
      toolChoice: toolChoice,
      options: options,
      callOptions: callOptions,
    ),
  );
}
