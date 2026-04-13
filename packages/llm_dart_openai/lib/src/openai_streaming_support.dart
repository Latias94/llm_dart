import 'dart:convert';

final class OpenAIStreamPartState {
  final Set<String> _startedIds = {};
  final Set<String> _endedIds = {};

  bool markStarted(String id) => _startedIds.add(id);

  bool markEnded(String id) => _endedIds.add(id);

  bool hasStarted(String id) => _startedIds.contains(id);

  bool hasEnded(String id) => _endedIds.contains(id);
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

String formatInvalidOpenAIToolInputError(
  String toolName,
  FormatException error,
) {
  final message = error.message.trim();
  if (message.isEmpty) {
    return 'Invalid JSON tool arguments for "$toolName".';
  }

  return 'Invalid JSON tool arguments for "$toolName": $message';
}
