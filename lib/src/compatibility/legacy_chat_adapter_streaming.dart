part of 'legacy_chat_adapter.dart';

Iterable<ChatStreamEvent> _mapLegacyStreamEvent(
  core.TextStreamEvent event,
  _LegacyStreamState state,
) sync* {
  switch (event) {
    case core.TextDeltaEvent(:final delta):
      state.text.write(delta);
      yield TextDeltaEvent(delta);
    case core.ReasoningDeltaEvent(:final delta):
      state.thinking.write(delta);
      yield ThinkingDeltaEvent(delta);
    case core.ToolInputStartEvent(:final toolCallId, :final toolName):
      state.startToolCall(toolCallId, toolName);
    case core.ToolInputDeltaEvent(:final toolCallId, :final delta):
      final toolCall = state.appendToolCallDelta(toolCallId, delta);
      if (toolCall != null) {
        yield ToolCallDeltaEvent(toolCall);
      }
    case core.ToolInputErrorEvent(
        :final toolCallId,
        :final toolName,
        :final errorText,
        :final input
      ):
      state.failToolCall(
        toolCallId: toolCallId,
        toolName: toolName,
        input: input,
      );
      yield ErrorEvent(GenericError(errorText));
    case core.ToolCallEvent(:final toolCall):
      final legacyToolCall = _toLegacyToolCall(
        toolCall.toolCallId,
        toolCall.toolName,
        toolCall.input,
      );
      state.completeToolCall(legacyToolCall);
      yield ToolCallDeltaEvent(legacyToolCall);
    case core.FinishEvent(:final usage):
      yield CompletionEvent(
        _LegacyChatResponse(
          text: state.text.isEmpty ? null : state.text.toString(),
          toolCalls: state.completedToolCalls.isEmpty
              ? null
              : state.completedToolCalls,
          thinking: state.thinking.isEmpty ? null : state.thinking.toString(),
          usage: _convertUsage(usage),
        ),
      );
    case core.ErrorEvent(:final error):
      yield ErrorEvent(_toLegacyError(error));
    default:
      break;
  }
}

Iterable<ChatStreamEvent> _mapGoogleLegacyStreamEvent(
  core.TextStreamEvent event,
  _GoogleLegacyStreamState state,
) sync* {
  switch (event) {
    case core.TextDeltaEvent(:final delta):
      state.base.text.write(delta);
      yield TextDeltaEvent(delta);
    case core.ReasoningDeltaEvent(:final delta):
      state.base.thinking.write(delta);
      yield ThinkingDeltaEvent(delta);
    case core.ToolInputStartEvent(:final toolCallId, :final toolName):
      state.base.startToolCall(toolCallId, toolName);
    case core.ToolInputDeltaEvent(:final toolCallId, :final delta):
      final toolCall = state.base.appendToolCallDelta(toolCallId, delta);
      if (toolCall != null) {
        yield ToolCallDeltaEvent(toolCall);
      }
    case core.ToolInputErrorEvent(
        :final toolCallId,
        :final toolName,
        :final errorText,
        :final input
      ):
      state.base.failToolCall(
        toolCallId: toolCallId,
        toolName: toolName,
        input: input,
      );
      yield ErrorEvent(GenericError(errorText));
    case core.ToolCallEvent(:final toolCall):
      final legacyToolCall = _toLegacyToolCall(
        toolCall.toolCallId,
        toolCall.toolName,
        toolCall.input,
      );
      state.base.completeToolCall(legacyToolCall);
      yield ToolCallDeltaEvent(legacyToolCall);
    case core.FileEvent(:final file):
      if (file.mediaType.startsWith('image/')) {
        yield TextDeltaEvent('[Generated image: ${file.mediaType}]');
      }
    case core.FinishEvent(:final usage):
      yield CompletionEvent(
        _LegacyChatResponse(
          text: state.base.text.isEmpty ? null : state.base.text.toString(),
          toolCalls: state.base.completedToolCalls.isEmpty
              ? null
              : state.base.completedToolCalls,
          thinking: state.base.thinking.isEmpty
              ? null
              : state.base.thinking.toString(),
          usage: _convertUsage(usage),
        ),
      );
    case core.ErrorEvent(:final error):
      yield ErrorEvent(_toLegacyError(error));
    default:
      break;
  }
}

final class _LegacyStreamState {
  final StringBuffer text = StringBuffer();
  final StringBuffer thinking = StringBuffer();
  final Map<String, _LegacyToolCallState> _toolCalls = {};
  final List<ToolCall> completedToolCalls = <ToolCall>[];

  void startToolCall(String toolCallId, String toolName) {
    _toolCalls.putIfAbsent(
      toolCallId,
      () => _LegacyToolCallState(
        toolCallId: toolCallId,
        toolName: toolName,
      ),
    );
  }

  ToolCall? appendToolCallDelta(String toolCallId, String delta) {
    final state = _toolCalls[toolCallId];
    if (state == null) {
      return null;
    }

    state.arguments.write(delta);
    return ToolCall(
      id: state.toolCallId,
      callType: 'function',
      function: FunctionCall(
        name: state.toolName,
        arguments: state.arguments.toString(),
      ),
    );
  }

  void completeToolCall(ToolCall toolCall) {
    _toolCalls.remove(toolCall.id);
    completedToolCalls.add(toolCall);
  }

  void failToolCall({
    required String toolCallId,
    required String toolName,
    Object? input,
  }) {
    _toolCalls.remove(toolCallId);
    completedToolCalls.removeWhere((toolCall) => toolCall.id == toolCallId);
    if (input != null) {
      completedToolCalls.add(
        ToolCall(
          id: toolCallId,
          callType: 'function',
          function: FunctionCall(
            name: toolName,
            arguments: _encodeJsonValue(input),
          ),
        ),
      );
    }
  }
}

final class _LegacyToolCallState {
  final String toolCallId;
  final String toolName;
  final StringBuffer arguments = StringBuffer();

  _LegacyToolCallState({
    required this.toolCallId,
    required this.toolName,
  });
}

final class _GoogleLegacyStreamState {
  final _LegacyStreamState base = _LegacyStreamState();
}
