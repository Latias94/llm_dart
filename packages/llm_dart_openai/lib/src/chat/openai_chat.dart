import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';

import '../client/openai_client.dart';
import '../config/openai_config.dart';

/// OpenAI Chat capability implementation
///
/// This module handles all chat-related functionality for OpenAI providers,
/// including streaming, tool calling, and reasoning model support.
class OpenAIChat implements ChatCapability {
  final OpenAIClient client;
  final OpenAIConfig config;

  // State tracking for stream processing
  bool _hasReasoningContent = false;
  String _lastChunk = '';
  final StringBuffer _thinkingBuffer = StringBuffer();

  OpenAIChat(this.client, this.config);

  String get chatEndpoint => 'chat/completions';

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
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
    CancelToken? cancelToken,
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

    // Filter out thinking content for reasoning models
    return ReasoningUtils.filterThinkingContent(text);
  }

  /// Build request body for chat API
  Map<String, dynamic> _buildRequestBody(
    List<ChatMessage> messages,
    List<Tool>? tools,
    bool stream,
  ) {
    final promptMessages =
        messages.map((message) => message.toPromptMessage()).toList();

    var apiMessages = client.buildApiMessagesFromPrompt(promptMessages);

    // Handle system prompt: prefer explicit system messages over config
    final hasSystemMessage = messages.any((m) => m.role == ChatRole.system);

    // Only add config system prompt if no explicit system message exists
    if (!hasSystemMessage && config.systemPrompt != null) {
      apiMessages.insert(0, {'role': 'system', 'content': config.systemPrompt});
    }

    final body = <String, dynamic>{
      'model': config.model,
      'messages': apiMessages,
      'stream': stream,
    };

    // Reasoning-specific parameter restrictions are no longer enforced here.
    // We always forward the configured parameters and let the provider
    // surface any errors or warnings.
    if (config.maxTokens != null) {
      body['max_tokens'] = config.maxTokens;
    }
    if (config.temperature != null) {
      body['temperature'] = config.temperature;
    }
    if (config.topP != null) {
      body['top_p'] = config.topP;
    }
    if (config.topK != null) body['top_k'] = config.topK;

    // Forward reasoning effort directly when configured, without
    // provider-specific shaping.
    if (config.reasoningEffort != null) {
      body['reasoning_effort'] = config.reasoningEffort!.value;
    }

    // Add tools if provided
    final effectiveTools = tools ?? config.tools;
    if (effectiveTools != null && effectiveTools.isNotEmpty) {
      body['tools'] = effectiveTools.map((t) => t.toJson()).toList();

      final effectiveToolChoice = config.toolChoice;
      if (effectiveToolChoice != null) {
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
    final frequencyPenalty =
        config.getExtension<double>(LLMConfigKeys.frequencyPenalty);
    if (frequencyPenalty != null) {
      body['frequency_penalty'] = frequencyPenalty;
    }

    final presencePenalty =
        config.getExtension<double>(LLMConfigKeys.presencePenalty);
    if (presencePenalty != null) {
      body['presence_penalty'] = presencePenalty;
    }

    final logitBias =
        config.getExtension<Map<String, double>>(LLMConfigKeys.logitBias);
    if (logitBias != null && logitBias.isNotEmpty) {
      body['logit_bias'] = logitBias;
    }

    final seed = config.getExtension<int>(LLMConfigKeys.seed);
    if (seed != null) {
      body['seed'] = seed;
    }

    final parallelToolCalls =
        config.getExtension<bool>(LLMConfigKeys.parallelToolCalls);
    if (parallelToolCalls != null) {
      body['parallel_tool_calls'] = parallelToolCalls;
    }

    final logprobs = config.getExtension<bool>(LLMConfigKeys.logprobs);
    if (logprobs != null) {
      body['logprobs'] = logprobs;
    }

    final topLogprobs = config.getExtension<int>(LLMConfigKeys.topLogprobs);
    if (topLogprobs != null) {
      body['top_logprobs'] = topLogprobs;
    }

    final verbosity = config.getExtension<String>(LLMConfigKeys.verbosity);
    if (verbosity != null) {
      body['verbosity'] = verbosity;
    }

    // Handle extra_body parameters (for OpenAI-compatible interfaces)
    // This merges provider-specific parameters from extra_body into the main request body
    final extraBody = body['extra_body'] as Map<String, dynamic>?;
    if (extraBody != null) {
      // Merge extra_body contents into the main body
      body.addAll(extraBody);
      // Remove the extra_body field itself as it should not be sent to the API
      body.remove('extra_body');
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
        if (thinkingContent == null && config.model.contains('deepseek-r1')) {
          final reasoning = responseData['reasoning'] as String?;
          if (reasoning != null && reasoning.isNotEmpty) {
            thinkingContent = reasoning;
          }
        }
      }
    }

    return OpenAIChatResponse(
      responseData,
      thinkingContent,
      const [],
      {
        'provider': client.providerId,
        'model': config.model,
        'apiType': 'chat',
        'hasThinking': thinkingContent != null && thinkingContent.isNotEmpty,
      },
    );
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
        _hasReasoningContent,
        _lastChunk,
        _thinkingBuffer,
      );

      events.addAll(parsedEvents);
    }

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
    final choices = json['choices'] as List?;
    if (choices == null || choices.isEmpty) return events;

    final choice = choices.first as Map<String, dynamic>;
    final delta = choice['delta'] as Map<String, dynamic>?;
    if (delta == null) return events;

    // Handle reasoning content using reasoning utils
    final reasoningContent = ReasoningUtils.extractReasoningContent(delta);

    if (reasoningContent != null && reasoningContent.isNotEmpty) {
      thinkingBuffer.write(reasoningContent);
      _hasReasoningContent = true; // Update state
      events.add(ThinkingDeltaEvent(reasoningContent));
      return events;
    }

    // Handle regular content
    final content = delta['content'] as String?;
    if (content != null && content.isNotEmpty) {
      // Update last chunk for reasoning detection
      _lastChunk = content;

      // Check reasoning status using utils
      final reasoningResult = ReasoningUtils.checkReasoningStatus(
        delta: delta,
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

    // Handle tool calls
    final toolCalls = delta['tool_calls'] as List?;
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
    final finishReason = choice['finish_reason'] as String?;
    if (finishReason != null) {
      final usage = json['usage'] as Map<String, dynamic>?;
      final thinkingContent =
          thinkingBuffer.isNotEmpty ? thinkingBuffer.toString() : null;

      final response = OpenAIChatResponse(
        {
          'choices': [
            {
              'message': {'content': '', 'role': 'assistant'},
            },
          ],
          if (usage != null) 'usage': usage,
        },
        thinkingContent,
        const [],
        {
          'provider': client.providerId,
          'model': config.model,
          'apiType': 'chat',
          'streaming': true,
          'hasThinking': thinkingContent != null && thinkingContent.isNotEmpty,
        },
      );

      events.add(CompletionEvent(response));

      // Reset state after completion
      _resetStreamState();
    }

    return events;
  }
}

/// OpenAI chat response implementation
class OpenAIChatResponse implements ChatResponse {
  final Map<String, dynamic> _rawResponse;
  final String? _thinkingContent;

  final List<CallWarning> _warnings;
  final Map<String, dynamic>? _metadata;

  OpenAIChatResponse(
    this._rawResponse, [
    this._thinkingContent,
    List<CallWarning> warnings = const [],
    Map<String, dynamic>? metadata,
  ])  : _warnings = warnings,
        _metadata = metadata;

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
  List<CallWarning> get warnings => _warnings;

  @override
  Map<String, dynamic>? get metadata => _metadata;

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
