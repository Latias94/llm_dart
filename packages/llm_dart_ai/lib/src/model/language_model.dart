import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../prompt/model_message.dart';
import '../prompt/prompt_normalization.dart';

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
}) {
  final providerPrompt = resolveProviderPrompt(
    prompt: prompt,
    messages: messages,
  );

  return model.doGenerate(
    GenerateTextRequest(
      prompt: providerPrompt,
      tools: tools,
      toolChoice: toolChoice,
      options: options,
      callOptions: callOptions,
    ),
  );
}

Stream<TextStreamEvent> streamText({
  required LanguageModel model,
  List<PromptMessage>? prompt,
  List<ModelMessage>? messages,
  List<FunctionToolDefinition> tools = const [],
  ToolChoice? toolChoice,
  GenerateTextOptions options = const GenerateTextOptions(),
  CallOptions callOptions = const CallOptions(),
}) {
  final providerPrompt = resolveProviderPrompt(
    prompt: prompt,
    messages: messages,
  );

  return model.doStream(
    GenerateTextRequest(
      prompt: providerPrompt,
      tools: tools,
      toolChoice: toolChoice,
      options: options,
      callOptions: callOptions,
    ),
  );
}
