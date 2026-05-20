import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_chat_completions_codec.dart';
import 'openai_language_model_prepared_call.dart';
import 'openai_language_model_response.dart';
import 'openai_language_model_stream.dart';
import 'openai_responses_codec.dart';

Future<GenerateTextResult> sendOpenAILanguageModelGenerateCall({
  required TransportClient transport,
  required PreparedOpenAILanguageModelCall preparedCall,
  required OpenAIResponsesCodec responsesCodec,
  required OpenAIChatCompletionsCodec chatCompletionsCodec,
}) async {
  try {
    final response = await transport.send(preparedCall.transportRequest);

    return decodeOpenAILanguageModelGenerateResponse(
      call: preparedCall.call,
      body: response.body,
      warnings: preparedCall.warnings,
      responsesCodec: responsesCodec,
      chatCompletionsCodec: chatCompletionsCodec,
    );
  } catch (error, stackTrace) {
    Error.throwWithStackTrace(
      normalizeTransportCancellation(
        error,
        preparedCall.transportRequest.cancellation?.source,
      ),
      stackTrace,
    );
  }
}

Stream<LanguageModelStreamEvent> sendOpenAILanguageModelStreamCall({
  required TransportClient transport,
  required PreparedOpenAILanguageModelCall preparedCall,
  required bool includeRawChunks,
  required OpenAIResponsesCodec responsesCodec,
  required OpenAIChatCompletionsCodec chatCompletionsCodec,
}) async* {
  yield StartEvent(warnings: preparedCall.warnings);

  try {
    final response = await transport.sendStream(preparedCall.transportRequest);

    yield* decodeOpenAILanguageModelStreamEvents(
      route: preparedCall.call.route,
      stream: response.stream,
      includeRawChunks: includeRawChunks,
      responsesCodec: responsesCodec,
      chatCompletionsCodec: chatCompletionsCodec,
    );
  } catch (error) {
    yield ErrorEvent(transportErrorToModelError(error));
  }
}
