import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_chat_completions_codec.dart';
import 'openai_language_model_support.dart';
import 'openai_responses_codec.dart';

GenerateTextResult decodeOpenAILanguageModelGenerateResponse({
  required ResolvedOpenAILanguageModelCall call,
  required Object? body,
  required List<ModelWarning> warnings,
  required OpenAIResponsesCodec responsesCodec,
  required OpenAIChatCompletionsCodec chatCompletionsCodec,
}) {
  final json = decodeOpenAIJsonObject(body);
  if (call.usesResponsesApi) {
    return responsesCodec.decodeGenerateResponse(
      json,
      warnings: warnings,
    );
  }

  return chatCompletionsCodec.decodeGenerateResponse(
    json,
    warnings: warnings,
  );
}
