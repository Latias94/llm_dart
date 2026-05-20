import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_chat_completions_stream_state.dart';
import 'openai_chat_completions_stream_tool_codec.dart';
import 'openai_chat_completions_stream_util.dart';
import 'openai_chat_completions_support.dart';
import '../common/openai_streaming_support.dart';

const String _openAIChatCompletionsTextId = 'text_0';
const String _openAIChatCompletionsReasoningId = 'reasoning_0';

Iterable<LanguageModelStreamEvent> decodeOpenAIChatCompletionsStreamChunk(
  OpenAIChatCompletionsSupport support,
  Map<String, Object?> chunk,
  OpenAIChatCompletionsStreamState state,
) sync* {
  final metadata = OpenAIChatCompletionsStreamMetadataAdapter(
    support: support,
    state: state,
    chunk: chunk,
  );
  captureOpenAIResponseMetadata(
    state: state,
    responseId: openAIChatCompletionsAsString(chunk['id']),
    responseModelId: openAIChatCompletionsAsString(chunk['model']),
    responseTimestamp: openAIChatCompletionsDecodeResponseTimestamp(chunk),
  );
  final metadataEvent = maybeCreateOpenAIResponseMetadataEvent(
    state: state,
    metadata: metadata.response,
  );
  if (metadataEvent != null) {
    yield metadataEvent;
  }

  final choice = openAIChatCompletionsFirstChoice(chunk);
  if (choice == null) {
    if (openAIChatCompletionsAsMap(chunk['error']) case final error?) {
      yield ErrorEvent(
        ModelError.fromUnknown(
          error,
          kind: ModelErrorKind.provider,
        ),
      );
    }
    return;
  }

  final delta =
      openAIChatCompletionsAsMap(choice['delta']) ?? const <String, Object?>{};
  final textLogprobs = openAIChatCompletionsDecodeLogprobs(choice['logprobs']);
  captureOpenAIResponseMetadata(
    state: state,
    usage: openAIChatCompletionsDecodeUsage(
      openAIChatCompletionsAsMap(chunk['usage']),
    ),
  );

  yield* support.decodeChunkSources(
    chunk,
    responseId: state.responseId,
    emittedSourceIds: state.emittedSourceIds,
  );

  final reasoningDelta = openAIChatCompletionsExtractReasoningDelta(delta);
  yield* decodeOpenAIReasoningDeltaEvents(
    state: state.reasoningParts,
    id: _openAIChatCompletionsReasoningId,
    delta: reasoningDelta,
    startMetadata: metadata.reasoning,
    deltaMetadata: metadata.reasoning,
  );

  final contentDelta = openAIChatCompletionsExtractContentDelta(delta);
  yield* decodeOpenAITextDeltaEvents(
    state: state.textParts,
    id: _openAIChatCompletionsTextId,
    delta: contentDelta,
    aggregateLogprobs: state.logprobs,
    deltaLogprobs: textLogprobs,
    startMetadata: () => metadata.text(textLogprobs),
    deltaMetadata: () => metadata.text(textLogprobs),
  );

  yield* decodeOpenAIChatCompletionsToolCallDeltas(
    delta,
    state,
    metadata,
  );

  final rawFinishReason =
      openAIChatCompletionsAsString(choice['finish_reason']);
  if (rawFinishReason == null) {
    return;
  }

  captureOpenAIResponseMetadata(
    state: state,
    rawFinishReason: rawFinishReason,
  );

  final textEndEvent = maybeCreateOpenAITextEndEvent(
    state: state.textParts,
    id: _openAIChatCompletionsTextId,
    metadata: () => metadata.text(textLogprobs),
  );
  if (textEndEvent != null) {
    yield textEndEvent;
  }

  final reasoningEndEvent = maybeCreateOpenAIReasoningEndEvent(
    state: state.reasoningParts,
    id: _openAIChatCompletionsReasoningId,
    metadata: metadata.reasoning,
  );
  if (reasoningEndEvent != null) {
    yield reasoningEndEvent;
  }

  yield* finalizeOpenAIChatCompletionsToolCalls(state, metadata);

  yield FinishEvent(
    finishReason: openAIChatCompletionsMapFinishReason(rawFinishReason),
    rawFinishReason: rawFinishReason,
    usage: state.usage,
    providerMetadata: metadata.finish(),
  );
}
