import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../chat_completions/openai_chat_completions_codec.dart';
import 'openai_language_model_call_routing.dart';
import '../responses/openai_responses_codec.dart';

final class OpenAILanguageModelPreparedRequest {
  final Object? body;
  final List<ModelWarning> warnings;

  const OpenAILanguageModelPreparedRequest({
    required this.body,
    required this.warnings,
  });
}

OpenAILanguageModelPreparedRequest encodeOpenAILanguageModelRequest({
  required ResolvedOpenAILanguageModelCall call,
  required GenerateTextRequest request,
  required bool stream,
  required OpenAIResponsesCodec responsesCodec,
  required OpenAIChatCompletionsCodec chatCompletionsCodec,
}) {
  if (call.usesResponsesApi) {
    final preparedRequest = responsesCodec.encodeRequest(
      modelId: call.requestModelId,
      prompt: request.prompt,
      tools: request.tools,
      toolChoice: request.toolChoice,
      options: request.options,
      providerOptions: call.providerOptions.common,
      stream: stream,
    );
    return OpenAILanguageModelPreparedRequest(
      body: preparedRequest.body,
      warnings: preparedRequest.warnings,
    );
  }

  final preparedRequest = chatCompletionsCodec.encodeRequest(
    modelId: call.requestModelId,
    prompt: request.prompt,
    tools: request.tools,
    toolChoice: request.toolChoice,
    options: request.options,
    providerOptions: call.providerOptions,
    stream: stream,
  );
  return OpenAILanguageModelPreparedRequest(
    body: preparedRequest.body,
    warnings: preparedRequest.warnings,
  );
}
