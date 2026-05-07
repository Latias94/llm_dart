part of 'stream_parsing_support.dart';

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

      final toolState = state.toolCalls
          .putIfAbsent(index, OpenAIIncrementalToolCallState.new);
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

    if (rawToolCall.containsKey('id') && rawToolCall.containsKey('function')) {
      try {
        events.add(ToolCallDeltaEvent(ToolCall.fromJson(rawToolCall)));
      } catch (error) {
        onWarning('Failed to parse tool call: $error');
      }
    }
  }
}
