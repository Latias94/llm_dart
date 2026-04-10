import '../../../../core/capability.dart';
import '../../../../models/chat_models.dart';
import '../../../../utils/reasoning_utils.dart';

final RegExp _thinkingTagPattern = RegExp(
  r'<think>(.*?)</think>',
  dotAll: true,
);

/// Mutable stream-parsing state shared by OpenAI compatibility stream codecs.
class OpenAIStreamParsingState {
  bool hasReasoningContent = false;
  String lastChunk = '';
  final StringBuffer thinkingBuffer = StringBuffer();
  final Map<int, String> toolCallIds = {};

  String? get thinkingContent =>
      thinkingBuffer.isNotEmpty ? thinkingBuffer.toString() : null;

  void reset() {
    hasReasoningContent = false;
    lastChunk = '';
    thinkingBuffer.clear();
    toolCallIds.clear();
  }
}

/// Adds reasoning delta events from `reasoning_content` / `reasoning` /
/// `thinking` style fields and returns whether the current payload was fully
/// consumed as reasoning-only content.
bool addOpenAIReasoningDeltaEvents({
  required OpenAIStreamParsingState state,
  required List<ChatStreamEvent> events,
  required Map<String, dynamic>? delta,
}) {
  final reasoningContent = ReasoningUtils.extractReasoningContent(delta);
  if (reasoningContent == null || reasoningContent.isEmpty) {
    return false;
  }

  state.thinkingBuffer.write(reasoningContent);
  state.hasReasoningContent = true;
  events.add(ThinkingDeltaEvent(reasoningContent));
  return true;
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

  if (reasoningDelta != null) {
    final reasoningResult = ReasoningUtils.checkReasoningStatus(
      delta: reasoningDelta,
      hasReasoningContent: state.hasReasoningContent,
      lastChunk: state.lastChunk,
    );
    state.hasReasoningContent = reasoningResult.hasReasoningContent;
  }

  state.lastChunk = content;

  if (ReasoningUtils.containsThinkingTags(content)) {
    final thinkMatch = _thinkingTagPattern.firstMatch(content);
    final thinkingText = thinkMatch?.group(1)?.trim();
    if (thinkingText != null && thinkingText.isNotEmpty) {
      state.thinkingBuffer.write(thinkingText);
      events.add(ThinkingDeltaEvent(thinkingText));
    }
    return;
  }

  events.add(TextDeltaEvent(content));
}

/// Adds incremental tool-call delta events while preserving stable ids for
/// index-addressed streamed tool call chunks.
void addOpenAIToolCallDeltaEvents({
  required OpenAIStreamParsingState state,
  required List<ChatStreamEvent> events,
  required List<dynamic>? toolCalls,
  required void Function(String message) onWarning,
}) {
  if (toolCalls == null || toolCalls.isEmpty) {
    return;
  }

  final toolCallMap = toolCalls.first;
  if (toolCallMap is! Map<String, dynamic>) {
    return;
  }

  final index = toolCallMap['index'] as int?;
  if (index != null) {
    final id = toolCallMap['id'] as String?;
    if (id != null && id.isNotEmpty) {
      state.toolCallIds[index] = id;
    }

    final stableId = state.toolCallIds[index];
    if (stableId == null) {
      return;
    }

    final functionMap = toolCallMap['function'] as Map<String, dynamic>?;
    if (functionMap == null) {
      return;
    }

    final name = functionMap['name'] as String? ?? '';
    final args = functionMap['arguments'] as String? ?? '';
    if (name.isEmpty && args.isEmpty) {
      return;
    }

    events.add(
      ToolCallDeltaEvent(
        ToolCall(
          id: stableId,
          callType: 'function',
          function: FunctionCall(
            name: name,
            arguments: args,
          ),
        ),
      ),
    );
    return;
  }

  if (toolCallMap.containsKey('id') && toolCallMap.containsKey('function')) {
    try {
      events.add(ToolCallDeltaEvent(ToolCall.fromJson(toolCallMap)));
    } catch (error) {
      onWarning('Failed to parse tool call: $error');
    }
  }
}
