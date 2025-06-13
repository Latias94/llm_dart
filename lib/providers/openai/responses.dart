import 'dart:async';

import '../../core/capability.dart';
import '../../core/llm_error.dart';
import '../../models/chat_models.dart';
import '../../models/responses_models.dart';
import '../../models/tool_models.dart';
import '../../utils/reasoning_utils.dart';
import 'client.dart';
import 'config.dart';
import 'responses_capability.dart';

/// OpenAI Responses API capability implementation
///
/// This module handles the new Responses API which combines the simplicity
/// of Chat Completions with the tool-use capabilities of the Assistants API.
/// It supports built-in tools like web search, file search, and computer use.
class OpenAIResponses implements ChatCapability, OpenAIResponsesCapability {
  final OpenAIClient client;
  final OpenAIConfig config;

  // State tracking for stream processing
  bool _hasReasoningContent = false;
  String _lastChunk = '';
  final StringBuffer _thinkingBuffer = StringBuffer();

  OpenAIResponses(this.client, this.config);

  String get responsesEndpoint => 'responses';

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools,
  ) async {
    final requestBody = _buildRequestBody(messages, tools, false, false);
    final responseData = await client.postJson(responsesEndpoint, requestBody);
    return _parseResponse(responseData);
  }

  /// Create a response with background processing
  ///
  /// When background=true, the response will be processed asynchronously.
  /// You can retrieve the result later using getResponse() or cancel it with cancelResponse().
  @override
  Future<ChatResponse> chatWithToolsBackground(
    List<ChatMessage> messages,
    List<Tool>? tools,
  ) async {
    final requestBody = _buildRequestBody(messages, tools, false, true);
    final responseData = await client.postJson(responsesEndpoint, requestBody);
    return _parseResponse(responseData);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
  }) async* {
    final effectiveTools = tools ?? config.tools;
    final requestBody =
        _buildRequestBody(messages, effectiveTools, true, false);

    // Reset stream state
    _resetStreamState();

    try {
      // Create SSE stream
      final stream = client.postStreamRaw(responsesEndpoint, requestBody);

      await for (final chunk in stream) {
        try {
          final events = _parseStreamEvents(chunk);
          for (final event in events) {
            yield event;
          }
        } catch (e) {
          // Log parsing errors but continue processing
          client.logger.warning('Failed to parse stream chunk: $e');
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
  Future<ChatResponse> chat(List<ChatMessage> messages) async {
    return chatWithTools(messages, null);
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

  // ========== Responses API CRUD Operations ==========

  /// Retrieve a model response by ID
  ///
  /// This allows you to fetch a previously created response using its ID.
  /// Useful for stateful conversations and response chaining.
  @override
  Future<ChatResponse> getResponse(
    String responseId, {
    List<String>? include,
    int? startingAfter,
    bool stream = false,
  }) async {
    var endpoint = '$responsesEndpoint/$responseId';

    // Build query parameters
    final queryParams = <String, String>{};
    if (include != null && include.isNotEmpty) {
      queryParams['include'] = include.join(',');
    }
    if (startingAfter != null) {
      queryParams['starting_after'] = startingAfter.toString();
    }
    if (stream) {
      queryParams['stream'] = stream.toString();
    }

    // Append query parameters to endpoint
    if (queryParams.isNotEmpty) {
      final queryString = queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      endpoint = '$endpoint?$queryString';
    }

    final responseData = await client.get(endpoint);
    return _parseResponse(responseData);
  }

  /// Delete a model response by ID
  ///
  /// Permanently removes a stored response from OpenAI's servers.
  /// Returns true if deletion was successful.
  @override
  Future<bool> deleteResponse(String responseId) async {
    try {
      final endpoint = '$responsesEndpoint/$responseId';
      final responseData = await client.delete(endpoint);
      return responseData['deleted'] == true;
    } on LLMError {
      rethrow;
    } catch (e) {
      client.logger.warning('Failed to delete response $responseId: $e');
      throw OpenAIResponsesError(
        'Failed to delete response: $e',
        responseId: responseId,
        errorType: 'deletion_failed',
      );
    }
  }

  /// Cancel a background response by ID
  ///
  /// Only responses created with background=true can be cancelled.
  /// Returns the cancelled response object.
  @override
  Future<ChatResponse> cancelResponse(String responseId) async {
    final endpoint = '$responsesEndpoint/$responseId/cancel';
    final responseData = await client.postJson(endpoint, {});
    return _parseResponse(responseData);
  }

  /// List input items for a response
  ///
  /// Returns the input items that were used to generate a specific response.
  /// Useful for debugging and understanding response context.
  @override
  Future<ResponseInputItemsList> listInputItems(
    String responseId, {
    String? after,
    String? before,
    List<String>? include,
    int limit = 20,
    String order = 'desc',
  }) async {
    var endpoint = '$responsesEndpoint/$responseId/input_items';

    // Build query parameters
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'order': order,
    };

    if (after != null) queryParams['after'] = after;
    if (before != null) queryParams['before'] = before;
    if (include != null && include.isNotEmpty) {
      queryParams['include'] = include.join(',');
    }

    // Append query parameters to endpoint
    final queryString = queryParams.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    endpoint = '$endpoint?$queryString';

    final responseData = await client.get(endpoint);
    return ResponseInputItemsList.fromJson(responseData);
  }

  // ========== Conversation State Management ==========

  /// Create a new response that continues from a previous response
  ///
  /// This enables stateful conversations where the provider maintains
  /// the conversation history automatically.
  @override
  Future<ChatResponse> continueConversation(
    String previousResponseId,
    List<ChatMessage> newMessages, {
    List<Tool>? tools,
    bool background = false,
  }) async {
    // Create a new config with the previous response ID
    final updatedConfig =
        config.copyWith(previousResponseId: previousResponseId);
    final tempResponses = OpenAIResponses(client, updatedConfig);

    final requestBody =
        tempResponses._buildRequestBody(newMessages, tools, false, background);
    final responseData = await client.postJson(responsesEndpoint, requestBody);
    return _parseResponse(responseData);
  }

  /// Fork a conversation from a specific response
  ///
  /// Creates a new conversation branch starting from the specified response.
  /// Useful for exploring different conversation paths.
  @override
  Future<ChatResponse> forkConversation(
    String fromResponseId,
    List<ChatMessage> newMessages, {
    List<Tool>? tools,
    bool background = false,
  }) async {
    // Fork is the same as continue for OpenAI Responses API
    return continueConversation(fromResponseId, newMessages,
        tools: tools, background: background);
  }

  /// Build request body for Responses API
  Map<String, dynamic> _buildRequestBody(
    List<ChatMessage> messages,
    List<Tool>? tools,
    bool stream,
    bool background,
  ) {
    // Convert messages to API format
    final apiMessages = client.buildApiMessages(messages);

    // Handle system prompt: prefer explicit system messages over config
    final hasSystemMessage = messages.any((m) => m.role == ChatRole.system);

    // Only add config system prompt if no explicit system message exists
    if (!hasSystemMessage && config.systemPrompt != null) {
      apiMessages.insert(0, {'role': 'system', 'content': config.systemPrompt});
    }

    final body = <String, dynamic>{
      'model': config.model,
      'input':
          apiMessages.length == 1 ? apiMessages.first['content'] : apiMessages,
      'stream': stream,
      'background': background,
    };

    // Add previous response ID for chaining
    if (config.previousResponseId != null) {
      body['previous_response_id'] = config.previousResponseId;
    }

    // Add optional parameters using reasoning utils
    body.addAll(
      ReasoningUtils.getMaxTokensParams(
        model: config.model,
        maxTokens: config.maxTokens,
      ),
    );

    // Add temperature if not disabled for reasoning models
    if (config.temperature != null &&
        !ReasoningUtils.shouldDisableTemperature(config.model)) {
      body['temperature'] = config.temperature;
    }

    // Add top_p if not disabled for reasoning models
    if (config.topP != null &&
        !ReasoningUtils.shouldDisableTopP(config.model)) {
      body['top_p'] = config.topP;
    }
    if (config.topK != null) body['top_k'] = config.topK;

    // Add reasoning effort parameters (Responses API format)
    if (config.reasoningEffort != null) {
      body['reasoning'] = {
        'effort': config.reasoningEffort!.value,
      };
    }

    // Build tools array combining function tools and built-in tools
    final allTools = <Map<String, dynamic>>[];

    // Add function tools (convert to Responses API format)
    final effectiveTools = tools ?? config.tools;
    if (effectiveTools != null && effectiveTools.isNotEmpty) {
      allTools
          .addAll(effectiveTools.map((t) => _convertToolToResponsesFormat(t)));
    }

    // Add built-in tools
    if (config.builtInTools != null && config.builtInTools!.isNotEmpty) {
      allTools.addAll(config.builtInTools!.map((t) => t.toJson()));
    }

    if (allTools.isNotEmpty) {
      body['tools'] = allTools;

      // Add tool choice if configured (only for function tools)
      final effectiveToolChoice = config.toolChoice;
      if (effectiveToolChoice != null &&
          effectiveTools != null &&
          effectiveTools.isNotEmpty) {
        body['tool_choice'] = effectiveToolChoice.toJson();
      }
    }

    // Add structured output if configured
    if (config.jsonSchema != null) {
      final schema = config.jsonSchema!;
      final responseFormat = <String, dynamic>{
        'type': 'json_schema',
        'json_schema': schema.toJson(),
      };

      // Ensure additionalProperties is set to false for OpenAI compliance
      if (schema.schema != null) {
        final schemaMap = Map<String, dynamic>.from(schema.schema!);
        if (!schemaMap.containsKey('additionalProperties')) {
          schemaMap['additionalProperties'] = false;
        }
        responseFormat['json_schema'] = {
          'name': schema.name,
          if (schema.description != null) 'description': schema.description,
          'schema': schemaMap,
          if (schema.strict != null) 'strict': schema.strict,
        };
      }

      body['response_format'] = responseFormat;
    }

    // Add common parameters
    if (config.stopSequences != null && config.stopSequences!.isNotEmpty) {
      body['stop'] = config.stopSequences;
    }

    if (config.user != null) {
      body['user'] = config.user;
    }

    if (config.serviceTier != null) {
      body['service_tier'] = config.serviceTier!.value;
    }

    // Add OpenAI-specific extension parameters
    final frequencyPenalty = config.getExtension<double>('frequencyPenalty');
    if (frequencyPenalty != null) {
      body['frequency_penalty'] = frequencyPenalty;
    }

    final presencePenalty = config.getExtension<double>('presencePenalty');
    if (presencePenalty != null) {
      body['presence_penalty'] = presencePenalty;
    }

    final logitBias = config.getExtension<Map<String, double>>('logitBias');
    if (logitBias != null && logitBias.isNotEmpty) {
      body['logit_bias'] = logitBias;
    }

    final seed = config.getExtension<int>('seed');
    if (seed != null) {
      body['seed'] = seed;
    }

    final parallelToolCalls = config.getExtension<bool>('parallelToolCalls');
    if (parallelToolCalls != null) {
      body['parallel_tool_calls'] = parallelToolCalls;
    }

    final logprobs = config.getExtension<bool>('logprobs');
    if (logprobs != null) {
      body['logprobs'] = logprobs;
    }

    final topLogprobs = config.getExtension<int>('topLogprobs');
    if (topLogprobs != null) {
      body['top_logprobs'] = topLogprobs;
    }

    return body;
  }

  /// Parse non-streaming response
  ChatResponse _parseResponse(Map<String, dynamic> responseData) {
    // Extract thinking/reasoning content from Responses API format
    String? thinkingContent;

    // Parse the output array from Responses API
    final output = responseData['output'] as List?;
    if (output != null) {
      // Look for reasoning items in the output array
      for (final item in output) {
        if (item is Map<String, dynamic> && item['type'] == 'reasoning') {
          // Extract reasoning summary if available
          final summary = item['summary'] as List?;
          if (summary != null && summary.isNotEmpty) {
            final summaryItem = summary.first as Map<String, dynamic>?;
            thinkingContent = summaryItem?['text'] as String?;
          }
          break;
        }
      }
    }

    // Fallback: Check for reasoning content in other fields
    if (thinkingContent == null) {
      // Check if reasoning is an object with summary field
      final reasoning = responseData['reasoning'];
      if (reasoning is Map<String, dynamic>) {
        thinkingContent = reasoning['summary'] as String?;
      } else if (reasoning is String) {
        thinkingContent = reasoning;
      }

      // Fallback to other possible fields
      thinkingContent ??= responseData['thinking'] as String? ??
          responseData['reasoning_content'] as String?;
    }

    return OpenAIResponsesResponse(responseData, thinkingContent);
  }

  /// Parse streaming events
  List<ChatStreamEvent> _parseStreamEvents(String chunk) {
    final events = <ChatStreamEvent>[];

    // Parse SSE chunk
    final json = client.parseSSEChunk(chunk);
    if (json == null) return events;

    // Use existing stream parsing logic with proper state tracking
    final parsedEvents = _parseStreamEventWithReasoning(
      json,
      _hasReasoningContent,
      _lastChunk,
      _thinkingBuffer,
    );

    events.addAll(parsedEvents);
    return events;
  }

  /// Reset stream state (call this when starting a new stream)
  void _resetStreamState() {
    _hasReasoningContent = false;
    _lastChunk = '';
    _thinkingBuffer.clear();
  }

  /// Parse stream events with reasoning support
  List<ChatStreamEvent> _parseStreamEventWithReasoning(
    Map<String, dynamic> json,
    bool hasReasoningContent,
    String lastChunk,
    StringBuffer thinkingBuffer,
  ) {
    final events = <ChatStreamEvent>[];

    // Handle Responses API streaming events
    final eventType = json['type'] as String?;

    if (eventType == 'response.output_text.delta') {
      // Handle text delta events from Responses API
      final delta = json['delta'] as String?;
      if (delta != null && delta.isNotEmpty) {
        _lastChunk = delta;

        // Filter out thinking tags for models that use <think> tags
        if (ReasoningUtils.containsThinkingTags(delta)) {
          // Extract thinking content and add to buffer
          final thinkMatch = RegExp(
            r'<think>(.*?)</think>',
            dotAll: true,
          ).firstMatch(delta);
          if (thinkMatch != null) {
            final thinkingText = thinkMatch.group(1)?.trim();
            if (thinkingText != null && thinkingText.isNotEmpty) {
              thinkingBuffer.write(thinkingText);
              events.add(ThinkingDeltaEvent(thinkingText));
            }
          }
          // Don't emit content that contains thinking tags
          return events;
        }

        events.add(TextDeltaEvent(delta));
        return events;
      }
    }

    if (eventType == 'response.completed') {
      // Handle completion event
      final response = json['response'] as Map<String, dynamic>?;
      if (response != null) {
        final thinkingContent =
            thinkingBuffer.isNotEmpty ? thinkingBuffer.toString() : null;

        final completionResponse =
            OpenAIResponsesResponse(response, thinkingContent);
        events.add(CompletionEvent(completionResponse));

        // Reset state after completion
        _resetStreamState();
        return events;
      }
    }

    // Handle reasoning content using reasoning utils (fallback)
    final reasoningContent = ReasoningUtils.extractReasoningContent(json);
    if (reasoningContent != null && reasoningContent.isNotEmpty) {
      thinkingBuffer.write(reasoningContent);
      _hasReasoningContent = true; // Update state
      events.add(ThinkingDeltaEvent(reasoningContent));
      return events;
    }

    // Legacy format: Handle regular content from output_text_delta
    final content = json['output_text_delta'] as String?;
    if (content != null && content.isNotEmpty) {
      // Update last chunk for reasoning detection
      _lastChunk = content;

      // Check reasoning status using utils
      final reasoningResult = ReasoningUtils.checkReasoningStatus(
        delta: {'content': content}, // Adapt to reasoning utils format
        hasReasoningContent: _hasReasoningContent,
        lastChunk: lastChunk,
      );

      // Update state based on reasoning detection
      _hasReasoningContent = reasoningResult.hasReasoningContent;

      // Filter out thinking tags for models that use <think> tags
      if (ReasoningUtils.containsThinkingTags(content)) {
        // Extract thinking content and add to buffer
        final thinkMatch = RegExp(
          r'<think>(.*?)</think>',
          dotAll: true,
        ).firstMatch(content);
        if (thinkMatch != null) {
          final thinkingText = thinkMatch.group(1)?.trim();
          if (thinkingText != null && thinkingText.isNotEmpty) {
            thinkingBuffer.write(thinkingText);
            events.add(ThinkingDeltaEvent(thinkingText));
          }
        }
        // Don't emit content that contains thinking tags
        return events;
      }

      events.add(TextDeltaEvent(content));
    }

    // Handle tool calls (if supported in Responses API)
    final toolCalls = json['tool_calls'] as List?;
    if (toolCalls != null && toolCalls.isNotEmpty) {
      final toolCall = toolCalls.first as Map<String, dynamic>;
      if (toolCall.containsKey('id') && toolCall.containsKey('function')) {
        try {
          events.add(ToolCallDeltaEvent(ToolCall.fromJson(toolCall)));
        } catch (e) {
          // Skip malformed tool calls
          client.logger.warning('Failed to parse tool call: $e');
        }
      }
    }

    // Check for finish reason
    final finishReason = json['finish_reason'] as String?;
    if (finishReason != null) {
      final usage = json['usage'] as Map<String, dynamic>?;
      final thinkingContent =
          thinkingBuffer.isNotEmpty ? thinkingBuffer.toString() : null;

      final response = OpenAIResponsesResponse({
        'output_text': '',
        if (usage != null) 'usage': usage,
      }, thinkingContent);

      events.add(CompletionEvent(response));

      // Reset state after completion
      _resetStreamState();
    }

    return events;
  }

  /// Convert Tool to Responses API format
  ///
  /// Responses API expects a flattened format instead of nested function object
  Map<String, dynamic> _convertToolToResponsesFormat(Tool tool) {
    return {
      'type': 'function',
      'name': tool.function.name,
      'description': tool.function.description,
      'parameters': tool.function.parameters.toJson(),
    };
  }
}

/// OpenAI Responses API response implementation
class OpenAIResponsesResponse implements ChatResponse {
  final Map<String, dynamic> _rawResponse;
  final String? _thinkingContent;

  OpenAIResponsesResponse(this._rawResponse, [this._thinkingContent]);

  @override
  String? get text {
    // First try the Responses API format
    final output = _rawResponse['output'] as List?;
    if (output != null) {
      // Look for message items in the output array
      for (final item in output) {
        if (item is Map<String, dynamic> && item['type'] == 'message') {
          final content = item['content'] as List?;
          if (content != null) {
            // Find text content in the content array
            for (final contentItem in content) {
              if (contentItem is Map<String, dynamic> &&
                  contentItem['type'] == 'output_text') {
                return contentItem['text'] as String?;
              }
            }
          }
        }
      }
    }

    // Fallback to legacy format
    return _rawResponse['output_text'] as String?;
  }

  @override
  List<ToolCall>? get toolCalls {
    // First try the Responses API format
    final output = _rawResponse['output'] as List?;
    if (output != null) {
      final toolCalls = <ToolCall>[];

      // Look for function_call items in the output array
      for (final item in output) {
        if (item is Map<String, dynamic> && item['type'] == 'function_call') {
          try {
            // Convert Responses API function call format to ToolCall
            final toolCall = ToolCall(
              id: item['call_id'] as String? ?? item['id'] as String? ?? '',
              callType: 'function',
              function: FunctionCall(
                name: item['name'] as String? ?? '',
                arguments: item['arguments'] as String? ?? '{}',
              ),
            );
            toolCalls.add(toolCall);
          } catch (e) {
            // Skip malformed tool calls silently
            // Logging should be handled at a higher level
          }
        }
      }

      if (toolCalls.isNotEmpty) return toolCalls;
    }

    // Fallback to legacy format
    final toolCalls = _rawResponse['tool_calls'] as List?;
    if (toolCalls == null) return null;

    return toolCalls
        .map((tc) => ToolCall.fromJson(tc as Map<String, dynamic>))
        .toList();
  }

  @override
  UsageInfo? get usage {
    final usageData = _rawResponse['usage'] as Map<String, dynamic>?;
    if (usageData == null) return null;

    return UsageInfo.fromJson(usageData);
  }

  @override
  String? get thinking => _thinkingContent;

  /// Get the response ID for chaining responses
  String? get responseId => _rawResponse['id'] as String?;

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
