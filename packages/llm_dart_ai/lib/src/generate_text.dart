import 'package:llm_dart_core/llm_dart_core.dart';

import 'prompt_input.dart';
import 'types.dart';

/// Generate text (Vercel-style prompt input).
///
/// Provide exactly one of:
/// - [prompt] (plain text prompt)
/// - [messages] (legacy chat message model)
/// - [promptIr] (Prompt IR)
///
/// You can also pass [system] alongside any of them.
Future<GenerateTextResult> generateText({
  required ChatCapability model,
  String? system,
  String? prompt,
  List<ChatMessage>? messages,
  Prompt? promptIr,
  List<Tool>? tools,
  CancelToken? cancelToken,
}) async {
  final input = standardizePromptInput(
    system: system,
    prompt: prompt,
    messages: messages,
    promptIr: promptIr,
  );

  final ChatResponse response;
  switch (input) {
    case StandardizedChatMessages(:final messages):
      response = await model.chatWithTools(
        messages,
        tools,
        cancelToken: cancelToken,
      );

    case StandardizedPromptIr(:final prompt):
      response = model is PromptChatCapability
          ? await (model as PromptChatCapability).chatPrompt(
              prompt,
              tools: tools,
              cancelToken: cancelToken,
            )
          : await model.chatWithTools(
              prompt.toChatMessages(),
              tools,
              cancelToken: cancelToken,
            );
  }

  return GenerateTextResult(
    rawResponse: response,
    text: response.text,
    thinking: response.thinking,
    toolCalls: response.toolCalls,
    usage: response.usage,
  );
}

/// Generate text from a `Prompt` IR (legacy helper).
@Deprecated('Use generateText(model: ..., promptIr: ...) instead.')
Future<GenerateTextResult> generateTextFromPromptIr({
  required ChatCapability model,
  required Prompt prompt,
  List<Tool>? tools,
  CancelToken? cancelToken,
}) =>
    generateText(
      model: model,
      promptIr: prompt,
      tools: tools,
      cancelToken: cancelToken,
    );

/// Generate text from a plain prompt (legacy helper).
@Deprecated('Use generateText(model: ..., system: ..., prompt: ...) instead.')
Future<GenerateTextResult> generateTextFromPrompt({
  required ChatCapability model,
  required String prompt,
  String? systemPrompt,
  List<Tool>? tools,
  CancelToken? cancelToken,
}) {
  return generateText(
    model: model,
    system: systemPrompt,
    prompt: prompt,
    tools: tools,
    cancelToken: cancelToken,
  );
}
