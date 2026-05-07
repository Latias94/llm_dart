part of 'anthropic_chat_stream_support.dart';

/// Stateful Anthropic stream event decoder.
///
/// This owns provider-specific stream event semantics, including incremental
/// tool-call input aggregation, thinking deltas, stop-reason completion events,
/// and Anthropic error payload mapping.
final class AnthropicChatStreamEventSupport {
  final Logger logger;
  final Map<int, AnthropicToolCallStreamState> _activeToolCalls = {};

  AnthropicChatStreamEventSupport({
    required this.logger,
  });

  void reset() {
    _activeToolCalls.clear();
  }

  ChatStreamEvent? parseStreamEvent(Map<String, dynamic> json) {
    final type = json['type'] as String?;

    switch (type) {
      case 'message_start':
        return _parseMessageStart(json);
      case 'content_block_start':
        _trackContentBlockStart(json);
        break;
      case 'content_block_delta':
        return _parseContentBlockDelta(json);
      case 'content_block_stop':
        return _parseContentBlockStop(json);
      case 'message_delta':
        return _parseMessageDelta(json);
      case 'message_stop':
        return CompletionEvent(AnthropicChatResponse({
          'content': [],
          'usage': {},
        }));
      case 'error':
        return _parseError(json);
      default:
        logger.warning('Unknown stream event type: $type');
    }

    return null;
  }

  ChatStreamEvent? _parseMessageStart(Map<String, dynamic> json) {
    final message = json['message'] as Map<String, dynamic>?;
    if (message == null) {
      return null;
    }

    final rawUsage = message['usage'];
    if (rawUsage == null) {
      return null;
    }

    return CompletionEvent(AnthropicChatResponse({
      'content': [],
      'usage': _mapUsage(rawUsage),
    }));
  }

  void _trackContentBlockStart(Map<String, dynamic> json) {
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

  ChatStreamEvent? _parseContentBlockDelta(Map<String, dynamic> json) {
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

  ChatStreamEvent? _parseContentBlockStop(Map<String, dynamic> json) {
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
      logger.info('✅ Emitting ToolCallDeltaEvent for ${state.name}');
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

  ChatStreamEvent? _parseMessageDelta(Map<String, dynamic> json) {
    final delta = json['delta'] as Map<String, dynamic>?;
    if (delta == null) {
      return null;
    }

    final stopReason = delta['stop_reason'] as String?;
    if (stopReason == null) {
      return null;
    }

    final rawUsage = json['usage'];
    final response = AnthropicChatResponse({
      'content': [],
      'usage': rawUsage == null ? null : _mapUsage(rawUsage),
      'stop_reason': stopReason,
    });

    if (stopReason == 'pause_turn') {
      logger.info('Turn paused - long-running operation in progress');
    } else if (stopReason == 'tool_use') {
      logger.info('Stopped for tool use');
    }

    return CompletionEvent(response);
  }

  ChatStreamEvent? _parseError(Map<String, dynamic> json) {
    final error = json['error'] as Map<String, dynamic>?;
    if (error == null) {
      return null;
    }

    final message = error['message'] as String? ?? 'Unknown error';
    final errorType = error['type'] as String? ?? 'api_error';

    return ErrorEvent(_mapAnthropicError(errorType, message));
  }

  Map<String, dynamic> _mapUsage(Object rawUsage) {
    if (rawUsage is Map<String, dynamic>) {
      return rawUsage;
    }
    if (rawUsage is Map) {
      return Map<String, dynamic>.from(rawUsage);
    }
    return <String, dynamic>{};
  }

  LLMError _mapAnthropicError(String errorType, String message) {
    switch (errorType) {
      case 'authentication_error':
        return AuthError(message);
      case 'permission_error':
        return AuthError('Permission denied: $message');
      case 'invalid_request_error':
        return InvalidRequestError(message);
      case 'not_found_error':
        return InvalidRequestError('Not found: $message');
      case 'rate_limit_error':
        return RateLimitError(message);
      case 'api_error':
      case 'overloaded_error':
        return ProviderError('Anthropic API error: $message');
      default:
        return ProviderError('Anthropic API error ($errorType): $message');
    }
  }
}
