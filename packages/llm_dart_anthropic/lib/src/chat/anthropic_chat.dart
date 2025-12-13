// Anthropic chat capability implementation (prompt-first).

import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../client/anthropic_client.dart';
import '../config/anthropic_config.dart';
import '../mcp/anthropic_mcp_models.dart';
import '../request/anthropic_request_builder.dart';

/// Anthropic Chat capability implementation for the sub-package.
class AnthropicChat implements ChatCapability {
  final AnthropicClient client;
  final AnthropicConfig config;
  late final AnthropicRequestBuilder _requestBuilder;

  final Map<int, _ToolCallState> _activeToolCalls = {};
  // Shared SSE line buffer used for streaming responses.
  final SSELineBuffer _sseLineBuffer = SSELineBuffer();

  AnthropicChat(this.client, this.config) {
    _requestBuilder = AnthropicRequestBuilder(config);
  }

  String get chatEndpoint => 'messages';

  @override
  Future<ChatResponse> chat(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async {
    final requestBody = _requestBuilder.buildRequestBodyFromPrompt(
      messages,
      tools,
      false,
      options: options,
    );
    final responseData = await client.postJson(
      chatEndpoint,
      requestBody,
      cancelToken: CancellationUtils.toDioCancelToken(cancelToken),
    );
    return _parseResponse(responseData);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async* {
    _resetStreamState();

    final requestBody = _requestBuilder.buildRequestBodyFromPrompt(
      messages,
      tools,
      true,
      options: options,
    );

    final stream = client.postStreamRaw(
      chatEndpoint,
      requestBody,
      cancelToken: CancellationUtils.toDioCancelToken(cancelToken),
    );

    await for (final chunk in stream) {
      final events = _parseStreamEvents(chunk);
      for (final event in events) {
        yield event;
      }
    }
  }

  Future<int> countTokens(
    List<ModelMessage> messages, {
    List<Tool>? tools,
  }) async {
    final requestBody = _requestBuilder.buildRequestBodyFromPrompt(
      messages,
      tools,
      false,
    );

    // The count_tokens endpoint only needs the prompt shape; remove
    // generation-specific settings to avoid provider-side validation errors.
    requestBody.remove('max_tokens');
    requestBody.remove('stream');
    requestBody.remove('temperature');
    requestBody.remove('top_p');
    requestBody.remove('top_k');

    try {
      final responseData =
          await client.postJson('messages/count_tokens', requestBody);
      return responseData['input_tokens'] as int? ?? 0;
    } catch (e) {
      client.logger.warning('Failed to count tokens: $e');

      var totalChars = 0;
      for (final message in messages) {
        for (final part in message.parts) {
          if (part is TextContentPart) {
            totalChars += part.text.length;
          } else if (part is ReasoningContentPart) {
            totalChars += part.text.length;
          }
        }
      }

      return (totalChars / 4).ceil();
    }
  }

  ChatResponse _parseResponse(Map<String, dynamic> responseData) {
    return AnthropicChatResponse(responseData);
  }

  void _resetStreamState() {
    _activeToolCalls.clear();
    _sseLineBuffer.clear();
  }

  List<ChatStreamEvent> _parseStreamEvents(String chunk) {
    final events = <ChatStreamEvent>[];

    final lines = _sseLineBuffer.addChunk(chunk);
    if (lines.isEmpty) return events;

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
            'Failed to parse stream JSON: ${data.substring(0, data.length > 50 ? 50 : data.length)}..., error: $e',
          );
          continue;
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

            final response = AnthropicChatResponse({
              'content': [],
              'usage': usage,
            });
            return CompletionEvent(response);
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
                'Received content_block_start without an index! toolName: $toolName (ID: $toolId)',
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

          if (deltaType == 'tool_use_delta') {
            final indexValue = index ?? 0;
            final state = _activeToolCalls[indexValue];
            if (state == null) {
              client.logger.warning(
                'Received tool_use_delta for unknown index: $indexValue',
              );
              return null;
            }

            final partialJson = delta['partial_json'] as String?;
            if (partialJson != null) {
              state.inputBuffer.write(partialJson);

              try {
                final completeJson = state.inputBuffer.toString();
                if (completeJson.isNotEmpty) {
                  final input = jsonDecode(completeJson);
                  final toolCall = ToolCall(
                    id: state.id ?? 'unknown',
                    callType: 'function',
                    function: FunctionCall(
                      name: state.name ?? 'unknown',
                      arguments: jsonEncode(input),
                    ),
                  );
                  return ToolCallDeltaEvent(toolCall);
                }
              } catch (_) {
                // Wait for more chunks
              }
            }
          }
        }
        break;

      case 'content_block_stop':
        final index = json['index'] as int?;
        if (index != null) {
          _activeToolCalls.remove(index);
        }
        break;

      case 'message_delta':
        final delta = json['delta'] as Map<String, dynamic>?;
        if (delta != null) {
          final stopReason = delta['stop_reason'] as String?;
          final stopSequence = delta['stop_sequence'] as String?;
          final rawUsage = delta['usage'];
          final Map<String, dynamic>? usage;
          if (rawUsage == null) {
            usage = null;
          } else if (rawUsage is Map<String, dynamic>) {
            usage = rawUsage;
          } else if (rawUsage is Map) {
            usage = Map<String, dynamic>.from(rawUsage);
          } else {
            usage = null;
          }

          if (stopReason != null || usage != null || stopSequence != null) {
            final response = AnthropicChatResponse({
              'content': [],
              if (usage != null) 'usage': usage,
              if (stopReason != null) 'stop_reason': stopReason,
              if (stopSequence != null) 'stop_sequence': stopSequence,
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
        final response = AnthropicChatResponse({
          'content': [],
          'usage': {},
        });
        return CompletionEvent(response);

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

class AnthropicChatResponse implements ChatResponse {
  final Map<String, dynamic> _rawResponse;

  AnthropicChatResponse(this._rawResponse);

  @override
  String? get text {
    final content = _rawResponse['content'] as List?;
    if (content == null || content.isEmpty) return null;

    final textBlocks = content
        .where((block) => block['type'] == 'text')
        .map((block) => block['text'] as String?)
        .where((text) => text != null)
        .cast<String>();

    return textBlocks.isEmpty ? null : textBlocks.join('\n');
  }

  @override
  String? get thinking {
    final content = _rawResponse['content'] as List?;
    if (content == null || content.isEmpty) return null;

    final thinkingBlocks = content
        .where((block) =>
            block['type'] == 'thinking' || block['type'] == 'redacted_thinking')
        .map((block) => block['thinking'] as String?)
        .where((text) => text != null)
        .cast<String>();

    return thinkingBlocks.isEmpty ? null : thinkingBlocks.join('\n');
  }

  @override
  List<ToolCall>? get toolCalls {
    final content = _rawResponse['content'] as List?;
    if (content == null || content.isEmpty) return null;

    final toolUseBlocks =
        content.where((block) => block['type'] == 'tool_use').toList();

    if (toolUseBlocks.isEmpty) return null;

    final toolCalls = <ToolCall>[];

    for (final block in toolUseBlocks) {
      toolCalls.add(ToolCall(
        id: block['id'] as String,
        callType: 'function',
        function: FunctionCall(
          name: block['name'] as String,
          arguments: jsonEncode(block['input']),
        ),
      ));
    }

    final mcpToolUseBlocks =
        content.where((block) => block['type'] == 'mcp_tool_use').toList();

    for (final block in mcpToolUseBlocks) {
      toolCalls.add(ToolCall(
        id: block['id'] as String,
        callType: 'mcp_function',
        function: FunctionCall(
          name: block['name'] as String,
          arguments: jsonEncode(block['input']),
        ),
      ));
    }

    return toolCalls.isEmpty ? null : toolCalls;
  }

  List<AnthropicMCPToolUse>? get mcpToolUses {
    final content = _rawResponse['content'] as List?;
    if (content == null || content.isEmpty) return null;

    final mcpToolUseBlocks =
        content.where((block) => block['type'] == 'mcp_tool_use').toList();

    if (mcpToolUseBlocks.isEmpty) return null;

    return mcpToolUseBlocks
        .map((block) => AnthropicMCPToolUse.fromJson(block))
        .toList();
  }

  List<AnthropicMCPToolResult>? get mcpToolResults {
    final content = _rawResponse['content'] as List?;
    if (content == null || content.isEmpty) return null;

    final mcpToolResultBlocks =
        content.where((block) => block['type'] == 'mcp_tool_result').toList();

    if (mcpToolResultBlocks.isEmpty) return null;

    return mcpToolResultBlocks
        .map((block) => AnthropicMCPToolResult.fromJson(block))
        .toList();
  }

  @override
  UsageInfo? get usage {
    final rawUsage = _rawResponse['usage'];
    if (rawUsage == null) return null;

    final Map<String, dynamic> usageData;
    if (rawUsage is Map<String, dynamic>) {
      usageData = rawUsage;
    } else if (rawUsage is Map) {
      usageData = Map<String, dynamic>.from(rawUsage);
    } else {
      return null;
    }

    final inputTokens = usageData['input_tokens'] as int? ?? 0;
    final outputTokens = usageData['output_tokens'] as int? ?? 0;

    return UsageInfo(
      promptTokens: inputTokens,
      completionTokens: outputTokens,
      totalTokens: inputTokens + outputTokens,
      reasoningTokens: null,
    );
  }

  @override
  List<CallWarning> get warnings => const [];

  @override
  Map<String, dynamic>? get metadata {
    final model = _rawResponse['model'] as String?;
    final id = _rawResponse['id'] as String?;
    final stopReason = _rawResponse['stop_reason'] as String?;

    final content = _rawResponse['content'] as List?;
    bool hasThinkingBlocks = false;
    bool hasMcpToolUse = false;
    bool hasMcpToolResult = false;

    if (content != null) {
      for (final block in content) {
        final type = block['type'] as String?;
        if (type == null) continue;
        if (type == 'thinking' || type == 'redacted_thinking') {
          hasThinkingBlocks = true;
        } else if (type == 'mcp_tool_use') {
          hasMcpToolUse = true;
        } else if (type == 'mcp_tool_result') {
          hasMcpToolResult = true;
        }
      }
    }

    return {
      'provider': 'anthropic',
      if (id != null) 'id': id,
      if (model != null) 'model': model,
      if (stopReason != null) 'stopReason': stopReason,
      'hasThinking': hasThinkingBlocks,
      'hasMcpToolUse': hasMcpToolUse,
      'hasMcpToolResult': hasMcpToolResult,
    };
  }

  @override
  CallMetadata? get callMetadata {
    final data = metadata;
    if (data == null) return null;
    return CallMetadata.fromJson(data);
  }

  @override
  String toString() {
    final textContent = text;
    final calls = toolCalls;
    final thinkingContent = thinking;

    final parts = <String>[];

    if (thinkingContent != null) {
      parts.add('Thinking: $thinkingContent');
    }

    if (calls != null) {
      parts.add(calls.map((c) => c.toString()).join('\n'));
    }

    if (textContent != null) {
      parts.add(textContent);
    }

    return parts.join('\n');
  }
}

class _ToolCallState {
  String? id;
  String? name;
  final StringBuffer inputBuffer = StringBuffer();

  bool get isComplete => id != null && name != null;
}
