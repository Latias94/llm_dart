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
    final streamState = OpenAIResponsesStreamState();
    await for (final chunk in streamChunkParser.parse(stream)) {
      if (includeRawChunks) {
        yield RawChunkEvent(chunk);
      }
      for (final event in responsesCodec.decodeStreamChunk(
        chunk,
        streamState,
      )) {
        yield event;
      }
    }
    return;
  }

  final streamState = OpenAIChatCompletionsStreamState();
  await for (final chunk in streamChunkParser.parse(stream)) {
    if (includeRawChunks) {
      yield RawChunkEvent(chunk);
    }
    for (final event in chatCompletionsCodec.decodeStreamChunk(
      chunk,
      streamState,
    )) {
      yield event;
    }
  }
}
