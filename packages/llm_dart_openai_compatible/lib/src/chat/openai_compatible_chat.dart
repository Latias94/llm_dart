import 'dart:async';

import 'package:dio/dio.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

import '../client/openai_compatible_client.dart';
import '../config/openai_compatible_config.dart';

/// OpenAI-compatible Chat capability implementation
///
/// This module implements ChatCapability for any provider that exposes
/// an OpenAI-style chat/completions API.
class OpenAICompatibleChat implements ChatCapability {
  final OpenAICompatibleClient client;
  final OpenAICompatibleConfig config;

  bool _hasReasoningContent = false;
  String _lastChunk = '';
  final StringBuffer _thinkingBuffer = StringBuffer();

  OpenAICompatibleChat(this.client, this.config);

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

    _resetStreamState();

    try {
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
    } catch (e) {
      if (e is LLMError) rethrow;
      throw GenericError('Stream error: $e');
    }
  }

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  }) {
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

    return ReasoningUtils.filterThinkingContent(text);
  }

  Map<String, dynamic> _buildRequestBody(
    List<ChatMessage> messages,
    List<Tool>? tools,
    bool stream,
  ) {
    final apiMessages = client.buildApiMessages(messages);

    final hasSystemMessage = messages.any((m) => m.role == ChatRole.system);
    if (!hasSystemMessage && config.systemPrompt != null) {
      apiMessages.insert(0, {'role': 'system', 'content': config.systemPrompt});
    }

    final body = <String, dynamic>{
      'model': config.model,
      'messages': apiMessages,
      'stream': stream,
    };

    body.addAll(
      ReasoningUtils.getMaxTokensParams(
        model: config.model,
        maxTokens: config.maxTokens,
      ),
    );

    if (config.temperature != null &&
        !ReasoningUtils.shouldDisableTemperature(config.model)) {
      body['temperature'] = config.temperature;
    }

    if (config.topP != null &&
        !ReasoningUtils.shouldDisableTopP(config.model)) {
      body['top_p'] = config.topP;
    }
    if (config.topK != null) body['top_k'] = config.topK;

    body.addAll(
      ReasoningUtils.getReasoningEffortParams(
        providerId: config.providerId,
        model: config.model,
        reasoningEffort: config.reasoningEffort,
        maxTokens: config.maxTokens,
      ),
    );

    final effectiveTools = tools ?? config.tools;
    if (effectiveTools != null && effectiveTools.isNotEmpty) {
      body['tools'] = effectiveTools.map((t) => t.toJson()).toList();

      final effectiveToolChoice = config.toolChoice;
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

    if (config.stopSequences != null && config.stopSequences!.isNotEmpty) {
      body['stop'] = config.stopSequences;
    }

    if (config.user != null) {
      body['user'] = config.user;
    }

    if (config.serviceTier != null) {
      body['service_tier'] = config.serviceTier!.value;
    }

    final extraBody = body['extra_body'] as Map<String, dynamic>?;
    if (extraBody != null) {
      body.addAll(extraBody);
      body.remove('extra_body');
    }

    return body;
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

    final warnings = _buildWarningsForCall();
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
      final toolCall = toolCalls.first as Map<String, dynamic>;
      if (toolCall.containsKey('id') && toolCall.containsKey('function')) {
        try {
          events.add(ToolCallDeltaEvent(ToolCall.fromJson(toolCall)));
        } catch (_) {}
      }
    }

    final finishReason = choice['finish_reason'] as String?;
    if (finishReason != null) {
      final usage = json['usage'] as Map<String, dynamic>?;
      final thinkingContent =
          thinkingBuffer.isNotEmpty ? thinkingBuffer.toString() : null;

      final warnings = _buildWarningsForCall();
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
        warnings,
        metadata,
      );

      events.add(CompletionEvent(response));
      _resetStreamState();
    }

    return events;
  }

  /// Build non-fatal warnings for this call based on the current configuration.
  ///
  /// Today this focuses on reasoning models where certain parameters
  /// (temperature, top_p) are accepted but have no effect.
  List<CallWarning> _buildWarningsForCall() {
    final warnings = <CallWarning>[];

    if (config.temperature != null &&
        ReasoningUtils.shouldDisableTemperature(config.model)) {
      warnings.add(
        CallWarning(
          code: 'PARAMETER_NO_EFFECT',
          message:
              'temperature has no effect for reasoning model ${config.model}',
          details: {
            'parameter': 'temperature',
            'model': config.model,
            'providerId': config.providerId,
          },
        ),
      );
    }

    if (config.topP != null && ReasoningUtils.shouldDisableTopP(config.model)) {
      warnings.add(
        CallWarning(
          code: 'PARAMETER_NO_EFFECT',
          message: 'top_p has no effect for reasoning model ${config.model}',
          details: {
            'parameter': 'top_p',
            'model': config.model,
            'providerId': config.providerId,
          },
        ),
      );
    }

    return warnings;
  }

  /// Build provider-agnostic metadata for this call.
  Map<String, dynamic>? _buildMetadataForCall() {
    return {
      'providerId': config.providerId,
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
