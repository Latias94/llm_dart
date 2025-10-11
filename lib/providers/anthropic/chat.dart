import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/capability.dart';
import '../../core/llm_error.dart';
import '../../models/chat_models.dart';
import '../../models/tool_models.dart';
import 'client.dart';
import 'config.dart';
import 'mcp_models.dart';
import 'request_builder.dart';

/// Anthropic Chat capability implementation
///
/// This module handles all chat-related functionality for Anthropic providers,
/// including streaming, tool calling, and reasoning model support.
///
/// **API Documentation:**
/// - Messages API: https://docs.anthropic.com/en/api/messages
/// - Streaming: https://docs.anthropic.com/en/api/messages-streaming
/// - Tool Use: https://docs.anthropic.com/en/docs/tool-use
/// - Extended Thinking: https://docs.anthropic.com/en/docs/build-with-claude/extended-thinking
/// - Token Counting: https://docs.anthropic.com/en/api/messages-count-tokens
class AnthropicChat implements ChatCapability {
  final AnthropicClient client;
  final AnthropicConfig config;
  late final AnthropicRequestBuilder _requestBuilder;

  AnthropicChat(this.client, this.config) {
    _requestBuilder = AnthropicRequestBuilder(config);
  }

  String get chatEndpoint => 'messages';

  /// Send a chat request with optional tool support
  ///
  /// **API Reference:** https://docs.anthropic.com/en/api/messages
  ///
  /// Supports all Anthropic message types including text, images, PDFs,
  /// tool calls, and extended thinking for supported models.
  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    final requestBody =
        _requestBuilder.buildRequestBody(messages, tools, false);
    // Headers including interleaved thinking beta are automatically handled by AnthropicClient
    final responseData = await client.postJson(
      chatEndpoint,
      requestBody,
      cancelToken: cancelToken,
    );
    return _parseResponse(responseData);
  }

  /// Stream chat responses with real-time events
  ///
  /// **API Reference:** https://docs.anthropic.com/en/api/messages-streaming
  ///
  /// Returns a stream of events including text deltas, thinking deltas,
  /// tool calls, and completion events. Supports all message types and
  /// extended thinking for reasoning models.
  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    final effectiveTools = tools ?? config.tools;
    final requestBody =
        _requestBuilder.buildRequestBody(messages, effectiveTools, true);

    // Create SSE stream - headers are automatically handled by AnthropicClient
    // including interleaved thinking beta header if enabled
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

  /// Count tokens in messages using Anthropic's token counting API
  ///
  /// **API Reference:** https://docs.anthropic.com/en/api/messages-count-tokens
  ///
  /// This uses Anthropic's dedicated endpoint to accurately count tokens
  /// for messages, system prompts, tools, and thinking configurations
  /// without sending an actual chat request. Useful for:
  /// - Cost estimation before sending requests
  /// - Staying within model token limits
  /// - Optimizing prompt length
  Future<int> countTokens(List<ChatMessage> messages,
      {List<Tool>? tools}) async {
    final requestBody = _buildTokenCountRequestBody(messages, tools);

    try {
      final responseData =
          await client.postJson('messages/count_tokens', requestBody);
      return responseData['input_tokens'] as int? ?? 0;
    } catch (e) {
      client.logger.warning('Failed to count tokens: $e');
      // Fallback to rough estimation (4 chars per token)
      final totalChars =
          messages.map((m) => m.content.length).fold(0, (a, b) => a + b);
      return (totalChars / 4).ceil();
    }
  }

  /// Build request body for token counting API
  Map<String, dynamic> _buildTokenCountRequestBody(
      List<ChatMessage> messages, List<Tool>? tools) {
    final anthropicMessages = <Map<String, dynamic>>[];
    final systemMessages = <String>[];

    // Convert messages to Anthropic format (same as chat)
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

    // Add system prompt if present
    final allSystemPrompts = <String>[];
    if (config.systemPrompt != null && config.systemPrompt!.isNotEmpty) {
      allSystemPrompts.add(config.systemPrompt!);
    }
    allSystemPrompts.addAll(systemMessages);

    if (allSystemPrompts.isNotEmpty) {
      body['system'] = allSystemPrompts.join('\n\n');
    }

    // Add tools if provided
    final effectiveTools = tools ?? config.tools;
    if (effectiveTools != null && effectiveTools.isNotEmpty) {
      body['tools'] =
          effectiveTools.map((t) => _requestBuilder.convertTool(t)).toList();
    }

    // Add thinking configuration if enabled
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

  /// Parse response from Anthropic API
  ChatResponse _parseResponse(Map<String, dynamic> responseData) {
    return AnthropicChatResponse(responseData);
  }

  /// Parse stream events from SSE chunks
  List<ChatStreamEvent> _parseStreamEvents(String chunk) {
    final events = <ChatStreamEvent>[];
    final lines = chunk.split('\n');

    for (final line in lines) {
      if (line.startsWith('data: ')) {
        final data = line.substring(6).trim();

        // Handle end of stream
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
          // Skip malformed JSON chunks but log for debugging
          client.logger.fine('Failed to parse stream JSON: $data, error: $e');
          continue;
        }
      } else if (line.startsWith('event: ')) {
        // Handle event type lines (though Anthropic typically uses data lines)
        final eventType = line.substring(7).trim();
        client.logger.fine('Received event type: $eventType');
      }
    }

    return events;
  }

  /// Parse individual stream event
  ChatStreamEvent? _parseStreamEvent(Map<String, dynamic> json) {
    final type = json['type'] as String?;

    switch (type) {
      case 'message_start':
        // Message started - initialize response tracking
        final message = json['message'] as Map<String, dynamic>?;
        if (message != null) {
          final rawUsage = message['usage'];
          if (rawUsage != null) {
            // Safely convert Map<dynamic, dynamic> to Map<String, dynamic>
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
        final contentBlock = json['content_block'] as Map<String, dynamic>?;
        if (contentBlock != null) {
          final blockType = contentBlock['type'] as String?;
          if (blockType == 'tool_use') {
            // Tool use started
            final toolName = contentBlock['name'] as String?;
            final toolId = contentBlock['id'] as String?;
            client.logger.info('Tool use started: $toolName (ID: $toolId)');
          } else if (blockType == 'thinking') {
            // Thinking block started
            client.logger.info('Thinking block started');
          } else if (blockType == 'redacted_thinking') {
            // Redacted thinking block started
            client.logger.info('Redacted thinking block started');
          }
        }
        break;

      case 'content_block_delta':
        final delta = json['delta'] as Map<String, dynamic>?;
        if (delta != null) {
          final deltaType = delta['type'] as String?;

          // Handle text delta
          final text = delta['text'] as String?;
          if (text != null) {
            return TextDeltaEvent(text);
          }

          // Handle thinking delta (extended thinking)
          if (deltaType == 'thinking_delta') {
            final thinkingText = delta['thinking'] as String?;
            if (thinkingText != null) {
              return ThinkingDeltaEvent(thinkingText);
            }
          }

          // Handle signature delta (thinking encryption)
          if (deltaType == 'signature_delta') {
            // Signature deltas are for verification, typically not shown to users
            // We can safely ignore these or log them for debugging
            client.logger
                .fine('Received signature delta for thinking verification');
          }

          // Handle tool use input delta
          final partialJson = delta['partial_json'] as String?;
          if (partialJson != null) {
            client.logger.fine('Tool input delta: $partialJson');
          }
        }
        break;

      case 'content_block_stop':
        final contentBlock = json['content_block'] as Map<String, dynamic>?;
        if (contentBlock != null) {
          final blockType = contentBlock['type'] as String?;
          if (blockType == 'tool_use') {
            // Tool use completed - emit a tool call delta event
            final toolName = contentBlock['name'] as String?;
            final toolId = contentBlock['id'] as String?;
            final input = contentBlock['input'];
            client.logger.info('Tool use completed: $toolName (ID: $toolId)');

            // Create a tool call delta event for completed tool use
            if (toolName != null && toolId != null && input != null) {
              final toolCall = ToolCall(
                id: toolId,
                callType: 'function',
                function: FunctionCall(
                  name: toolName,
                  arguments: jsonEncode(input),
                ),
              );
              return ToolCallDeltaEvent(toolCall);
            }
          } else if (blockType == 'thinking') {
            client.logger.info('Thinking block completed');
          } else if (blockType == 'redacted_thinking') {
            client.logger.info('Redacted thinking block completed');
          }
        }
        break;

      case 'message_delta':
        final delta = json['delta'] as Map<String, dynamic>?;
        if (delta != null) {
          final stopReason = delta['stop_reason'] as String?;
          if (stopReason != null) {
            final rawUsage = json['usage'];
            // Safely convert Map<dynamic, dynamic> to Map<String, dynamic>
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

            // Log special stop reasons
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

          // Map Anthropic error types to our error system
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

  /// Convert ChatMessage to Anthropic format
  /// Note: Anthropic API does not support the 'name' field, so it will be ignored
  Map<String, dynamic> _convertMessage(ChatMessage message) {
    final content = <Map<String, dynamic>>[];

    // Check for Anthropic-specific extensions first
    final anthropicData =
        message.getExtension<Map<String, dynamic>>('anthropic');

    // SIMPLE CACHE CHECK - Look for cache flag in extensions
    Map<String, dynamic>? cacheControl;
    if (anthropicData != null) {
      final contentBlocks = anthropicData['contentBlocks'] as List<dynamic>?;
      if (contentBlocks != null) {
        for (final block in contentBlocks) {
          if (block is Map<String, dynamic>) {
            // Check for cache control - SIMPLE!
            if (block['cache_control'] != null && block['text'] == '') {
              cacheControl = block['cache_control'];
              continue; // Skip adding empty cache marker
            }
            content.add(block);
          }
        }
      }

      // Add regular content with cache if flag is set - SIMPLE!
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
      // Fallback to standard message type handling
      switch (message.messageType) {
        case TextMessage():
          content.add({'type': 'text', 'text': message.content});
          break;
        case ImageMessage(mime: final mime, data: final data):
          // Validate image format for Anthropic
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
          // Handle different file types
          if (mime.mimeType == 'application/pdf') {
            // Anthropic supports PDF documents as a special content type
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
            // Other file types are not supported by Anthropic
            content.add({
              'type': 'text',
              'text':
                  '[File type ${mime.description} (${mime.mimeType}) is not supported by Anthropic. Only PDF documents are supported.]',
            });
          }
          break;
        case ImageUrlMessage(url: final url):
          // Note: Anthropic doesn't support image URLs directly like OpenAI
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
                  'Failed to parse tool call arguments: ${toolCall.function.arguments}, error: $e');
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
            // Parse the result content to determine if it's an error
            bool isError = false;
            String resultContent = result.function.arguments;

            // Try to parse as JSON to check for error indicators
            try {
              final parsed = jsonDecode(resultContent);
              if (parsed is Map<String, dynamic>) {
                isError = parsed['error'] != null ||
                    parsed['is_error'] == true ||
                    parsed['success'] == false;
              }
            } catch (e) {
              // If not valid JSON, check for common error patterns
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

/// Anthropic chat response implementation
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

    // Collect all thinking blocks (including redacted thinking)
    final thinkingBlocks = <String>[];

    for (final block in content) {
      final blockType = block['type'] as String?;
      if (blockType == 'thinking') {
        final thinkingText = block['thinking'] as String?;
        if (thinkingText != null && thinkingText.isNotEmpty) {
          thinkingBlocks.add(thinkingText);
        }
      } else if (blockType == 'redacted_thinking') {
        // For redacted thinking, we can't show the content but we can indicate it exists
        // The actual encrypted data is in the 'data' field but should not be displayed
        thinkingBlocks
            .add('[Redacted thinking content - encrypted for safety]');
      }
    }

    return thinkingBlocks.isEmpty ? null : thinkingBlocks.join('\n\n');
  }

  @override
  List<ToolCall>? get toolCalls {
    final content = _rawResponse['content'] as List?;
    if (content == null || content.isEmpty) return null;

    final toolCalls = <ToolCall>[];

    // Handle regular tool_use blocks
    final toolUseBlocks =
        content.where((block) => block['type'] == 'tool_use').toList();

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

    // Handle MCP tool_use blocks (Anthropic MCP connector)
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

  /// Get Anthropic MCP tool use blocks from the response
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

  /// Get Anthropic MCP tool result blocks from the response
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

    // Safely convert Map<dynamic, dynamic> to Map<String, dynamic>
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

    // Note: Anthropic also provides cache_creation_input_tokens and cache_read_input_tokens
    // These could be exposed in a future version of UsageInfo

    return UsageInfo(
      promptTokens: inputTokens,
      completionTokens: outputTokens,
      totalTokens: inputTokens + outputTokens,
      // Anthropic doesn't provide separate thinking_tokens in usage
      // Thinking content is handled separately through content blocks
      reasoningTokens: null,
    );
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
