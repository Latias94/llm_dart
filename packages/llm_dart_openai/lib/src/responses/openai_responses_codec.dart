import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../language/openai_generate_text_options.dart';
import 'openai_responses_generate_result_codec.dart';
import 'openai_responses_request_codec.dart';
import 'openai_responses_stream_event_codec.dart';
import 'openai_responses_stream_state.dart';

export 'openai_responses_stream_state.dart';

final class OpenAIResponsesCodec {
  const OpenAIResponsesCodec();

  OpenAIResponsesRequest encodeRequest({
    required String modelId,
    required List<PromptMessage> prompt,
    required List<FunctionToolDefinition> tools,
    required ToolChoice? toolChoice,
    required GenerateTextOptions options,
    required OpenAIGenerateTextOptions providerOptions,
    required bool stream,
  }) {
    return const OpenAIResponsesRequestCodec().encodeRequest(
      modelId: modelId,
      prompt: prompt,
      tools: tools,
      toolChoice: toolChoice,
      options: options,
      providerOptions: providerOptions,
      stream: stream,
    );
  }

  GenerateTextResult decodeGenerateResponse(
    Map<String, Object?> response, {
    List<ModelWarning> warnings = const [],
  }) =>
      decodeOpenAIResponsesGenerateResponse(response, warnings: warnings);

  Iterable<LanguageModelStreamEvent> decodeStreamChunk(
    Map<String, Object?> chunk,
    OpenAIResponsesStreamState state,
  ) =>
      decodeOpenAIResponsesStreamChunk(chunk, state);
}
