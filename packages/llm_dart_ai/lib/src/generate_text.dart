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
      if (model is PromptChatCapability) {
        response = await (model as PromptChatCapability).chatPrompt(
          prompt,
          tools: tools,
          cancelToken: cancelToken,
        );
      } else {
        requirePromptCapabilityForFileReferenceParts(
          prompt: prompt,
          requiredCapabilityName: '`PromptChatCapability`',
        );
        response = await model.chatWithTools(
          prompt.toChatMessages(),
          tools,
          cancelToken: cancelToken,
        );
      }
  }

  return GenerateTextResult(
    rawResponse: response,
    text: response.text,
    thinking: response.thinking,
    toolCalls: response.toolCalls,
    usage: response.usage,
    finishReason:
        response is ChatResponseWithFinishReason ? response.finishReason : null,
  );
}
