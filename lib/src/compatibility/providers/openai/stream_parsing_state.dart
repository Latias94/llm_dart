part of 'stream_parsing_support.dart';

class OpenAIIncrementalToolCallState {
  String? id;
  String? name;
  final StringBuffer arguments = StringBuffer();

  void update({
    String? id,
    String? name,
    String? argumentsDelta,
  }) {
    if (id != null && id.isNotEmpty) {
      this.id = id;
    }

    if (name != null && name.isNotEmpty) {
      this.name = name;
    }

    if (argumentsDelta != null && argumentsDelta.isNotEmpty) {
      arguments.write(argumentsDelta);
    }
  }

  ToolCall buildDeltaToolCall(String argumentsDelta) {
    return ToolCall(
      id: id ?? '',
      callType: 'function',
      function: FunctionCall(
        name: name ?? '',
        arguments: argumentsDelta,
      ),
    );
  }

  ToolCall buildAggregatedToolCall() {
    return ToolCall(
      id: id ?? '',
      callType: 'function',
      function: FunctionCall(
        name: name ?? '',
        arguments: arguments.toString(),
      ),
    );
  }
}

/// Mutable stream-parsing state shared by OpenAI compatibility stream codecs.
class OpenAIStreamParsingState {
  bool hasReasoningContent = false;
  String lastChunk = '';
  final StringBuffer thinkingBuffer = StringBuffer();
  final StringBuffer textBuffer = StringBuffer();
  final StringBuffer _pendingContentBuffer = StringBuffer();
  bool isInsideThinkingTag = false;
  final Map<int, OpenAIIncrementalToolCallState> toolCalls = {};

  String? get thinkingContent =>
      thinkingBuffer.isNotEmpty ? thinkingBuffer.toString() : null;

  String? get textContent =>
      textBuffer.isNotEmpty ? textBuffer.toString() : null;

  Map<int, String> get toolCallIds => {
        for (final entry in toolCalls.entries)
          if (entry.value.id != null && entry.value.id!.isNotEmpty)
            entry.key: entry.value.id!,
      };

  void appendPendingContent(String content) {
    _pendingContentBuffer.write(content);
  }

  String get pendingContent => _pendingContentBuffer.toString();

  void replacePendingContent(String content) {
    _pendingContentBuffer
      ..clear()
      ..write(content);
  }

  List<ToolCall> buildToolCalls() {
    final entries = toolCalls.entries.toList(growable: false)
      ..sort((left, right) => left.key.compareTo(right.key));

    return [
      for (final entry in entries)
        if ((entry.value.id ?? '').isNotEmpty)
          entry.value.buildAggregatedToolCall(),
    ];
  }

  void reset() {
    hasReasoningContent = false;
    lastChunk = '';
    thinkingBuffer.clear();
    textBuffer.clear();
    _pendingContentBuffer.clear();
    isInsideThinkingTag = false;
    toolCalls.clear();
  }
}
