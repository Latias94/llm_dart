// OpenAI chat capability implementation (prompt-first).

import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../client/openai_client.dart';
import '../config/openai_config.dart';

/// OpenAI Chat capability implementation
///
/// This module handles all chat-related functionality for OpenAI providers,
/// including streaming, tool calling, and reasoning model support.
class OpenAIChat implements ChatCapability {
  final OpenAIClient client;
  final OpenAIConfig config;

  OpenAIChat(this.client, this.config);

  String get chatEndpoint => 'chat/completions';

  @override
  Future<ChatResponse> chat(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async {
    final requestBody = _buildRequestBody(
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
    final requestBody = _buildRequestBody(
      messages,
      tools,
      true,
      options: options,
    );

    // Per-stream state used for reasoning and tool call tracking.
    final state = _OpenAIStreamState();

    try {
      final stream = client.postStreamRaw(
        chatEndpoint,
        requestBody,
        cancelToken: CancellationUtils.toDioCancelToken(cancelToken),
      );

      await for (final chunk in stream) {
        try {
          final events = _parseStreamEvents(chunk, state);
          for (final event in events) {
            yield event;
          }
        } catch (e) {
          client.logger.warning('Failed to parse stream chunk: $e');
        }
      }
    } catch (e) {
      if (e is LLMError) {
        rethrow;
      } else {
        throw GenericError('Stream error: $e');
      }
    }
  }

  /// Build request body for chat API
  Map<String, dynamic> _buildRequestBody(
    List<ModelMessage> promptMessages,
    List<Tool>? tools,
    bool stream, {
    LanguageModelCallOptions? options,
  }) {
    final isReasoningModel =
        ReasoningUtils.isOpenAIReasoningModel(config.model);

    var apiMessages = client.buildApiMessagesFromPrompt(promptMessages);

    // Handle system prompt: prefer explicit system messages over config
    final hasSystemMessage =
        promptMessages.any((m) => m.role == ChatRole.system);

    // Only add config system prompt if no explicit system message exists
    if (!hasSystemMessage && config.systemPrompt != null) {
      apiMessages.insert(0, {'role': 'system', 'content': config.systemPrompt});
    }

    final body = <String, dynamic>{
      'model': config.model,
      'messages': apiMessages,
      'stream': stream,
    };

    final effectiveMaxTokens = options?.maxTokens ?? config.maxTokens;

    // Map token limits according to reasoning model support.
    // Reasoning models use max_completion_tokens, non-reasoning use max_tokens.
    if (effectiveMaxTokens != null) {
      if (isReasoningModel) {
        body['max_completion_tokens'] = effectiveMaxTokens;
      } else {
        body['max_tokens'] = effectiveMaxTokens;
      }
    }

    // Sampling parameters:
    // - For reasoning models (GPT‑5 family, o1/o3/o4, etc.), OpenAI does not
    //   support temperature/top_p and related penalties on the Chat endpoint.
    //   We follow the AI SDK behavior and omit those fields so users do not
    //   get invalid_request errors.
    // - For standard chat models (gpt-4o, gpt-4.1, gpt-5-chat, etc.), we
    //   forward the configured values as-is.
    if (!isReasoningModel) {
      final effectiveTemperature = options?.temperature ?? config.temperature;
      final effectiveTopP = options?.topP ?? config.topP;

      if (effectiveTemperature != null) {
        body['temperature'] = effectiveTemperature;
      }
      if (effectiveTopP != null) {
        body['top_p'] = effectiveTopP;
      }
    }

    final effectiveTopK = options?.topK ?? config.topK;
    if (effectiveTopK != null) {
      body['top_k'] = effectiveTopK;
    }

    // Forward reasoning effort directly; OpenAI ignores it for non-reasoning
    // chat models, but accepts it for reasoning-capable ones.
    if (config.reasoningEffort != null) {
      body['reasoning_effort'] = config.reasoningEffort!.value;
    }

    // Add tools if provided
    final effectiveTools = options?.tools ?? tools ?? config.tools;
    if (effectiveTools != null && effectiveTools.isNotEmpty) {
      body['tools'] = effectiveTools.map((t) => t.toJson()).toList();

      final effectiveToolChoice = options?.toolChoice ?? config.toolChoice;
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

    // Add common parameters (per-call options override config).
    final effectiveStopSequences =
        options?.stopSequences ?? config.stopSequences;
    if (effectiveStopSequences != null && effectiveStopSequences.isNotEmpty) {
      body['stop'] = effectiveStopSequences;
    }

    final effectiveUser = options?.user ?? config.user;
    if (effectiveUser != null) {
      body['user'] = effectiveUser;
    }

    final effectiveServiceTier = options?.serviceTier ?? config.serviceTier;
    if (effectiveServiceTier != null) {
      body['service_tier'] = effectiveServiceTier.value;
    }

    // Add OpenAI-specific extension parameters
    final frequencyPenalty =
        config.getExtension<double>(LLMConfigKeys.frequencyPenalty);
    if (frequencyPenalty != null && !isReasoningModel) {
      body['frequency_penalty'] = frequencyPenalty;
    }

    final presencePenalty =
        config.getExtension<double>(LLMConfigKeys.presencePenalty);
    if (presencePenalty != null && !isReasoningModel) {
      body['presence_penalty'] = presencePenalty;
    }

    final logitBias =
        config.getExtension<Map<String, double>>(LLMConfigKeys.logitBias);
    if (logitBias != null && logitBias.isNotEmpty && !isReasoningModel) {
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
    if (logprobs != null && !isReasoningModel) {
      body['logprobs'] = logprobs;
    }

    final topLogprobs = config.getExtension<int>(LLMConfigKeys.topLogprobs);
    if (topLogprobs != null && !isReasoningModel) {
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
  List<ChatStreamEvent> _parseStreamEvents(
    String chunk,
    _OpenAIStreamState state,
  ) {
    final events = <ChatStreamEvent>[];

    // Parse SSE chunk - now returns a list of JSON objects
    final jsonList = client.parseSSEChunk(chunk);
    if (jsonList.isEmpty) return events;

    // Process each JSON object in the chunk
    for (final json in jsonList) {
      // Use existing stream parsing logic with per-stream state tracking.
      final parsedEvents = _parseStreamEventWithReasoning(json, state);

      events.addAll(parsedEvents);
    }

    return events;
  }

  /// Parse stream events with reasoning support
  List<ChatStreamEvent> _parseStreamEventWithReasoning(
    Map<String, dynamic> json,
    _OpenAIStreamState state,
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
      state.thinkingBuffer.write(reasoningContent);
      state.hasReasoningContent = true; // Update state
      events.add(ThinkingDeltaEvent(reasoningContent));
      return events;
    }

    // Handle regular content
    final content = delta['content'] as String?;
    if (content != null && content.isNotEmpty) {
      // Update last chunk for reasoning detection
      state.lastChunk = content;

      // Check reasoning status using utils
      final reasoningResult = ReasoningUtils.checkReasoningStatus(
        delta: delta,
        hasReasoningContent: state.hasReasoningContent,
        lastChunk: state.lastChunk,
      );

      // Update state based on reasoning detection
      state.hasReasoningContent = reasoningResult.hasReasoningContent;

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
            state.thinkingBuffer.write(thinkingText);
            events.add(ThinkingDeltaEvent(thinkingText));
          }
        }
        // Don't emit content that contains thinking tags
        return events;
      }

      events.add(TextDeltaEvent(content));
    }

    // Handle tool calls.
    //
    // OpenAI streams tool_calls in multiple chunks:
    // - The first chunk typically has index + id + function.name + initial arguments
    // - Subsequent chunks usually have only index + function.arguments deltas
    //
    // We cache id by index and reuse it for each chunk so that every
    // ToolCallDeltaEvent carries a stable toolCall.id that callers can rely on.
    final toolCalls = delta['tool_calls'] as List?;
    if (toolCalls != null && toolCalls.isNotEmpty) {
      final toolCallMap = toolCalls.first as Map<String, dynamic>;
      final toolCall = state.toolCallStreamState.processDelta(toolCallMap);
      if (toolCall != null) {
        events.add(ToolCallDeltaEvent(toolCall));
      }
    }

    // Check for finish reason
    final finishReason = choice['finish_reason'] as String?;
    if (finishReason != null) {
      final usage = json['usage'] as Map<String, dynamic>?;
      final thinkingContent = state.thinkingBuffer.isNotEmpty
          ? state.thinkingBuffer.toString()
          : null;

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
    }

    return events;
  }
}

/// Per-stream state used when parsing OpenAI chat streaming responses.
class _OpenAIStreamState {
  bool hasReasoningContent = false;
  String lastChunk = '';
  final StringBuffer thinkingBuffer = StringBuffer();

  /// Track tool call IDs by index for streaming tool calls.
  /// We delegate index → id mapping and delta parsing to [ToolCallStreamState].
  final ToolCallStreamState toolCallStreamState = ToolCallStreamState();
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
  CallMetadata? get callMetadata {
    final data = metadata;
    if (data == null) return null;
    return CallMetadata.fromJson(data);
  }

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
