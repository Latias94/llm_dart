import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import '../chat_completions/openai_chat_completions_codec.dart';
import '../provider/openai_family_profile.dart';
import 'openai_language_model_call_routing.dart';
import 'openai_language_model_request.dart';
import 'openai_language_model_transport.dart';
import '../responses/openai_responses_codec.dart';
import '../provider/resolved_openai_chat_settings.dart';

final class PreparedOpenAILanguageModelCall {
  final ResolvedOpenAILanguageModelCall call;
  final TransportRequest transportRequest;
  final List<ModelWarning> warnings;

  const PreparedOpenAILanguageModelCall({
    required this.call,
    required this.transportRequest,
    required this.warnings,
  });
}

PreparedOpenAILanguageModelCall prepareOpenAILanguageModelCall({
  required GenerateTextRequest request,
  required String modelId,
  required String baseUrl,
  required OpenAIFamilyProfile profile,
  required String apiKey,
  required ResolvedOpenAIChatModelSettings settings,
  required bool stream,
  required OpenAIResponsesCodec responsesCodec,
  required OpenAIChatCompletionsCodec chatCompletionsCodec,
}) {
  final call = resolveOpenAILanguageModelCall(
    request: request,
    modelId: modelId,
    profile: profile,
    settings: settings,
  );
  final preparedRequest = encodeOpenAILanguageModelRequest(
    call: call,
    request: request,
    stream: stream,
    responsesCodec: responsesCodec,
    chatCompletionsCodec: chatCompletionsCodec,
  );

  return PreparedOpenAILanguageModelCall(
    call: call,
    transportRequest: buildOpenAILanguageModelTransportRequest(
      baseUrl: baseUrl,
      route: call.route,
      request: request,
      stream: stream,
      body: preparedRequest.body,
      profile: profile,
      apiKey: apiKey,
      settings: settings,
    ),
    warnings: preparedRequest.warnings,
  );
}
