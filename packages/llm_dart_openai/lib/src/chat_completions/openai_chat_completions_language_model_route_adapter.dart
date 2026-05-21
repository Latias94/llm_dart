import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import '../common/openai_json_support.dart';
import '../language/openai_language_model_call_routing.dart';
import '../language/openai_language_model_route_adapter.dart';
import '../provider/openai_family_route_policy.dart';
import '../provider/openai_family_profile.dart';
import 'openai_chat_completions_codec.dart';

final class OpenAIChatCompletionsLanguageModelRouteAdapter
    implements OpenAILanguageModelRouteAdapter {
  final OpenAIChatCompletionsCodec codec;

  const OpenAIChatCompletionsLanguageModelRouteAdapter({
    this.codec = const OpenAIChatCompletionsCodec(),
  });

  factory OpenAIChatCompletionsLanguageModelRouteAdapter.forProfile(
    OpenAIFamilyProfile profile,
  ) {
    return OpenAIChatCompletionsLanguageModelRouteAdapter(
      codec: OpenAIChatCompletionsCodec.forProfile(profile),
    );
  }

  @override
  OpenAIRequestRoute get route => OpenAIRequestRoute.chatCompletions;

  @override
  Uri resolveUri(String baseUrl) => Uri.parse('$baseUrl/chat/completions');

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
      providerOptions: call.providerOptions,
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
      state: OpenAIChatCompletionsStreamState(),
      includeRawChunks: includeRawChunks,
      sourceName: 'OpenAI Chat Completions stream',
      streamChunkParser: streamChunkParser,
      decodeChunk: codec.decodeStreamChunk,
    );
  }
}
