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
