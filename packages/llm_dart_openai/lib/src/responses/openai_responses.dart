import 'dart:async';

import 'package:dio/dio.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

import '../client/openai_client.dart';
import '../config/openai_config.dart';
import 'openai_responses_capability.dart';

/// OpenAI Responses API capability implementation for the subpackage.
///
/// This mirrors the main package implementation and supports:
/// - Chat with tools
/// - Streaming
/// - Background responses
/// - Stateful conversation management
/// - Input items listing
class OpenAIResponses implements ChatCapability, OpenAIResponsesCapability {
  final OpenAIClient client;
  final OpenAIConfig config;

  bool _hasReasoningContent = false;
  String _lastChunk = '';
  final StringBuffer _thinkingBuffer = StringBuffer();

  OpenAIResponses(this.client, this.config);

  String get responsesEndpoint => 'responses';

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    final requestBody = _buildRequestBody(messages, tools, false, false);
    final responseData = await client.postJson(
      responsesEndpoint,
      requestBody,
      cancelToken: cancelToken,
    );
    return _parseResponse(responseData);
  }

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
    CancelToken? cancelToken,
  }) async* {
    final effectiveTools = tools ?? config.tools;
    final requestBody =
        _buildRequestBody(messages, effectiveTools, true, false);

    _resetStreamState();

    try {
      final stream = client.postStreamRaw(
        responsesEndpoint,
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

  @override
  Future<ChatResponse> getResponse(
    String responseId, {
    List<String>? include,
    int? startingAfter,
    bool stream = false,
  }) async {
    var endpoint = '$responsesEndpoint/$responseId';

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

    if (queryParams.isNotEmpty) {
      final queryString = queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      endpoint = '$endpoint?$queryString';
    }

    final responseData = await client.getJson(endpoint);
    return _parseResponse(responseData);
  }

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
      throw GenericError('Failed to delete response: $e');
    }
  }

  @override
  Future<ChatResponse> cancelResponse(String responseId) async {
    final endpoint = '$responsesEndpoint/$responseId/cancel';
    final responseData = await client.postJson(endpoint, {});
    return _parseResponse(responseData);
  }

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

    final queryParams = <String, String>{
      'limit': limit.toString(),
      'order': order,
    };

    if (after != null) queryParams['after'] = after;
    if (before != null) queryParams['before'] = before;
    if (include != null && include.isNotEmpty) {
      queryParams['include'] = include.join(',');
    }

    final queryString = queryParams.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    endpoint = '$endpoint?$queryString';

    final responseData = await client.getJson(endpoint);
    return ResponseInputItemsList.fromJson(responseData);
  }

  @override
  Future<ChatResponse> continueConversation(
    String previousResponseId,
    List<ChatMessage> newMessages, {
    List<Tool>? tools,
    bool background = false,
  }) async {
    final updatedConfig =
        config.copyWith(previousResponseId: previousResponseId);
    final tempResponses = OpenAIResponses(client, updatedConfig);

    final requestBody =
        tempResponses._buildRequestBody(newMessages, tools, false, background);
    final responseData = await client.postJson(responsesEndpoint, requestBody);
    return _parseResponse(responseData);
  }

  @override
  Future<ChatResponse> forkConversation(
    String fromResponseId,
    List<ChatMessage> newMessages, {
    List<Tool>? tools,
    bool background = false,
  }) {
    return continueConversation(
      fromResponseId,
      newMessages,
      tools: tools,
      background: background,
    );
  }

  Map<String, dynamic> _buildRequestBody(
    List<ChatMessage> messages,
    List<Tool>? tools,
    bool stream,
    bool background,
  ) {
    final apiMessages = client.buildApiMessages(messages);

    final hasSystemMessage = messages.any((m) => m.role == ChatRole.system);

    if (!hasSystemMessage && config.systemPrompt != null) {
      apiMessages.insert(0, {'role': 'system', 'content': config.systemPrompt});
    }

    final body = <String, dynamic>{
      'model': config.model,
      'input': apiMessages,
      'stream': stream,
      'background': background,
    };

    if (config.previousResponseId != null) {
      body['previous_response_id'] = config.previousResponseId;
    }

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

    if (config.reasoningEffort != null) {
      body['reasoning'] = {
        'effort': config.reasoningEffort!.value,
      };
    }

    final allTools = <Map<String, dynamic>>[];

    final effectiveTools = tools ?? config.tools;
    if (effectiveTools != null && effectiveTools.isNotEmpty) {
      allTools
          .addAll(effectiveTools.map((t) => _convertToolToResponsesFormat(t)));
    }

    if (config.builtInTools != null && config.builtInTools!.isNotEmpty) {
      allTools.addAll(config.builtInTools!.map((t) => t.toJson()));
    }

    if (allTools.isNotEmpty) {
      body['tools'] = allTools;

      final effectiveToolChoice = config.toolChoice;
      if (effectiveToolChoice != null &&
          effectiveTools != null &&
          effectiveTools.isNotEmpty) {
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

    final output = responseData['output'] as List?;
    if (output != null) {
      for (final item in output) {
        if (item is Map<String, dynamic> && item['type'] == 'message') {
          final content = item['content'] as List?;
          if (content != null) {
            for (final contentItem in content) {
              if (contentItem is Map<String, dynamic> &&
                  contentItem['type'] == 'thinking') {
                thinkingContent = contentItem['thinking'] as String?;
              }
            }
          }
        }
      }
    }

    return OpenAIResponsesResponse(responseData, thinkingContent);
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

    final eventType = json['type'] as String?;

    if (eventType == 'response.output_text.delta') {
      final delta = json['delta'] as String?;
      if (delta != null && delta.isNotEmpty) {
        _lastChunk = delta;

        if (ReasoningUtils.containsThinkingTags(delta)) {
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
          return events;
        }

        events.add(TextDeltaEvent(delta));
        return events;
      }
    }

    if (eventType == 'response.completed') {
      final response = json['response'] as Map<String, dynamic>?;
      if (response != null) {
        final thinkingContent =
            thinkingBuffer.isNotEmpty ? thinkingBuffer.toString() : null;

        final completionResponse =
            OpenAIResponsesResponse(response, thinkingContent);
        events.add(CompletionEvent(completionResponse));

        _resetStreamState();
        return events;
      }
    }

    final reasoningContent = ReasoningUtils.extractReasoningContent(json);
    if (reasoningContent != null && reasoningContent.isNotEmpty) {
      thinkingBuffer.write(reasoningContent);
      _hasReasoningContent = true;
      events.add(ThinkingDeltaEvent(reasoningContent));
      return events;
    }

    final content = json['output_text_delta'] as String?;
    if (content != null && content.isNotEmpty) {
      _lastChunk = content;

      final reasoningResult = ReasoningUtils.checkReasoningStatus(
        delta: {'content': content},
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

    final toolCalls = json['tool_calls'] as List?;
    if (toolCalls != null && toolCalls.isNotEmpty) {
      final toolCall = toolCalls.first as Map<String, dynamic>;
      if (toolCall.containsKey('id') && toolCall.containsKey('function')) {
        try {
          events.add(ToolCallDeltaEvent(ToolCall.fromJson(toolCall)));
        } catch (e) {
          client.logger.warning('Failed to parse tool call: $e');
        }
      }
    }

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

      _resetStreamState();
    }

    return events;
  }

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
    final output = _rawResponse['output'] as List?;
    if (output != null) {
      for (final item in output) {
        if (item is Map<String, dynamic> && item['type'] == 'message') {
          final content = item['content'] as List?;
          if (content != null) {
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

    return _rawResponse['output_text'] as String?;
  }

  @override
  List<ToolCall>? get toolCalls {
    final output = _rawResponse['output'] as List?;
    if (output != null) {
      final toolCalls = <ToolCall>[];

      for (final item in output) {
        if (item is Map<String, dynamic> && item['type'] == 'function_call') {
          try {
            final toolCall = ToolCall(
              id: item['call_id'] as String? ?? item['id'] as String? ?? '',
              callType: 'function',
              function: FunctionCall(
                name: item['name'] as String? ?? '',
                arguments: item['arguments'] as String? ?? '{}',
              ),
            );
            toolCalls.add(toolCall);
          } catch (_) {}
        }
      }

      if (toolCalls.isNotEmpty) return toolCalls;
    }

    final toolCalls = _rawResponse['tool_calls'] as List?;
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
  List<CallWarning> get warnings => const [];

  @override
  Map<String, dynamic>? get metadata {
    final id = _rawResponse['id'] as String?;
    final model = _rawResponse['model'] as String?;
    final status = _rawResponse['status'] as String?;

    // Count occurrences of function_call and built-in tools in output, if present.
    final output = _rawResponse['output'] as List?;
    int functionCallCount = 0;

    if (output != null) {
      for (final item in output) {
        if (item is Map<String, dynamic>) {
          final type = item['type'] as String?;
          if (type == 'function_call') {
            functionCallCount++;
          }
        }
      }
    }

    return {
      'provider': 'openai',
      if (id != null) 'id': id,
      if (model != null) 'model': model,
      if (status != null) 'status': status,
      'functionCallCount': functionCallCount,
    };
  }

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
