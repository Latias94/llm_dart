import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

final class OpenAIStreamPartState {
  final Set<String> _startedIds = {};
  final Set<String> _endedIds = {};

  bool markStarted(String id) => _startedIds.add(id);

  bool markEnded(String id) => _endedIds.add(id);

  bool hasStarted(String id) => _startedIds.contains(id);

  bool hasEnded(String id) => _endedIds.contains(id);
}

base class OpenAIStreamState {
  final OpenAIIndexedToolCallAccumulator toolCalls =
      OpenAIIndexedToolCallAccumulator();
  final OpenAIStreamPartState textParts = OpenAIStreamPartState();
  final OpenAIStreamPartState reasoningParts = OpenAIStreamPartState();
  final List<Object?> logprobs = [];

  String? responseId;
  DateTime? responseTimestamp;
  String? responseModelId;
  String? serviceTier;
  String? rawFinishReason;
  UsageStats? usage;
  bool hasToolCalls = false;
  bool hasResponseMetadata = false;
}

final class OpenAIStreamToolCallState {
  final int index;
  String? toolCallId;
  String? toolName;
  String? title;
  final StringBuffer arguments = StringBuffer();
  bool startEmitted = false;
  bool endEmitted = false;

  OpenAIStreamToolCallState({
    required this.index,
    this.toolCallId,
    this.toolName,
    this.title,
  });

  void update({
    String? toolCallId,
    String? toolName,
    String? title,
    String? argumentsDelta,
  }) {
    if (toolCallId != null && toolCallId.isNotEmpty) {
      this.toolCallId = toolCallId;
    }

    if (toolName != null && toolName.isNotEmpty) {
      this.toolName = toolName;
    }

    if (title != null && title.isNotEmpty) {
      this.title = title;
    }

    if (argumentsDelta != null && argumentsDelta.isNotEmpty) {
      arguments.write(argumentsDelta);
    }
  }

  String resolveToolCallId(String fallback) => toolCallId ?? fallback;

  String resolveToolName([String fallback = 'function']) =>
      toolName ?? fallback;

  String encodedArguments([String fallback = '{}']) {
    return arguments.isEmpty ? fallback : arguments.toString();
  }
}

final class OpenAIIndexedToolCallAccumulator {
  final Map<int, OpenAIStreamToolCallState> _states = {};

  int get length => _states.length;

  OpenAIStreamToolCallState? operator [](int index) => _states[index];

  OpenAIStreamToolCallState resolve(
    int index, {
    String? toolCallId,
    String? toolName,
    String? title,
  }) {
    final state = _states.putIfAbsent(
      index,
      () => OpenAIStreamToolCallState(index: index),
    );
    state.update(
      toolCallId: toolCallId,
      toolName: toolName,
      title: title,
    );
    return state;
  }

  OpenAIStreamToolCallState? remove(int index) => _states.remove(index);

  List<MapEntry<int, OpenAIStreamToolCallState>> sortedEntries() {
    final entries = _states.entries.toList(growable: false);
    entries.sort((left, right) => left.key.compareTo(right.key));
    return entries;
  }

  void clear() => _states.clear();
}

String? firstOpenAINonEmptyString(Iterable<String?> candidates) {
  for (final candidate in candidates) {
    if (candidate != null && candidate.isNotEmpty) {
      return candidate;
    }
  }

  return null;
}

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

final class OpenAIJsonDecodeResult {
  final Object? value;
  final FormatException? error;

  const OpenAIJsonDecodeResult({
    required this.value,
    this.error,
  });
}

OpenAIJsonDecodeResult tryDecodeOpenAIJsonValue(String value) {
  try {
    return OpenAIJsonDecodeResult(
      value: jsonDecode(value),
    );
  } on FormatException catch (error) {
    return OpenAIJsonDecodeResult(
      value: value,
      error: error,
    );
  } catch (error) {
    return OpenAIJsonDecodeResult(
      value: value,
      error: FormatException(error.toString()),
    );
  }
}

void captureOpenAIResponseMetadata({
  required OpenAIStreamState state,
  String? responseId,
  DateTime? responseTimestamp,
  String? responseModelId,
  String? serviceTier,
  String? rawFinishReason,
  UsageStats? usage,
  bool? hasToolCalls,
}) {
  if (responseId != null) {
    state.responseId = responseId;
  }
  if (responseTimestamp != null) {
    state.responseTimestamp = responseTimestamp;
  }
  if (responseModelId != null) {
    state.responseModelId = responseModelId;
  }
  if (serviceTier != null) {
    state.serviceTier = serviceTier;
  }
  if (rawFinishReason != null) {
    state.rawFinishReason = rawFinishReason;
  }
  if (usage != null) {
    state.usage = usage;
  }
  if (hasToolCalls == true) {
    state.hasToolCalls = true;
  }
}

ResponseMetadataEvent? maybeCreateOpenAIResponseMetadataEvent({
  required OpenAIStreamState state,
  required ProviderMetadata? Function() metadata,
}) {
  if (state.hasResponseMetadata) {
    return null;
  }

  if (state.responseId == null &&
      state.responseModelId == null &&
      state.responseTimestamp == null) {
    return null;
  }

  state.hasResponseMetadata = true;
  return ResponseMetadataEvent(
    responseMetadata: ModelResponseMetadata(
      id: state.responseId,
      timestamp: state.responseTimestamp,
      modelId: state.responseModelId,
    ),
    providerMetadata: metadata(),
  );
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
