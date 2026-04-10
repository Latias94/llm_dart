import 'dart:async';

import '../../../../core/capability.dart';
import '../../../../core/llm_error.dart';
import '../../../../models/chat_models.dart';
import '../../../../models/tool_models.dart';
import '../../../../utils/reasoning_utils.dart';
import 'client.dart';
import '../../../../providers/openai/config.dart';
import 'config_views.dart';
import 'request_body_support.dart';
import 'stream_parsing_support.dart';

/// OpenAI Chat capability implementation
///
/// This module handles all chat-related functionality for OpenAI providers,
/// including streaming, tool calling, and reasoning model support.
class OpenAIChat implements ChatCapability {
  final OpenAIClient client;
  final OpenAIConfig config;

  // State tracking for stream processing
  final OpenAIStreamParsingState _streamState = OpenAIStreamParsingState();

  OpenAIChat(this.client, this.config);

  String get chatEndpoint => 'chat/completions';

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    TransportCancellation? cancelToken,
  }) async {
    final requestBody = _buildRequestBody(messages, tools, false);
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
    TransportCancellation? cancelToken,
  }) async* {
    final effectiveTools = tools ?? config.tools;
    final requestBody = _buildRequestBody(messages, effectiveTools, true);

    // Reset stream state
    _resetStreamState();

    try {
      // Create SSE stream
      final stream = client.postStreamRaw(
        chatEndpoint,
        requestBody,
        cancelToken: cancelToken,
      );

      await for (final chunk in stream) {
        try {
          final events = _parseStreamEvents(chunk);
          for (final event in events) {
            yield event;
          }
        } catch (e) {
          // Log parsing errors but continue processing
          client.logger.warning('Failed to parse stream chunk: $e');
          // Optionally yield an error event instead of throwing
          // yield ErrorEvent(GenericError('Stream parsing error: $e'));
        }
      }
    } catch (e) {
      // Handle stream creation or connection errors
      if (e is LLMError) {
        rethrow;
      } else {
        throw GenericError('Stream error: $e');
      }
    }
  }

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    TransportCancellation? cancelToken,
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

    // Filter out thinking content for reasoning models
    return ReasoningUtils.filterThinkingContent(text);
  }

  /// Build request body for chat API
  Map<String, dynamic> _buildRequestBody(
    List<ChatMessage> messages,
    List<Tool>? tools,
    bool stream,
  ) {
    final requestConfig = config.requestCompat;
    final apiMessages = buildOpenAICompatApiMessages(
      client: client,
      requestConfig: requestConfig,
      messages: messages,
    );

    final body = <String, dynamic>{
      'model': requestConfig.model,
      'messages': apiMessages,
      'stream': stream,
    };

    // Add reasoning effort parameters
    body.addAll(
      ReasoningUtils.getReasoningEffortParams(
        providerId: client.providerId,
        model: requestConfig.model,
        reasoningEffort: requestConfig.reasoningEffort,
        maxTokens: requestConfig.maxTokens,
      ),
    );

    // Add provider-specific reasoning parameters
    if (client.providerId == 'openrouter' &&
        requestConfig.model.contains('deepseek-r1')) {
      body['include_reasoning'] = true;
    }

    applyOpenAICompatCommonRequestFields(
      body: body,
      client: client,
      config: config,
      requestConfig: requestConfig,
      includeVerbosity: true,
      flattenExtraBody: true,
    );

    // Add tools if provided
    final effectiveTools = tools ?? requestConfig.tools;
    if (effectiveTools != null && effectiveTools.isNotEmpty) {
      body['tools'] = effectiveTools.map((t) => t.toJson()).toList();

      final effectiveToolChoice = requestConfig.toolChoice;
      if (effectiveToolChoice != null) {
        body['tool_choice'] = effectiveToolChoice.toJson();
      }
    }

    return body;
  }

  /// Parse non-streaming response
  ChatResponse _parseResponse(Map<String, dynamic> responseData) {
    // Extract thinking/reasoning content from non-streaming response
    String? thinkingContent;

    final choices = responseData['choices'] as List?;
    if (choices != null && choices.isNotEmpty) {
      final choice = choices.first as Map<String, dynamic>;
      final message = choice['message'] as Map<String, dynamic>?;

      if (message != null) {
        // Check for reasoning content in various possible fields
        thinkingContent = message['reasoning'] as String? ??
            message['thinking'] as String? ??
            message['reasoning_content'] as String?;

        // For models that use <think> tags, extract thinking content
        final content = message['content'] as String?;
        if (content != null && ReasoningUtils.containsThinkingTags(content)) {
          final thinkMatch = RegExp(
            r'<think>(.*?)</think>',
            dotAll: true,
          ).firstMatch(content);
          if (thinkMatch != null) {
            thinkingContent = thinkMatch.group(1)?.trim();
            // Update the message content to remove thinking tags
            message['content'] = ReasoningUtils.filterThinkingContent(content);
          }
        }

        // For OpenRouter with deepseek-r1, check if include_reasoning was used
        if (thinkingContent == null &&
            config.requestCompat.model.contains('deepseek-r1')) {
          final reasoning = responseData['reasoning'] as String?;
          if (reasoning != null && reasoning.isNotEmpty) {
            thinkingContent = reasoning;
          }
        }
      }
    }

    return OpenAIChatResponse(responseData, thinkingContent);
  }

  /// Parse streaming events
  List<ChatStreamEvent> _parseStreamEvents(String chunk) {
    final events = <ChatStreamEvent>[];

    // Parse SSE chunk - now returns a list of JSON objects
    final jsonList = client.parseSSEChunk(chunk);
    if (jsonList.isEmpty) return events;

    // Process each JSON object in the chunk
    for (final json in jsonList) {
      // Use existing stream parsing logic with proper state tracking
      final parsedEvents = _parseStreamEventWithReasoning(
        json,
        _streamState,
      );

      events.addAll(parsedEvents);
    }

    return events;
  }

  /// Reset stream state (call this when starting a new stream)
  void _resetStreamState() {
    _streamState.reset();
  }

  /// Parse stream events with reasoning support
  List<ChatStreamEvent> _parseStreamEventWithReasoning(
    Map<String, dynamic> json,
    OpenAIStreamParsingState state,
  ) {
    final events = <ChatStreamEvent>[];
    final choices = json['choices'] as List?;
    if (choices == null || choices.isEmpty) return events;

    final choice = choices.first as Map<String, dynamic>;
    final delta = choice['delta'] as Map<String, dynamic>?;
    if (delta == null) return events;

    // Handle reasoning content using reasoning utils
    if (addOpenAIReasoningDeltaEvents(
      state: state,
      events: events,
      delta: delta,
    )) {
      return events;
    }

    // Handle regular content
    final content = delta['content'] as String?;
    if (content != null && content.isNotEmpty) {
      addOpenAITextDeltaEvents(
        state: state,
        events: events,
        content: content,
        reasoningDelta: delta,
      );
    }

    // Handle tool calls
    addOpenAIToolCallDeltaEvents(
      state: state,
      events: events,
      toolCalls: delta['tool_calls'] as List?,
      onWarning: client.logger.warning,
    );

    // Check for finish reason
    final finishReason = choice['finish_reason'] as String?;
    if (finishReason != null) {
      final usage = json['usage'] as Map<String, dynamic>?;
      final thinkingContent = state.thinkingContent;

      final response = OpenAIChatResponse({
        'choices': [
          {
            'message': {'content': '', 'role': 'assistant'},
          },
        ],
        if (usage != null) 'usage': usage,
      }, thinkingContent);

      events.add(CompletionEvent(response));

      // Reset state after completion
      state.reset();
    }

    return events;
  }
}

/// OpenAI chat response implementation
class OpenAIChatResponse implements ChatResponse {
  final Map<String, dynamic> _rawResponse;
  final String? _thinkingContent;

  OpenAIChatResponse(this._rawResponse, [this._thinkingContent]);

  @override
  String? get text {
    final choices = _rawResponse['choices'] as List?;
    if (choices == null || choices.isEmpty) return null;

    final message = choices.first['message'] as Map<String, dynamic>?;
    return message?['content'] as String?;
  }

  @override
  List<ToolCall>? get toolCalls {
    final choices = _rawResponse['choices'] as List?;
    if (choices == null || choices.isEmpty) return null;

    final message = choices.first['message'] as Map<String, dynamic>?;
    final toolCalls = message?['tool_calls'] as List?;

    if (toolCalls == null) return null;

    return toolCalls
        .map((tc) => ToolCall.fromJson(tc as Map<String, dynamic>))
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

    return UsageInfo.fromJson(usageData);
  }

  @override
  String? get thinking => _thinkingContent;

  @override
  String toString() {
    final textContent = text;
    final calls = toolCalls;

    if (textContent != null && calls != null) {
      return '${calls.map((c) => c.toString()).join('\n')}\n$textContent';
    } else if (textContent != null) {
      return textContent;
    } else if (calls != null) {
      return calls.map((c) => c.toString()).join('\n');
    } else {
      return '';
    }
  }
}
