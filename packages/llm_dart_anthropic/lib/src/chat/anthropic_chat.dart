import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

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
  final StringBuffer _sseBuffer = StringBuffer();

  AnthropicChat(this.client, this.config) {
    _requestBuilder = AnthropicRequestBuilder(config);
  }

  String get chatEndpoint => 'messages';

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    final requestBody =
        _requestBuilder.buildRequestBody(messages, tools, false);
    final responseData = await client.postJson(
      chatEndpoint,
      requestBody,
      cancelToken: cancelToken,
    );
    return _parseResponse(responseData);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    _resetStreamState();

    final effectiveTools = tools ?? config.tools;
    final requestBody =
        _requestBuilder.buildRequestBody(messages, effectiveTools, true);

    final stream = client.postStreamRaw(
      chatEndpoint,
      requestBody,
      cancelToken: cancelToken,
    );

    await for (final chunk in stream) {
      final events = _parseStreamEvents(chunk);
      for (final event in events) {
        yield event;
      }
    }
  }

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  }) async {
    return chatWithTools(messages, null, cancelToken: cancelToken);
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async => null;

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async {
    final prompt =
        'Summarize in 2-3 sentences:\n${messages.map((m) => '${m.role.name}: ${m.content}').join('\n')}';
    final request = [ChatMessage.user(prompt)];
    final response = await chat(request);
    final text = response.text;
    if (text == null) {
      throw const GenericError('no text in summary response');
    }
    return text;
  }

  Future<int> countTokens(List<ChatMessage> messages,
      {List<Tool>? tools}) async {
    final requestBody = _buildTokenCountRequestBody(messages, tools);

    try {
      final responseData =
          await client.postJson('messages/count_tokens', requestBody);
      return responseData['input_tokens'] as int? ?? 0;
    } catch (e) {
      client.logger.warning('Failed to count tokens: $e');
      final totalChars =
          messages.map((m) => m.content.length).fold(0, (a, b) => a + b);
      return (totalChars / 4).ceil();
    }
  }

  Map<String, dynamic> _buildTokenCountRequestBody(
    List<ChatMessage> messages,
    List<Tool>? tools,
  ) {
    final anthropicMessages = <Map<String, dynamic>>[];
    final systemMessages = <String>[];

    for (final message in messages) {
      if (message.role == ChatRole.system) {
        systemMessages.add(message.content);
      } else {
        anthropicMessages.add(_convertMessage(message));
      }
    }

    final body = <String, dynamic>{
      'model': config.model,
      'messages': anthropicMessages,
    };

    final allSystemPrompts = <String>[];
    if (config.systemPrompt != null && config.systemPrompt!.isNotEmpty) {
      allSystemPrompts.add(config.systemPrompt!);
    }
    allSystemPrompts.addAll(systemMessages);

    if (allSystemPrompts.isNotEmpty) {
      body['system'] = allSystemPrompts.join('\n\n');
    }

    final effectiveTools = tools ?? config.tools;
    if (effectiveTools != null && effectiveTools.isNotEmpty) {
      body['tools'] =
          effectiveTools.map((t) => _requestBuilder.convertTool(t)).toList();
    }

    if (config.reasoning) {
      final thinkingConfig = <String, dynamic>{
        'type': 'enabled',
      };
      if (config.thinkingBudgetTokens != null) {
        thinkingConfig['budget_tokens'] = config.thinkingBudgetTokens;
      }
      body['thinking'] = thinkingConfig;
    }

    return body;
  }

  ChatResponse _parseResponse(Map<String, dynamic> responseData) {
    return AnthropicChatResponse(responseData);
  }

  void _resetStreamState() {
    _activeToolCalls.clear();
    _sseBuffer.clear();
  }

  List<ChatStreamEvent> _parseStreamEvents(String chunk) {
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

  Map<String, dynamic> _convertMessage(ChatMessage message) {
    final content = <Map<String, dynamic>>[];

    final anthropicData =
        message.getExtension<Map<String, dynamic>>('anthropic');

    Map<String, dynamic>? cacheControl;
    if (anthropicData != null) {
      final contentBlocks = anthropicData['contentBlocks'] as List<dynamic>?;
      if (contentBlocks != null) {
        for (final block in contentBlocks) {
          if (block is Map<String, dynamic>) {
            if (block['cache_control'] != null && block['text'] == '') {
              cacheControl = block['cache_control'];
              continue;
            }
            if (block['type'] == 'tools') {
              continue;
            }
            content.add(block);
          }
        }
      }

      if (message.content.isNotEmpty) {
        final textBlock = <String, dynamic>{
          'type': 'text',
          'text': message.content
        };
        if (cacheControl != null) {
          textBlock['cache_control'] = cacheControl;
        }
        content.add(textBlock);
      }
    } else {
      switch (message.messageType) {
        case TextMessage():
          content.add({'type': 'text', 'text': message.content});
          break;
        case ImageMessage(mime: final mime, data: final data):
          final supportedFormats = [
            'image/jpeg',
            'image/png',
            'image/gif',
            'image/webp'
          ];
          if (!supportedFormats.contains(mime.mimeType)) {
            content.add({
              'type': 'text',
              'text':
                  '[Unsupported image format: ${mime.mimeType}. Supported formats: ${supportedFormats.join(', ')}]',
            });
          } else {
            content.add({
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': mime.mimeType,
                'data': base64Encode(data),
              },
            });
          }
          break;
        case FileMessage(mime: final mime, data: final data):
          if (mime.mimeType == 'application/pdf') {
            if (!config.supportsPDF) {
              content.add({
                'type': 'text',
                'text':
                    '[PDF documents are not supported by model ${config.model}]',
              });
            } else {
              content.add({
                'type': 'document',
                'source': {
                  'type': 'base64',
                  'media_type': 'application/pdf',
                  'data': base64Encode(data),
                },
              });
            }
          } else {
            content.add({
              'type': 'text',
              'text':
                  '[File type ${mime.description} (${mime.mimeType}) is not supported by Anthropic. Only PDF documents are supported.]',
            });
          }
          break;
        case ImageUrlMessage(url: final url):
          content.add({
            'type': 'text',
            'text':
                '[Image URL not supported by Anthropic. Please upload the image directly: $url]',
          });
          break;
        case ToolUseMessage(toolCalls: final toolCalls):
          for (final toolCall in toolCalls) {
            try {
              final input = jsonDecode(toolCall.function.arguments);
              content.add({
                'type': 'tool_use',
                'id': toolCall.id,
                'name': toolCall.function.name,
                'input': input,
              });
            } catch (e) {
              client.logger.warning(
                'Failed to parse tool call arguments: ${toolCall.function.arguments}, error: $e',
              );
              content.add({
                'type': 'text',
                'text':
                    '[Error: Invalid tool call arguments for ${toolCall.function.name}]',
              });
            }
          }
          break;
        case ToolResultMessage(results: final results):
          for (final result in results) {
            bool isError = false;
            String resultContent = result.function.arguments;

            try {
              final parsed = jsonDecode(resultContent);
              if (parsed is Map<String, dynamic>) {
                isError = parsed['error'] != null ||
                    parsed['is_error'] == true ||
                    parsed['success'] == false;
              }
            } catch (_) {
              final lowerContent = resultContent.toLowerCase();
              isError = lowerContent.contains('error') ||
                  lowerContent.contains('failed') ||
                  lowerContent.contains('exception');
            }

            content.add({
              'type': 'tool_result',
              'tool_use_id': result.id,
              'content': resultContent,
              'is_error': isError,
            });
          }
          break;
      }
    }

    return {'role': message.role.name, 'content': content};
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
