import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import '../common/openai_json_support.dart';
import '../language/openai_language_model_call_routing.dart';
import '../language/openai_language_model_route_adapter.dart';
import '../provider/openai_family_route_policy.dart';
import 'openai_responses_codec.dart';

final class OpenAIResponsesLanguageModelRouteAdapter
    implements OpenAILanguageModelRouteAdapter {
  final OpenAIResponsesCodec codec;

  const OpenAIResponsesLanguageModelRouteAdapter({
    this.codec = const OpenAIResponsesCodec(),
  });

  @override
  OpenAIRequestRoute get route => OpenAIRequestRoute.responses;

  @override
  Uri resolveUri(String baseUrl) => Uri.parse('$baseUrl/responses');

  @override
  OpenAILanguageModelPreparedRequest encodeRequest({
    required ResolvedOpenAILanguageModelCall call,
    required GenerateTextRequest request,
    required bool stream,
  }) {
    final preparedRequest = codec.encodeRequest(
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

  @override
  GenerateTextResult decodeGenerateResponse({
    required Object? body,
    required List<ModelWarning> warnings,
  }) {
    return codec.decodeGenerateResponse(
      decodeOpenAIJsonObject(body),
      warnings: warnings,
    );
  }

  @override
  Stream<LanguageModelStreamEvent> decodeStreamEvents({
    required Stream<List<int>> stream,
    required bool includeRawChunks,
    SseJsonChunkParser streamChunkParser = const SseJsonChunkParser(),
  }) {
    return decodeJsonSseLanguageModelStream(
      stream: stream,
      state: OpenAIResponsesStreamState(),
      includeRawChunks: includeRawChunks,
      sourceName: 'OpenAI Responses stream',
      streamChunkParser: streamChunkParser,
      decodeChunk: codec.decodeStreamChunk,
    );
  }
}
