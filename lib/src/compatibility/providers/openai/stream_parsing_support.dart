import '../../../../core/capability.dart';
import '../../../../models/chat_models.dart';
import '../../reasoning_utils.dart';

const String _thinkingTagStart = '<think>';
const String _thinkingTagEnd = '</think>';

/// Stateful text, reasoning, and tool-call delta codec shared by the OpenAI
/// compatibility Chat Completions and Responses stream parsers.
final class OpenAIStreamParsingCodec {
  final _OpenAIStreamParsingState _state = _OpenAIStreamParsingState();

  String? get thinkingContent => _state.thinkingContent;

  String? get textContent => _state.textContent;

  List<ToolCall> buildToolCalls() {
    return _state.buildToolCalls();
  }

  void reset() {
    _state.reset();
  }

  /// Adds reasoning delta events from `reasoning_content` / `reasoning` /
  /// `thinking` style fields and returns whether the current payload was fully
  /// consumed as reasoning-only content.
  bool addReasoningDeltaEvents({
    required List<ChatStreamEvent> events,
    required Map<String, dynamic>? delta,
  }) {
    final reasoningContent =
        CompatReasoningUtils.extractReasoningContent(delta);
    if (reasoningContent == null || reasoningContent.isEmpty) {
      return false;
    }

    _state.thinkingBuffer.write(reasoningContent);
    _state.hasReasoningContent = true;
    events.add(ThinkingDeltaEvent(reasoningContent));
    final content = delta?['content'] as String?;
    return content == null || content.isEmpty;
  }

  /// Adds either text-delta or thinking-delta events from a plain content
  /// chunk.
  ///
  /// When `reasoningDelta` is provided, the helper also updates
  /// reasoning-state transitions using the existing compatibility reasoning
  /// heuristics.
  void addTextDeltaEvents({
    required List<ChatStreamEvent> events,
    required String content,
    Map<String, dynamic>? reasoningDelta,
  }) {
    if (content.isEmpty) {
      return;
    }

    _state.lastChunk = content;
    if (reasoningDelta != null &&
        CompatReasoningUtils.hasReasoningContent(reasoningDelta)) {
      _state.hasReasoningContent = true;
    }

    _state.appendPendingContent(content);
    _drainContentEvents(events);
  }

  /// Flushes any pending partial content that was kept to resolve split
  /// `<think>` tag boundaries across stream chunks.
  void flushPendingContentEvents({
    required List<ChatStreamEvent> events,
  }) {
    final pending = _state.pendingContent;
    if (pending.isEmpty) {
      return;
    }

    if (_state.isInsideThinkingTag) {
      _emitThinkingDelta(events: events, content: pending);
    } else {
      _emitTextDelta(events: events, content: pending);
    }

    _state.replacePendingContent('');
  }

  /// Adds incremental tool-call delta events while preserving stable ids for
  /// index-addressed streamed tool call chunks.
  void addToolCallDeltaEvents({
    required List<ChatStreamEvent> events,
    required List<dynamic>? toolCalls,
    required void Function(String message) onWarning,
  }) {
    if (toolCalls == null || toolCalls.isEmpty) {
      return;
    }

    for (final rawToolCall in toolCalls) {
      if (rawToolCall is! Map<String, dynamic>) {
        continue;
      }

      final index = rawToolCall['index'] as int?;
      if (index != null) {
        final functionMap = rawToolCall['function'] as Map<String, dynamic>?;
        final id = rawToolCall['id'] as String?;
        final name = functionMap?['name'] as String?;
        final args = functionMap?['arguments'] as String? ?? '';

        final toolState = _state.toolCalls
            .putIfAbsent(index, _OpenAIIncrementalToolCallState.new);
        toolState.update(
          id: id,
          name: name,
          argumentsDelta: args,
        );

        final stableId = toolState.id;
        if (stableId == null || stableId.isEmpty) {
          continue;
        }

        if ((toolState.name ?? '').isEmpty && args.isEmpty) {
          continue;
        }

        events.add(ToolCallDeltaEvent(toolState.buildDeltaToolCall(args)));
        continue;
      }

      if (rawToolCall.containsKey('id') &&
          rawToolCall.containsKey('function')) {
        try {
          events.add(ToolCallDeltaEvent(ToolCall.fromJson(rawToolCall)));
        } catch (error) {
          onWarning('Failed to parse tool call: $error');
        }
      }
    }
  }

  void _drainContentEvents(List<ChatStreamEvent> events) {
    var pending = _state.pendingContent;

    while (pending.isNotEmpty) {
      if (_state.isInsideThinkingTag) {
        final endIndex = pending.indexOf(_thinkingTagEnd);
        if (endIndex >= 0) {
          final reasoning = pending.substring(0, endIndex);
          _emitThinkingDelta(events: events, content: reasoning);
          pending = pending.substring(endIndex + _thinkingTagEnd.length);
          _state.isInsideThinkingTag = false;
          continue;
        }

        final suffixLength = _delimiterSuffixLength(
          pending,
          _thinkingTagEnd,
        );
        final safePrefixLength = pending.length - suffixLength;
        if (safePrefixLength > 0) {
          _emitThinkingDelta(
            events: events,
            content: pending.substring(0, safePrefixLength),
          );
          pending = pending.substring(safePrefixLength);
        }
        break;
      }

      final startIndex = pending.indexOf(_thinkingTagStart);
      if (startIndex >= 0) {
        final visibleText = pending.substring(0, startIndex);
        _emitTextDelta(events: events, content: visibleText);
        pending = pending.substring(startIndex + _thinkingTagStart.length);
        _state.isInsideThinkingTag = true;
        _state.hasReasoningContent = true;
        continue;
      }

      final suffixLength = _delimiterSuffixLength(
        pending,
        _thinkingTagStart,
      );
      final safePrefixLength = pending.length - suffixLength;
      if (safePrefixLength > 0) {
        _emitTextDelta(
          events: events,
          content: pending.substring(0, safePrefixLength),
        );
        pending = pending.substring(safePrefixLength);
      }
      break;
    }

    _state.replacePendingContent(pending);
  }

  void _emitThinkingDelta({
    required List<ChatStreamEvent> events,
    required String content,
  }) {
    if (content.isEmpty) {
      return;
    }

    _state.thinkingBuffer.write(content);
    _state.hasReasoningContent = true;
    events.add(ThinkingDeltaEvent(content));
  }

  void _emitTextDelta({
    required List<ChatStreamEvent> events,
    required String content,
  }) {
    if (content.isEmpty) {
      return;
    }

    _state.textBuffer.write(content);
    events.add(TextDeltaEvent(content));
  }
}

final class _OpenAIIncrementalToolCallState {
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
final class _OpenAIStreamParsingState {
  bool hasReasoningContent = false;
  String lastChunk = '';
  final StringBuffer thinkingBuffer = StringBuffer();
  final StringBuffer textBuffer = StringBuffer();
  final StringBuffer _pendingContentBuffer = StringBuffer();
  bool isInsideThinkingTag = false;
  final Map<int, _OpenAIIncrementalToolCallState> toolCalls = {};

  String? get thinkingContent =>
      thinkingBuffer.isNotEmpty ? thinkingBuffer.toString() : null;

  String? get textContent =>
      textBuffer.isNotEmpty ? textBuffer.toString() : null;

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

int _delimiterSuffixLength(String value, String delimiter) {
  final maxLength = delimiter.length - 1;
  final upperBound = value.length < maxLength ? value.length : maxLength;

  for (var length = upperBound; length > 0; length--) {
    if (value.endsWith(delimiter.substring(0, length))) {
      return length;
    }
  }

  return 0;
}
