// OpenAI-compatible chat capability built on the legacy ChatMessage
// ChatCapability. This module converts messages to ModelMessage-based
// prompts internally but keeps ChatMessage at the public surface.
// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../client/openai_compatible_client.dart';
import '../config/openai_compatible_config.dart';
import '../provider_profiles/openai_compatible_provider_profiles.dart';

/// OpenAI-compatible Chat capability implementation
///
/// This module implements ChatCapability for any provider that exposes
/// an OpenAI-style chat/completions API.
class OpenAICompatibleChat implements ChatCapability, PromptChatCapability {
  final OpenAICompatibleClient client;
  final OpenAICompatibleConfig config;

  bool _hasReasoningContent = false;
  String _lastChunk = '';
  final StringBuffer _thinkingBuffer = StringBuffer();
  // Track tool call streaming state for OpenAI-compatible providers.
  // These providers typically follow the same pattern as OpenAI: the first
  // chunk carries id + index, while subsequent chunks only contain index and
  // incremental arguments. We delegate index → id mapping to
  // [ToolCallStreamState].
  final ToolCallStreamState _toolCallStreamState = ToolCallStreamState();

  OpenAICompatibleChat(this.client, this.config);

  String get chatEndpoint => 'chat/completions';

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async {
    final promptMessages =
        messages.map((message) => message.toPromptMessage()).toList();
    return chatPrompt(
      promptMessages,
      tools: tools,
      options: options,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async* {
    final promptMessages =
        messages.map((message) => message.toPromptMessage()).toList();
    yield* chatPromptStream(
      promptMessages,
      tools: tools,
      options: options,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    return chatWithTools(
      messages,
      null,
      options: options,
      cancelToken: cancelToken,
    );
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

    return ReasoningUtils.filterThinkingContent(text);
  }

  @override
  Future<ChatResponse> chatPrompt(
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
  Stream<ChatStreamEvent> chatPromptStream(
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

    _resetStreamState();

    try {
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
    } catch (e) {
      if (e is LLMError) rethrow;
      throw GenericError('Stream error: $e');
    }
  }

  Map<String, dynamic> _buildRequestBody(
    List<ModelMessage> promptMessages,
    List<Tool>? tools,
    bool stream, {
    LanguageModelCallOptions? options,
  }) {
    final apiMessages = client.buildApiMessagesFromPrompt(promptMessages);

    final hasSystemMessage =
        promptMessages.any((m) => m.role == ChatRole.system);
    if (!hasSystemMessage && config.systemPrompt != null) {
      apiMessages.insert(0, {'role': 'system', 'content': config.systemPrompt});
    }

    final body = <String, dynamic>{
      'model': config.model,
      'messages': apiMessages,
      'stream': stream,
    };

    final effectiveMaxTokens = options?.maxTokens ?? config.maxTokens;
    final effectiveTemperature = options?.temperature ?? config.temperature;
    final effectiveTopP = options?.topP ?? config.topP;
    final effectiveTopK = options?.topK ?? config.topK;

    // Reasoning-specific parameter restrictions are no longer enforced here.
    // We always forward the configured parameters and let the underlying
    // OpenAI-compatible provider decide how to handle them.
    if (effectiveMaxTokens != null) {
      body['max_tokens'] = effectiveMaxTokens;
    }
    if (effectiveTemperature != null) {
      body['temperature'] = effectiveTemperature;
    }
    if (effectiveTopP != null) {
      body['top_p'] = effectiveTopP;
    }
    if (effectiveTopK != null) {
      body['top_k'] = effectiveTopK;
    }

    if (config.reasoningEffort != null) {
      body['reasoning_effort'] = config.reasoningEffort!.value;
    }

    final effectiveTools = options?.tools ?? tools ?? config.tools;
    if (effectiveTools != null && effectiveTools.isNotEmpty) {
      body['tools'] = effectiveTools.map((t) => t.toJson()).toList();

      final effectiveToolChoice = options?.toolChoice ?? config.toolChoice;
      if (effectiveToolChoice != null) {
        body['tool_choice'] = effectiveToolChoice.toJson();
      }
    }

    if (config.jsonSchema != null) {
      final schema = config.jsonSchema!;
      final responseFormat = <String, dynamic>{
        'type': 'json_schema',
        'json_schema': schema.toJson(),
      };

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

    // Apply provider-specific request body transformers (e.g. Google Gemini).
    final transformedBody = _applyProviderRequestTransformers(body);

    final extraBody = transformedBody['extra_body'] as Map<String, dynamic>?;
    if (extraBody != null) {
      transformedBody.addAll(extraBody);
      transformedBody.remove('extra_body');
    }

    return transformedBody;
  }

  /// Apply provider-specific request body transformations when configured.
  ///
  /// This uses [OpenAICompatibleProviderConfig.requestBodyTransformer] from
  /// the provider profiles to adapt the OpenAI-compatible request body to
  /// provider-specific formats (e.g. Google Gemini thinking config).
  Map<String, dynamic> _applyProviderRequestTransformers(
    Map<String, dynamic> body,
  ) {
    final originalConfig = config.originalConfig;
    if (originalConfig == null) {
      return body;
    }

    final providerConfig =
        OpenAICompatibleProviderProfiles.getConfig(config.providerId);
    final transformer = providerConfig?.requestBodyTransformer;

    if (providerConfig == null || transformer == null) {
      return body;
    }

    try {
      return transformer.transform(
        body,
        originalConfig,
        providerConfig,
      );
    } catch (_) {
      // On any error, fall back to the unmodified body to avoid breaking calls.
      return body;
    }
  }

  ChatResponse _parseResponse(Map<String, dynamic> responseData) {
    String? thinkingContent;

    final choices = responseData['choices'] as List?;
    if (choices != null && choices.isNotEmpty) {
      final choice = choices.first as Map<String, dynamic>;
      final message = choice['message'] as Map<String, dynamic>?;

      if (message != null) {
        thinkingContent = message['reasoning'] as String? ??
            message['thinking'] as String? ??
            message['reasoning_content'] as String?;

        final content = message['content'] as String?;
        if (content != null && ReasoningUtils.containsThinkingTags(content)) {
          final thinkMatch = RegExp(
            r'<think>(.*?)</think>',
            dotAll: true,
          ).firstMatch(content);
          if (thinkMatch != null) {
            thinkingContent = thinkMatch.group(1)?.trim();
            message['content'] = ReasoningUtils.filterThinkingContent(content);
          }
        }
      }
    }

    final warnings = <CallWarning>[];
    final metadata = _buildMetadataForCall();

    return _OpenAICompatibleChatResponse(
      responseData,
      thinkingContent,
      warnings,
      metadata,
    );
  }

  List<ChatStreamEvent> _parseStreamEvents(String chunk) {
    final events = <ChatStreamEvent>[];
    final jsonList = client.parseSSEChunk(chunk);
    if (jsonList.isEmpty) return events;

    for (final json in jsonList) {
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

  void _resetStreamState() {
    _hasReasoningContent = false;
    _lastChunk = '';
    _thinkingBuffer.clear();
    _toolCallStreamState.reset();
  }

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

    final reasoningContent = ReasoningUtils.extractReasoningContent(delta);
    if (reasoningContent != null && reasoningContent.isNotEmpty) {
      thinkingBuffer.write(reasoningContent);
      _hasReasoningContent = true;
      events.add(ThinkingDeltaEvent(reasoningContent));
      return events;
    }

    final content = delta['content'] as String?;
    if (content != null && content.isNotEmpty) {
      _lastChunk = content;

      final reasoningResult = ReasoningUtils.checkReasoningStatus(
        delta: delta,
        hasReasoningContent: _hasReasoningContent,
        lastChunk: lastChunk,
      );

      _hasReasoningContent = reasoningResult.hasReasoningContent;

      if (ReasoningUtils.containsThinkingTags(content)) {
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
        return events;
      }

      events.add(TextDeltaEvent(content));
    }

    final toolCalls = delta['tool_calls'] as List?;
    if (toolCalls != null && toolCalls.isNotEmpty) {
      final toolCallMap = toolCalls.first as Map<String, dynamic>;
      final toolCall = _toolCallStreamState.processDelta(toolCallMap);
      if (toolCall != null) {
        events.add(ToolCallDeltaEvent(toolCall));
      }
    }

    final finishReason = choice['finish_reason'] as String?;
    if (finishReason != null) {
      final usage = json['usage'] as Map<String, dynamic>?;
      final thinkingContent =
          thinkingBuffer.isNotEmpty ? thinkingBuffer.toString() : null;
      final metadata = _buildMetadataForCall();

      final response = _OpenAICompatibleChatResponse(
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
        metadata,
      );

      events.add(CompletionEvent(response));
      _resetStreamState();
    }

    return events;
  }

  /// Build provider-agnostic metadata for this call.
  Map<String, dynamic>? _buildMetadataForCall() {
    return {
      // Align with core CallMetadata expectations:
      // use `provider` as the logical provider identifier.
      'provider': config.providerId,
      'model': config.model,
    };
  }
}

class _OpenAICompatibleChatResponse implements ChatResponse {
  final Map<String, dynamic> _rawResponse;
  final String? _thinkingContent;
  final List<CallWarning> _warnings;
  final Map<String, dynamic>? _metadata;

  _OpenAICompatibleChatResponse(
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
