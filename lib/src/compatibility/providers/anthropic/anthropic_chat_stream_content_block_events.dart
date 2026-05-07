part of 'anthropic_chat_stream_support.dart';

final class _AnthropicChatStreamContentBlockEvents {
  final Logger logger;
  final Map<int, AnthropicToolCallStreamState> _activeToolCalls = {};

  _AnthropicChatStreamContentBlockEvents({
    required this.logger,
  });

  void reset() {
    _activeToolCalls.clear();
  }

  void trackContentBlockStart(Map<String, dynamic> json) {
    final index = json['index'] as int?;
    final contentBlock = json['content_block'] as Map<String, dynamic>?;
    if (contentBlock == null) {
      return;
    }

    final blockType = contentBlock['type'] as String?;
    if (blockType == 'tool_use') {
      final toolName = contentBlock['name'] as String?;
      final toolId = contentBlock['id'] as String?;
      logger.info('Tool use started: $toolName (ID: $toolId)');

      if (index != null) {
        _activeToolCalls[index] = AnthropicToolCallStreamState(
          id: toolId,
          name: toolName,
        );
      } else {
        logger.severe(
          'Received content_block_start without an index! '
          'toolName: $toolName (ID: $toolId)',
        );
      }
    } else if (blockType == 'thinking') {
      logger.info('Thinking block started');
    } else if (blockType == 'redacted_thinking') {
      logger.info('Redacted thinking block completed');
    }
  }

  ChatStreamEvent? parseContentBlockDelta(Map<String, dynamic> json) {
    final index = json['index'] as int?;
    final delta = json['delta'] as Map<String, dynamic>?;
    if (delta == null) {
      return null;
    }

    final text = delta['text'] as String?;
    if (text != null) {
      return TextDeltaEvent(text);
    }

    final deltaType = delta['type'] as String?;
    if (deltaType == 'thinking_delta') {
      final thinkingText = delta['thinking'] as String?;
      if (thinkingText != null) {
        return ThinkingDeltaEvent(thinkingText);
      }
    }

    if (deltaType == 'signature_delta') {
      logger.fine('Received signature delta for thinking verification');
    }

    final partialJson = delta['partial_json'] as String?;
    if (partialJson != null && index != null) {
      final state = _activeToolCalls[index];
      if (state != null) {
        state.inputBuffer.write(partialJson);
        logger.fine(
          'Accumulated tool input (${state.inputBuffer.length} chars): '
          '$partialJson',
        );
      }
    } else {
      logger.severe(
        'Missing required parameter for content_block_delta: '
        'index=$index, partial_json=$partialJson',
      );
    }

    return null;
  }

  ChatStreamEvent? parseContentBlockStop(Map<String, dynamic> json) {
    final index = json['index'] as int?;
    logger.info(
      'content_block_stop: index=$index, has content_block='
      '${json.containsKey('content_block')}',
    );

    if (index == null) {
      logger.severe('Received content_block_stop without an index!');
      return null;
    }

    final state = _activeToolCalls[index];

    logger.info(
      'Looking up state for index $index: found=${state != null}, '
      'isComplete=${state?.isComplete}',
    );

    if (state != null && state.isComplete) {
      return _buildCompletedToolCall(index, state);
    }

    if (state != null) {
      logger.warning(
        'Tool use state incomplete for block $index: '
        'id=${state.id}, name=${state.name}',
      );
    } else {
      logger.warning('No tool use state found for block $index');
    }

    return null;
  }

  ChatStreamEvent? _buildCompletedToolCall(
    int index,
    AnthropicToolCallStreamState state,
  ) {
    final accumulatedInput = state.inputBuffer.toString();
    logger.info(
      'Tool use completed: ${state.name} (ID: ${state.id}, '
      '${accumulatedInput.length} chars)',
    );

    try {
      final input = jsonDecode(accumulatedInput);
      final toolCall = ToolCall(
        id: state.id!,
        callType: 'function',
        function: FunctionCall(
          name: state.name!,
          arguments: jsonEncode(input),
        ),
      );

      _activeToolCalls.remove(index);
      logger.info('Emitting ToolCallDeltaEvent for ${state.name}');
      return ToolCallDeltaEvent(toolCall);
    } catch (e) {
      logger.warning(
        'Failed to parse accumulated tool input: '
        '$accumulatedInput, error: $e',
      );
      _activeToolCalls.remove(index);
      return null;
    }
  }
}
