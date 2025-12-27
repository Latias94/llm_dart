part of 'package:llm_dart_anthropic_compatible/chat.dart';

/// Stateful SSE chunk parser for Anthropic ChatStreamEvent streaming.
///
/// This keeps the low-level streaming parsing logic out of `AnthropicChat`,
/// while preserving identical behavior.
class _AnthropicChatSseParser {
  final AnthropicClient client;
  final AnthropicConfig config;

  // Tool call state tracking for streaming.
  // Anthropic splits tool call data across multiple SSE events:
  // 1. content_block_start - contains tool name and id (includes index)
  // 2. content_block_delta (multiple) - contains partial_json chunks (includes index)
  // 3. content_block_stop - signals completion (includes index, no data)
  // The index is provided by Anthropic in each event to track which content block.
  final Map<int, _ToolCallState> _activeToolCalls = {};
  final Map<int, String> _blockTypes = {};
  final Map<int, Map<String, dynamic>> _pendingBlocks = {};
  final Map<int, Map<String, dynamic>> _redactedThinkingBlocks = {};
  final Map<int, List<Map<String, dynamic>>> _textBlockCitations = {};

  final SseChunkParser _parser = SseChunkParser();

  _AnthropicChatSseParser(this.client, this.config);

  final List<Map<String, dynamic>> _contentBlocks = <Map<String, dynamic>>[];

  String? _messageId;
  String? _model;
  String? _stopReason;
  Map<String, dynamic>? _usage;
  dynamic _container;

  var _inText = false;
  var _inThinking = false;
  final _textBuffer = StringBuffer();
  final _thinkingBuffer = StringBuffer();
  int? _currentTextIndex;
  int? _currentThinkingIndex;

  void reset() {
    _activeToolCalls.clear();
    _blockTypes.clear();
    _pendingBlocks.clear();
    _redactedThinkingBlocks.clear();
    _textBlockCitations.clear();
    _parser.reset();

    _contentBlocks.clear();
    _messageId = null;
    _model = null;
    _stopReason = null;
    _usage = null;
    _container = null;

    _inText = false;
    _inThinking = false;
    _textBuffer.clear();
    _thinkingBuffer.clear();
    _currentTextIndex = null;
    _currentThinkingIndex = null;
  }

  Map<String, dynamic>? _coerceMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  void _mergeUsage(dynamic rawUsage) {
    final map = _coerceMap(rawUsage);
    if (map == null) return;
    _usage = {...?_usage, ...map};
  }

  bool _isProviderNativeTool(String requestName, ToolNameMapping mapping) {
    return mapping.providerToolIdForRequestName(requestName) != null ||
        requestName == 'web_search' ||
        requestName == 'web_fetch';
  }

  ToolCall? _buildToolCall(
    _ToolCallState state,
    ToolNameMapping toolNameMapping, {
    required String arguments,
  }) {
    final id = state.id;
    final requestName = state.name;
    if (id == null ||
        id.isEmpty ||
        requestName == null ||
        requestName.isEmpty) {
      return null;
    }

    if (_isProviderNativeTool(requestName, toolNameMapping)) {
      return null;
    }

    final originalToolName =
        toolNameMapping.originalFunctionNameForRequestName(requestName) ??
            requestName;

    return ToolCall(
      id: id,
      callType: 'function',
      function: FunctionCall(
        name: originalToolName,
        arguments: arguments,
      ),
    );
  }

  void _closeOpenTextBlock() {
    if (!_inText) return;
    _inText = false;
    final text = _textBuffer.toString();
    if (text.isNotEmpty) {
      final citations = _currentTextIndex == null
          ? null
          : _textBlockCitations[_currentTextIndex];
      _contentBlocks.add({
        'type': 'text',
        'text': text,
        if (citations != null && citations.isNotEmpty) 'citations': citations,
      });
    }
    _textBuffer.clear();
    if (_currentTextIndex != null) {
      _textBlockCitations.remove(_currentTextIndex);
    }
    _currentTextIndex = null;
  }

  void _closeOpenThinkingBlock() {
    if (!_inThinking) return;
    _inThinking = false;
    final thinking = _thinkingBuffer.toString();
    if (thinking.isNotEmpty) {
      _contentBlocks.add({'type': 'thinking', 'thinking': thinking});
    }
    _thinkingBuffer.clear();
    _currentThinkingIndex = null;
  }

  AnthropicChatResponse _buildCompletionResponse(
      ToolNameMapping toolNameMapping) {
    if (_inText) _closeOpenTextBlock();
    if (_inThinking) _closeOpenThinkingBlock();

    for (final entry in _activeToolCalls.entries.toList(growable: false)) {
      final index = entry.key;
      final state = entry.value;
      if (!state.isComplete) continue;

      dynamic input;
      final accumulatedInput = state.inputBuffer.toString();
      try {
        input = accumulatedInput.isEmpty
            ? <String, dynamic>{}
            : jsonDecode(accumulatedInput);
      } catch (_) {
        input = <String, dynamic>{};
      }

      _contentBlocks.add({
        'type': 'tool_use',
        'id': state.id,
        'name': state.name,
        'input': input,
      });

      _activeToolCalls.remove(index);
    }

    return AnthropicChatResponse(
      {
        'content': _contentBlocks,
        if (_messageId != null) 'id': _messageId,
        if (_model != null) 'model': _model,
        if (_stopReason != null) 'stop_reason': _stopReason,
        if (_usage != null) 'usage': _usage,
        if (_container != null) 'container': _container,
      },
      config.providerId,
      toolNameMapping,
    );
  }

  /// Parse stream events from SSE chunks.
  ///
  /// Anthropic uses SSE format with both event and data lines:
  /// ```
  /// event: message_start
  /// data: {...}
  ///
  /// event: content_block_delta
  /// data: {...}
  /// ```
  ///
  /// This method handles incomplete chunks that can be split across network
  /// boundaries, similar to OpenAI's parseSSEChunk implementation.
  List<ChatStreamEvent> parseChunk(
    String chunk,
    ToolNameMapping toolNameMapping,
  ) {
    final events = <ChatStreamEvent>[];

    final lines = _parser.parse(chunk);
    if (lines.isEmpty) {
      // No complete lines yet, keep buffering.
      return events;
    }

    for (final line in lines) {
      final data = line.data;
      if (line.event != null && line.event!.isNotEmpty) {
        client.logger.fine('Received event type: ${line.event}');
      }

      // Handle end of stream.
      if (data == '[DONE]' || data.isEmpty) {
        if (data == '[DONE]') {
          events.add(
            CompletionEvent(
              _buildCompletionResponse(toolNameMapping),
            ),
          );
        }
        continue;
      }

      try {
        final json = jsonDecode(data) as Map<String, dynamic>;
        events.addAll(_parseStreamEvent(json, toolNameMapping));
      } catch (e) {
        // Skip malformed JSON chunks but log for debugging.
        client.logger.fine(
          'Failed to parse stream JSON: ${data.substring(0, data.length > 50 ? 50 : data.length)}..., error: $e',
        );
        continue;
      }
    }

    return events;
  }

  /// Parse individual stream event.
  List<ChatStreamEvent> _parseStreamEvent(
    Map<String, dynamic> json,
    ToolNameMapping toolNameMapping,
  ) {
    final events = <ChatStreamEvent>[];
    final type = json['type'] as String?;

    switch (type) {
      case 'message_start':
        final message = json['message'] as Map<String, dynamic>?;
        if (message != null) {
          _messageId = message['id'] as String?;
          _model = message['model'] as String?;
          _container = message['container'];
          _mergeUsage(message['usage']);

          // Programmatic tool calling: content may be pre-populated.
          final rawContent = message['content'];
          if (rawContent is List) {
            for (final block in rawContent) {
              if (block is! Map) continue;
              final blockMap = Map<String, dynamic>.from(block);
              if (blockMap['type'] != 'tool_use') continue;

              _contentBlocks.add(blockMap);

              final state = _ToolCallState()
                ..id = blockMap['id'] as String?
                ..name = blockMap['name'] as String?;

              final input = blockMap['input'];
              if (input != null) {
                try {
                  state.inputBuffer.write(jsonEncode(input));
                } catch (_) {}
              }

              final toolCall = _buildToolCall(
                state,
                toolNameMapping,
                arguments: state.inputBuffer.toString(),
              );
              if (toolCall != null) {
                events.add(ToolCallDeltaEvent(toolCall));
              }
            }
          }
        }
        break;

      case 'content_block_start':
        // Get block index from the event.
        final index = json['index'] as int?;

        final contentBlock = json['content_block'] as Map<String, dynamic>?;
        if (contentBlock != null) {
          final blockType = contentBlock['type'] as String?;
          if (index != null && blockType != null) {
            _blockTypes[index] = blockType;
          }

          if (blockType == 'tool_use') {
            // Tool use started - store tool info for accumulation.
            final toolName = contentBlock['name'] as String?;
            final toolId = contentBlock['id'] as String?;
            client.logger.info('Tool use started: $toolName (ID: $toolId)');

            // Initialize tool call state for this block.
            if (index != null) {
              final state = _ToolCallState();
              state.id = toolId;
              state.name = toolName;
              final rawInput = contentBlock['input'];
              if (rawInput is Map && rawInput.isNotEmpty) {
                try {
                  state.inputBuffer.write(jsonEncode(rawInput));
                  state.prefilledInput = true;
                } catch (_) {}
              }
              _activeToolCalls[index] = state;
            } else {
              client.logger.severe(
                'Received content_block_start without an index! toolName: $toolName (ID: $toolId)',
              );
            }
          } else if (blockType == 'thinking') {
            // Thinking block started.
            client.logger.info('Thinking block started');
          } else if (blockType == 'redacted_thinking') {
            if (index != null) {
              _redactedThinkingBlocks[index] =
                  Map<String, dynamic>.from(contentBlock);
            }
          } else if (blockType == 'text') {
            if (_inText) _closeOpenTextBlock();
            _inText = true;
            _currentTextIndex = index;
            final citationsRaw = contentBlock['citations'];
            if (index != null && citationsRaw is List) {
              _textBlockCitations[index] = citationsRaw
                  .whereType<Map>()
                  .map((m) => Map<String, dynamic>.from(m))
                  .toList(growable: true);
            }
          } else if (blockType == 'server_tool_use' ||
              blockType == 'mcp_tool_use' ||
              blockType == 'mcp_tool_result' ||
              blockType == 'web_fetch_tool_result' ||
              blockType == 'web_search_tool_result' ||
              (blockType != null && blockType.endsWith('_tool_result'))) {
            if (index != null) {
              _pendingBlocks[index] = Map<String, dynamic>.from(contentBlock);
            }
          }
        }
        break;

      case 'content_block_delta':
        // Get block index from the event.
        final index = json['index'] as int?;

        final delta = json['delta'] as Map<String, dynamic>?;
        if (delta != null) {
          final deltaType = delta['type'] as String?;

          // Handle text delta.
          final text = delta['text'] as String?;
          if (text != null) {
            if (!_inText) {
              _inText = true;
              _currentTextIndex = index;
            }
            _textBuffer.write(text);
            events.add(TextDeltaEvent(text));
            break;
          }

          // Handle thinking delta (extended thinking).
          if (deltaType == 'thinking_delta') {
            final thinkingText = delta['thinking'] as String?;
            if (thinkingText != null) {
              if (!_inThinking) {
                _inThinking = true;
                _currentThinkingIndex = index;
              }
              _thinkingBuffer.write(thinkingText);
              events.add(ThinkingDeltaEvent(thinkingText));
              break;
            }
          }

          if (deltaType == 'citations_delta') {
            final citation = delta['citation'];
            if (citation is Map &&
                index != null &&
                index == _currentTextIndex) {
              final list = _textBlockCitations.putIfAbsent(
                  index, () => <Map<String, dynamic>>[]);
              list.add(Map<String, dynamic>.from(citation));
            }
          }

          // Handle signature delta (thinking encryption).
          if (deltaType == 'signature_delta') {
            // Signature deltas are for verification, typically not shown to users.
            // We can safely ignore these or log them for debugging.
            client.logger
                .fine('Received signature delta for thinking verification');
          }

          // Handle tool use input delta - accumulate partial_json chunks.
          final partialJson = delta['partial_json'] as String?;
          if (partialJson != null && index != null) {
            final state = _activeToolCalls[index];
            if (state != null) {
              // If we already have prefilled tool input, ignore partial deltas to
              // avoid producing invalid JSON.
              if (!state.prefilledInput) {
                state.inputBuffer.write(partialJson);
              }
            }
          } else {
            client.logger.severe(
              'Missing required parameter for content_block_delta: index=$index, partial_json=$partialJson',
            );
          }
        }
        break;

      case 'content_block_stop':
        // Get block index from the event.
        final index = json['index'] as int?;

        client.logger.info(
          'content_block_stop: index=$index, has content_block=${json.containsKey('content_block')}',
        );

        if (index == null) {
          client.logger.severe('Received content_block_stop without an index!');
          break;
        }

        final blockType = _blockTypes[index];
        if (blockType == 'text' && index == _currentTextIndex) {
          _closeOpenTextBlock();
          break;
        }
        if (blockType == 'thinking' && index == _currentThinkingIndex) {
          _closeOpenThinkingBlock();
          break;
        }
        if (blockType == 'redacted_thinking') {
          final block = _redactedThinkingBlocks.remove(index);
          if (block != null) {
            _contentBlocks.add(block);
          } else {
            _contentBlocks.add({'type': 'redacted_thinking'});
          }
          break;
        }

        if (index != null) {
          final state = _activeToolCalls[index];

          client.logger.info(
            'Looking up state for index $index: found=${state != null}, isComplete=${state?.isComplete}',
          );

          if (state != null && state.isComplete) {
            final accumulatedInput = state.inputBuffer.toString();
            client.logger.info(
              'Tool use completed: ${state.name} (ID: ${state.id}, ${accumulatedInput.length} chars)',
            );

            // Preserve the tool_use block for assistant message continuity.
            dynamic input;
            try {
              input = accumulatedInput.isEmpty
                  ? <String, dynamic>{}
                  : jsonDecode(accumulatedInput);
            } catch (_) {
              input = <String, dynamic>{};
            }

            _contentBlocks.add({
              'type': 'tool_use',
              'id': state.id,
              'name': state.name,
              'input': input,
            });

            final toolCall = _buildToolCall(
              state,
              toolNameMapping,
              arguments: jsonEncode(input),
            );
            if (toolCall != null) {
              client.logger
                  .info('✅ Emitting ToolCallDeltaEvent for ${state.name}');
              events.add(ToolCallDeltaEvent(toolCall));
            }

            _activeToolCalls.remove(index);
          } else if (state != null) {
            client.logger.warning(
              'Tool use state incomplete for block $index: id=${state.id}, name=${state.name}',
            );
          } else {
            client.logger.warning('No tool use state found for block $index');
          }
        }

        final pending = _pendingBlocks.remove(index);
        if (pending != null) {
          _contentBlocks.add(pending);
          break;
        }
        break;

      case 'message_delta':
        final delta = json['delta'] as Map<String, dynamic>?;
        if (delta != null) {
          final stopReason = delta['stop_reason'] as String?;
          if (stopReason != null) {
            _stopReason = stopReason;
            _mergeUsage(json['usage']);

            // Log special stop reasons.
            if (stopReason == 'pause_turn') {
              client.logger.info(
                'Turn paused - long-running operation in progress',
              );
            } else if (stopReason == 'tool_use') {
              client.logger.info('Stopped for tool use');
            }
          }
        }
        break;

      case 'message_stop':
        events.add(
          CompletionEvent(
            _buildCompletionResponse(toolNameMapping),
          ),
        );
        break;

      case 'error':
        final error = json['error'] as Map<String, dynamic>?;
        if (error != null) {
          events.add(ErrorEvent(AnthropicChat._mapAnthropicError(error)));
        }
        break;

      default:
        client.logger.warning('Unknown stream event type: $type');
    }

    return events;
  }
}
