import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../chat_completions/openai_chat_completions_codec.dart';
import '../common/openai_json_support.dart';
import 'openai_language_model_call_routing.dart';
import '../responses/openai_responses_codec.dart';

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
