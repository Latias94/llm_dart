part of 'stream_parsing_support.dart';

const String _thinkingTagStart = '<think>';
const String _thinkingTagEnd = '</think>';

/// Adds reasoning delta events from `reasoning_content` / `reasoning` /
/// `thinking` style fields and returns whether the current payload was fully
/// consumed as reasoning-only content.
bool addOpenAIReasoningDeltaEvents({
  required OpenAIStreamParsingState state,
  required List<ChatStreamEvent> events,
  required Map<String, dynamic>? delta,
}) {
  final reasoningContent = CompatReasoningUtils.extractReasoningContent(delta);
  if (reasoningContent == null || reasoningContent.isEmpty) {
    return false;
  }

  state.thinkingBuffer.write(reasoningContent);
  state.hasReasoningContent = true;
  events.add(ThinkingDeltaEvent(reasoningContent));
  final content = delta?['content'] as String?;
  return content == null || content.isEmpty;
}

/// Adds either text-delta or thinking-delta events from a plain content chunk.
///
/// When `reasoningDelta` is provided, the helper also updates reasoning-state
/// transitions using the existing compatibility reasoning heuristics.
void addOpenAITextDeltaEvents({
  required OpenAIStreamParsingState state,
  required List<ChatStreamEvent> events,
  required String content,
  Map<String, dynamic>? reasoningDelta,
}) {
  if (content.isEmpty) {
    return;
  }

  state.lastChunk = content;
  if (reasoningDelta != null &&
      CompatReasoningUtils.hasReasoningContent(reasoningDelta)) {
    state.hasReasoningContent = true;
  }

  state.appendPendingContent(content);
  _drainOpenAIContentEvents(
    state: state,
    events: events,
  );
}

/// Flushes any pending partial content that was kept to resolve split
/// `<think>` tag boundaries across stream chunks.
void flushOpenAIPendingContentEvents({
  required OpenAIStreamParsingState state,
  required List<ChatStreamEvent> events,
}) {
  final pending = state.pendingContent;
  if (pending.isEmpty) {
    return;
  }

  if (state.isInsideThinkingTag) {
    _emitThinkingDelta(
      state: state,
      events: events,
      content: pending,
    );
  } else {
    _emitTextDelta(
      state: state,
      events: events,
      content: pending,
    );
  }

  state.replacePendingContent('');
}

void _drainOpenAIContentEvents({
  required OpenAIStreamParsingState state,
  required List<ChatStreamEvent> events,
}) {
  var pending = state.pendingContent;

  while (pending.isNotEmpty) {
    if (state.isInsideThinkingTag) {
      final endIndex = pending.indexOf(_thinkingTagEnd);
      if (endIndex >= 0) {
        final reasoning = pending.substring(0, endIndex);
        _emitThinkingDelta(
          state: state,
          events: events,
          content: reasoning,
        );
        pending = pending.substring(endIndex + _thinkingTagEnd.length);
        state.isInsideThinkingTag = false;
        continue;
      }

      final suffixLength = _delimiterSuffixLength(
        pending,
        _thinkingTagEnd,
      );
      final safePrefixLength = pending.length - suffixLength;
      if (safePrefixLength > 0) {
        _emitThinkingDelta(
          state: state,
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
      _emitTextDelta(
        state: state,
        events: events,
        content: visibleText,
      );
      pending = pending.substring(startIndex + _thinkingTagStart.length);
      state.isInsideThinkingTag = true;
      state.hasReasoningContent = true;
      continue;
    }

    final suffixLength = _delimiterSuffixLength(
      pending,
      _thinkingTagStart,
    );
    final safePrefixLength = pending.length - suffixLength;
    if (safePrefixLength > 0) {
      _emitTextDelta(
        state: state,
        events: events,
        content: pending.substring(0, safePrefixLength),
      );
      pending = pending.substring(safePrefixLength);
    }
    break;
  }

  state.replacePendingContent(pending);
}

void _emitThinkingDelta({
  required OpenAIStreamParsingState state,
  required List<ChatStreamEvent> events,
  required String content,
}) {
  if (content.isEmpty) {
    return;
  }

  state.thinkingBuffer.write(content);
  state.hasReasoningContent = true;
  events.add(ThinkingDeltaEvent(content));
}

void _emitTextDelta({
  required OpenAIStreamParsingState state,
  required List<ChatStreamEvent> events,
  required String content,
}) {
  if (content.isEmpty) {
    return;
  }

  state.textBuffer.write(content);
  events.add(TextDeltaEvent(content));
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
