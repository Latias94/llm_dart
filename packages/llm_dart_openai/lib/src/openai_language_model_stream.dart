import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_chat_completions_codec.dart';
import 'openai_language_model_call_routing.dart';
import 'openai_responses_codec.dart';

Stream<LanguageModelStreamEvent> decodeOpenAILanguageModelStreamEvents({
  required OpenAIRequestRoute route,
  required Stream<List<int>> stream,
  required bool includeRawChunks,
  required OpenAIResponsesCodec responsesCodec,
  required OpenAIChatCompletionsCodec chatCompletionsCodec,
  SseJsonChunkParser streamChunkParser = const SseJsonChunkParser(),
}) async* {
  if (route == OpenAIRequestRoute.responses) {
    yield* decodeJsonSseLanguageModelStream(
      stream: stream,
      state: OpenAIResponsesStreamState(),
      includeRawChunks: includeRawChunks,
      sourceName: 'OpenAI Responses stream',
      streamChunkParser: streamChunkParser,
      decodeChunk: responsesCodec.decodeStreamChunk,
    );
    return;
  }

  yield* decodeJsonSseLanguageModelStream(
    stream: stream,
    state: OpenAIChatCompletionsStreamState(),
    includeRawChunks: includeRawChunks,
    sourceName: 'OpenAI Chat Completions stream',
    streamChunkParser: streamChunkParser,
    decodeChunk: chatCompletionsCodec.decodeStreamChunk,
  );
}
