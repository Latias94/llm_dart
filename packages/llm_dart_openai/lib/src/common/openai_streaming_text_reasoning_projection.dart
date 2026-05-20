import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_streaming_state.dart';

void appendOpenAIThinkingAndText(
  String value, {
  required StringBuffer reasoningBuffer,
  required StringBuffer textBuffer,
}) {
  final thinkingMatches = RegExp(r'<think>(.*?)</think>', dotAll: true)
      .allMatches(value)
      .map((match) => match.group(1)?.trim())
      .whereType<String>()
      .where((text) => text.isNotEmpty)
      .toList(growable: false);

  for (final thinking in thinkingMatches) {
    reasoningBuffer.write(thinking);
  }

  final filtered =
      value.replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '');
  if (filtered.isNotEmpty) {
    textBuffer.write(filtered);
  }
}

void appendOpenAILogprobs(
  List<Object?> into,
  List<Object?>? logprobs,
) {
  if (logprobs == null || logprobs.isEmpty) {
    return;
  }

  into.addAll(logprobs);
}

Iterable<LanguageModelStreamEvent> decodeOpenAITextDeltaEvents({
  required OpenAIStreamPartState state,
  required String id,
  required String? delta,
  required ProviderMetadata? Function() startMetadata,
  required ProviderMetadata? Function() deltaMetadata,
  List<Object?>? aggregateLogprobs,
  List<Object?>? deltaLogprobs,
}) sync* {
  if (delta == null || delta.isEmpty) {
    return;
  }

  if (aggregateLogprobs != null) {
    appendOpenAILogprobs(aggregateLogprobs, deltaLogprobs);
  }

  if (state.markStarted(id)) {
    yield TextStartEvent(
      id: id,
      providerMetadata: startMetadata(),
    );
  }

  yield TextDeltaEvent(
    id: id,
    delta: delta,
    providerMetadata: deltaMetadata(),
  );
}

TextStartEvent? maybeCreateOpenAITextStartEvent({
  required OpenAIStreamPartState state,
  required String id,
  required ProviderMetadata? Function() metadata,
}) {
  if (!state.markStarted(id)) {
    return null;
  }

  return TextStartEvent(
    id: id,
    providerMetadata: metadata(),
  );
}

TextEndEvent? maybeCreateOpenAITextEndEvent({
  required OpenAIStreamPartState state,
  required String id,
  required ProviderMetadata? Function() metadata,
  bool allowUnstarted = false,
}) {
  if ((!allowUnstarted && !state.hasStarted(id)) || !state.markEnded(id)) {
    return null;
  }

  return TextEndEvent(
    id: id,
    providerMetadata: metadata(),
  );
}

Iterable<LanguageModelStreamEvent> decodeOpenAIReasoningDeltaEvents({
  required OpenAIStreamPartState state,
  required String id,
  required String? delta,
  required ProviderMetadata? Function() startMetadata,
  required ProviderMetadata? Function() deltaMetadata,
}) sync* {
  if (delta == null || delta.isEmpty) {
    return;
  }

  if (state.markStarted(id)) {
    yield ReasoningStartEvent(
      id: id,
      providerMetadata: startMetadata(),
    );
  }

  yield ReasoningDeltaEvent(
    id: id,
    delta: delta,
    providerMetadata: deltaMetadata(),
  );
}

ReasoningStartEvent? maybeCreateOpenAIReasoningStartEvent({
  required OpenAIStreamPartState state,
  required String id,
  required ProviderMetadata? Function() metadata,
}) {
  if (!state.markStarted(id)) {
    return null;
  }

  return ReasoningStartEvent(
    id: id,
    providerMetadata: metadata(),
  );
}

ReasoningEndEvent? maybeCreateOpenAIReasoningEndEvent({
  required OpenAIStreamPartState state,
  required String id,
  required ProviderMetadata? Function() metadata,
}) {
  if (!state.hasStarted(id) || !state.markEnded(id)) {
    return null;
  }

  return ReasoningEndEvent(
    id: id,
    providerMetadata: metadata(),
  );
}
