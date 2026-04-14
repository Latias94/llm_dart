import 'dart:convert';

import '../../../../core/capability.dart';
import '../../../../core/llm_error.dart';
import '../../../../models/chat_models.dart';
import 'anthropic_chat_response.dart';
import 'client.dart';

/// Stateful SSE parser for the Anthropic compatibility chat shell.
class AnthropicChatStreamParser {
  final AnthropicClient client;
  final Map<int, _ToolCallState> _activeToolCalls = {};
  final StringBuffer _sseBuffer = StringBuffer();

  AnthropicChatStreamParser({
    required this.client,
  });

  void reset() {
    _activeToolCalls.clear();
    _sseBuffer.clear();
  }

  List<ChatStreamEvent> parseChunk(String chunk) {
    final events = <ChatStreamEvent>[];

    _sseBuffer.write(chunk);
    final bufferContent = _sseBuffer.toString();
    final lastNewlineIndex = bufferContent.lastIndexOf('\n');

    if (lastNewlineIndex == -1) {
      return events;
    }

    final completeContent = bufferContent.substring(0, lastNewlineIndex + 1);
    final remainingContent = bufferContent.substring(lastNewlineIndex + 1);

    _sseBuffer.clear();
    if (remainingContent.isNotEmpty) {
      _sseBuffer.write(remainingContent);
    }

    final lines = completeContent.split('\n');

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      if (trimmedLine.startsWith('event: ')) {
        final eventType = trimmedLine.substring(7).trim();
        client.logger.fine('Received event type: $eventType');
        continue;
      }

      if (trimmedLine.startsWith('data: ')) {
        final data = trimmedLine.substring(6).trim();

        if (data == '[DONE]' || data.isEmpty) {
          if (data == '[DONE]') {
            events.add(CompletionEvent(AnthropicChatResponse({})));
          }
          continue;
        }

        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final event = _parseStreamEvent(json);
          if (event != null) {
            events.add(event);
          }
        } catch (e) {
          client.logger.fine(
            'Failed to parse stream JSON: '
            '${data.substring(0, data.length > 50 ? 50 : data.length)}..., '
            'error: $e',
          );
        }
      }
    }

    return events;
  }

  ChatStreamEvent? _parseStreamEvent(Map<String, dynamic> json) {
    final type = json['type'] as String?;

    switch (type) {
      case 'message_start':
        final message = json['message'] as Map<String, dynamic>?;
        if (message != null) {
          final rawUsage = message['usage'];
          if (rawUsage != null) {
            final Map<String, dynamic> usage;
            if (rawUsage is Map<String, dynamic>) {
              usage = rawUsage;
            } else if (rawUsage is Map) {
              usage = Map<String, dynamic>.from(rawUsage);
            } else {
              usage = <String, dynamic>{};
            }

            return CompletionEvent(AnthropicChatResponse({
              'content': [],
              'usage': usage,
            }));
          }
        }
        break;

      case 'content_block_start':
        final index = json['index'] as int?;
        final contentBlock = json['content_block'] as Map<String, dynamic>?;
        if (contentBlock != null) {
          final blockType = contentBlock['type'] as String?;
          if (blockType == 'tool_use') {
            final toolName = contentBlock['name'] as String?;
            final toolId = contentBlock['id'] as String?;
            client.logger.info('Tool use started: $toolName (ID: $toolId)');

            if (index != null) {
              final state = _ToolCallState();
              state.id = toolId;
              state.name = toolName;
              _activeToolCalls[index] = state;
            } else {
              client.logger.severe(
                'Received content_block_start without an index! '
                'toolName: $toolName (ID: $toolId)',
              );
            }
          } else if (blockType == 'thinking') {
            client.logger.info('Thinking block started');
          } else if (blockType == 'redacted_thinking') {
            client.logger.info('Redacted thinking block completed');
          }
        }
        break;

      case 'content_block_delta':
        final index = json['index'] as int?;
        final delta = json['delta'] as Map<String, dynamic>?;
        if (delta != null) {
          final deltaType = delta['type'] as String?;

          final text = delta['text'] as String?;
          if (text != null) {
            return TextDeltaEvent(text);
          }

          if (deltaType == 'thinking_delta') {
            final thinkingText = delta['thinking'] as String?;
            if (thinkingText != null) {
              return ThinkingDeltaEvent(thinkingText);
            }
          }

          if (deltaType == 'signature_delta') {
            client.logger
                .fine('Received signature delta for thinking verification');
          }

          final partialJson = delta['partial_json'] as String?;
          if (partialJson != null && index != null) {
            final state = _activeToolCalls[index];
            if (state != null) {
              state.inputBuffer.write(partialJson);
              client.logger.fine(
                'Accumulated tool input (${state.inputBuffer.length} chars): '
                '$partialJson',
              );
            }
          } else {
            client.logger.severe(
              'Missing required parameter for content_block_delta: '
              'index=$index, partial_json=$partialJson',
            );
          }
        }
        break;

      case 'content_block_stop':
        final index = json['index'] as int?;
        client.logger.info(
          'content_block_stop: index=$index, has content_block='
          '${json.containsKey('content_block')}',
        );

        if (index != null) {
          final state = _activeToolCalls[index];

          client.logger.info(
            'Looking up state for index $index: found=${state != null}, '
            'isComplete=${state?.isComplete}',
          );

          if (state != null && state.isComplete) {
            final accumulatedInput = state.inputBuffer.toString();
            client.logger.info(
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
              client.logger
                  .info('✅ Emitting ToolCallDeltaEvent for ${state.name}');
              return ToolCallDeltaEvent(toolCall);
            } catch (e) {
              client.logger.warning(
                'Failed to parse accumulated tool input: '
                '$accumulatedInput, error: $e',
              );
              _activeToolCalls.remove(index);
            }
          } else if (state != null) {
            client.logger.warning(
              'Tool use state incomplete for block $index: '
              'id=${state.id}, name=${state.name}',
            );
          } else {
            client.logger.warning('No tool use state found for block $index');
          }
        } else {
          client.logger.severe('Received content_block_stop without an index!');
        }
        break;

      case 'message_delta':
        final delta = json['delta'] as Map<String, dynamic>?;
        if (delta != null) {
          final stopReason = delta['stop_reason'] as String?;
          if (stopReason != null) {
            final rawUsage = json['usage'];
            final Map<String, dynamic>? usage;
            if (rawUsage == null) {
              usage = null;
            } else if (rawUsage is Map<String, dynamic>) {
              usage = rawUsage;
            } else if (rawUsage is Map) {
              usage = Map<String, dynamic>.from(rawUsage);
            } else {
              usage = <String, dynamic>{};
            }

            final response = AnthropicChatResponse({
              'content': [],
              'usage': usage,
              'stop_reason': stopReason,
            });

            if (stopReason == 'pause_turn') {
              client.logger
                  .info('Turn paused - long-running operation in progress');
            } else if (stopReason == 'tool_use') {
              client.logger.info('Stopped for tool use');
            }

            return CompletionEvent(response);
          }
        }
        break;

      case 'message_stop':
        return CompletionEvent(AnthropicChatResponse({
          'content': [],
          'usage': {},
        }));

      case 'error':
        final error = json['error'] as Map<String, dynamic>?;
        if (error != null) {
          final message = error['message'] as String? ?? 'Unknown error';
          final errorType = error['type'] as String? ?? 'api_error';

          LLMError llmError;
          switch (errorType) {
            case 'authentication_error':
              llmError = AuthError(message);
              break;
            case 'permission_error':
              llmError = AuthError('Permission denied: $message');
              break;
            case 'invalid_request_error':
              llmError = InvalidRequestError(message);
              break;
            case 'not_found_error':
              llmError = InvalidRequestError('Not found: $message');
              break;
            case 'rate_limit_error':
              llmError = RateLimitError(message);
              break;
            case 'api_error':
            case 'overloaded_error':
              llmError = ProviderError('Anthropic API error: $message');
              break;
            default:
              llmError =
                  ProviderError('Anthropic API error ($errorType): $message');
          }

          return ErrorEvent(llmError);
        }
        break;

      default:
        client.logger.warning('Unknown stream event type: $type');
    }

    return null;
  }
}

class _ToolCallState {
  String? id;
  String? name;
  final StringBuffer inputBuffer = StringBuffer();

  bool get isComplete => id != null && name != null;
}
