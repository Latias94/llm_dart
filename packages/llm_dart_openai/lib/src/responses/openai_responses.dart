// OpenAI Responses API implementation (prompt-first).

import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../client/openai_client.dart';
import '../config/openai_config.dart';
import '../tools/openai_builtin_tools.dart';
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
  // Track tool call streaming state for the Responses API.
  // Similar to Chat, the Responses API may only send the id in the first
  // chunk and then reference the same tool call via index in subsequent
  // chunks. We delegate index → id mapping to [ToolCallStreamState].
  final ToolCallStreamState _toolCallStreamState = ToolCallStreamState();

  OpenAIResponses(this.client, this.config);

  String get responsesEndpoint => 'responses';

  @override
  Future<ChatResponse> chatWithTools(
    List<ModelMessage> messages,
    List<Tool>? tools, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async {
    final requestBody = _buildRequestBody(
      messages,
      tools,
      false,
      false,
      options: options,
    );
    final responseData = await client.postJson(
      responsesEndpoint,
      requestBody,
      headers: options?.headers,
      cancelToken: CancellationUtils.toDioCancelToken(cancelToken),
    );
    return _parseResponse(responseData);
  }

  @override
  Future<ChatResponse> chatWithToolsBackground(
    List<ModelMessage> messages,
    List<Tool>? tools, {
    LanguageModelCallOptions? options,
  }) async {
    final requestBody = _buildRequestBody(
      messages,
      tools,
      false,
      true,
      options: options,
    );
    final responseData = await client.postJson(
      responsesEndpoint,
      requestBody,
      headers: options?.headers,
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
    final effectiveTools = tools ?? config.tools;
    final requestBody = _buildRequestBody(
      messages,
      effectiveTools,
      true,
      false,
      options: options,
    );

    _resetStreamState();

    try {
      final stream = client.postStreamRaw(
        responsesEndpoint,
        requestBody,
        headers: options?.headers,
        cancelToken: CancellationUtils.toDioCancelToken(cancelToken),
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
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    return chatWithTools(
      messages,
      tools,
      options: options,
      cancelToken: cancelToken,
    );
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
    List<ModelMessage> newMessages, {
    List<Tool>? tools,
    bool background = false,
  }) async {
    final updatedConfig =
        config.copyWith(previousResponseId: previousResponseId);
    final tempResponses = OpenAIResponses(client, updatedConfig);

    final requestBody = tempResponses._buildRequestBody(
      newMessages,
      tools,
      false,
      background,
    );
    final responseData = await client.postJson(responsesEndpoint, requestBody);
    return _parseResponse(responseData);
  }

  @override
  Future<ChatResponse> forkConversation(
    String fromResponseId,
    List<ModelMessage> newMessages, {
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
    List<ModelMessage> promptMessages,
    List<Tool>? tools,
    bool stream,
    bool background, {
    LanguageModelCallOptions? options,
  }) {
    final isReasoningModel =
        ReasoningUtils.isOpenAIReasoningModel(config.model);

    final apiMessages = client.buildApiMessagesFromPrompt(promptMessages);

    final hasSystemMessage =
        promptMessages.any((m) => m.role == ChatRole.system);

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

    // Core sampling and length parameters.
    // The Responses API uses max_output_tokens for all models.
    //
    // Per-call options override config-level defaults when provided so
    // that LanguageModelCallOptions behaves consistently across Chat and
    // Responses APIs.
    final effectiveMaxTokens = options?.maxTokens ?? config.maxTokens;
    if (effectiveMaxTokens != null) {
      body['max_output_tokens'] = effectiveMaxTokens;
    }

    // Reasoning models do not support temperature/top_p on the Responses API.
    final effectiveTemperature = options?.temperature ?? config.temperature;
    final effectiveTopP = options?.topP ?? config.topP;
    final effectiveTopK = options?.topK ?? config.topK;

    if (effectiveTemperature != null && !isReasoningModel) {
      body['temperature'] = effectiveTemperature;
    }

    if (effectiveTopP != null && !isReasoningModel) {
      body['top_p'] = effectiveTopP;
    }
    if (effectiveTopK != null) body['top_k'] = effectiveTopK;

    // Only attach reasoning config for reasoning-capable models.
    final effectiveReasoningEffort =
        options?.reasoningEffort ?? config.reasoningEffort;
    if (effectiveReasoningEffort != null && isReasoningModel) {
      body['reasoning'] = {
        'effort': effectiveReasoningEffort.value,
      };
    }

    // Preferred code path for tools: unified callTools (function + provider-defined).
    //
    // When [callTools] is provided, it takes precedence over the legacy
    // [tools] list and allows callers to mix traditional function tools
    // with provider-defined tools (`openai.*`) for the Responses API.
    final callTools = options?.callTools;
    if (callTools != null) {
      if (callTools.isEmpty) {
        // Explicitly configured tools for this call: none.
        // Skip legacy tools + builtInTools to avoid mixing sources.
        return body;
      }

      final functionSpecs = <FunctionCallToolSpec>[];
      final providerSpecs = <ProviderDefinedToolSpec>[];

      for (final spec in callTools) {
        if (spec is FunctionCallToolSpec) {
          functionSpecs.add(spec);
        } else if (spec is ProviderDefinedToolSpec) {
          providerSpecs.add(spec);
        }
      }

      final allTools = <Map<String, dynamic>>[];

      // Map provider-defined tools with `openai.*` ids to built-in
      // Responses tools.
      for (final spec in providerSpecs) {
        switch (spec.id) {
          case 'openai.web_search':
            {
              final allowedDomains =
                  spec.args['allowedDomains'] as List<String>?;
              final contextSize =
                  spec.args['contextSize'] as WebSearchContextSize?;
              final location = spec.args['location'] as WebSearchLocation?;

              final tool = OpenAIBuiltInTools.webSearch(
                allowedDomains: allowedDomains,
                contextSize: contextSize,
                location: location,
              );

              allTools.add(tool.toJson());
              break;
            }
          case 'openai.file_search':
            {
              final vectorStoreIds =
                  spec.args['vectorStoreIds'] as List<String>?;
              final maxNumResults = spec.args['maxNumResults'] as int?;
              final filters = spec.args['filters'] as Map<String, dynamic>?;

              final params = <String, dynamic>{};
              if (maxNumResults != null) {
                params['max_num_results'] = maxNumResults;
              }
              if (filters != null && filters.isNotEmpty) {
                params['filters'] = filters;
              }

              final tool = OpenAIBuiltInTools.fileSearch(
                vectorStoreIds: vectorStoreIds,
                parameters: params.isEmpty ? null : params,
              );

              allTools.add(tool.toJson());
              break;
            }
          case 'openai.code_interpreter':
            {
              final parameters =
                  spec.args['parameters'] as Map<String, dynamic>?;
              final tool = OpenAIBuiltInTools.codeInterpreter(
                parameters: parameters,
              );
              allTools.add(tool.toJson());
              break;
            }
          case 'openai.image_generation':
            {
              final model = spec.args['model'] as String?;
              final parameters =
                  spec.args['parameters'] as Map<String, dynamic>?;
              final tool = OpenAIBuiltInTools.imageGeneration(
                model: model,
                parameters: parameters,
              );
              allTools.add(tool.toJson());
              break;
            }
          default:
            // Ignore unsupported provider-defined tool ids for OpenAI.
            break;
        }
      }

      // Map function tools from FunctionCallToolSpec into the Responses
      // function tool format.
      if (functionSpecs.isNotEmpty) {
        final functionTools =
            functionSpecs.map((spec) => spec.tool).toList(growable: false);
        allTools.addAll(
          functionTools.map((t) => _convertToolToResponsesFormat(t)),
        );

        final effectiveToolChoice = options?.toolChoice ?? config.toolChoice;
        if (effectiveToolChoice != null && functionTools.isNotEmpty) {
          body['tool_choice'] = effectiveToolChoice.toJson();
        }
      }

      if (allTools.isNotEmpty) {
        body['tools'] = allTools;
      }

      // When callTools is used we intentionally skip the legacy tools +
      // builtInTools path to avoid mixing configuration sources.
      return body;
    }

    final allTools = <Map<String, dynamic>>[];

    final effectiveTools = options?.resolveTools() ?? tools ?? config.tools;
    if (effectiveTools != null && effectiveTools.isNotEmpty) {
      allTools
          .addAll(effectiveTools.map((t) => _convertToolToResponsesFormat(t)));
    }

    if (config.builtInTools != null && config.builtInTools!.isNotEmpty) {
      allTools.addAll(config.builtInTools!.map((t) => t.toJson()));
    }

    if (allTools.isNotEmpty) {
      body['tools'] = allTools;

      final effectiveToolChoice = options?.toolChoice ?? config.toolChoice;
      if (effectiveToolChoice != null &&
          effectiveTools != null &&
          effectiveTools.isNotEmpty) {
        body['tool_choice'] = effectiveToolChoice.toJson();
      }
    }

    final effectiveJsonSchema = options?.jsonSchema ?? config.jsonSchema;
    if (effectiveJsonSchema != null) {
      final schema = effectiveJsonSchema;
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
    _toolCallStreamState.reset();
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

    // Handle tool calls.
    //
    // The Responses API can also stream tool_calls incrementally:
    // - The first chunk may contain index + id + function.name + initial arguments
    // - Subsequent chunks typically contain only index + function.arguments
    //
    // We reuse the same index → id strategy as Chat so that every
    // ToolCallDeltaEvent has a stable id.
    final toolCalls = json['tool_calls'] as List?;
    if (toolCalls != null && toolCalls.isNotEmpty) {
      final toolCallMap = toolCalls.first as Map<String, dynamic>;
      final toolCall = _toolCallStreamState.processDelta(toolCallMap);
      if (toolCall != null) {
        events.add(ToolCallDeltaEvent(toolCall));
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

/// Typed view over a single web search source (URL or API).
class OpenAIResponsesWebSearchSource {
  final String type;
  final String? url;
  final String? name;

  const OpenAIResponsesWebSearchSource({
    required this.type,
    this.url,
    this.name,
  });
}

/// Typed view over the web search action executed by the tool.
class OpenAIResponsesWebSearchAction {
  /// Action type: `search` | `open_page` | `find`.
  final String type;

  /// Search query (for `search` actions).
  final String? query;

  /// URL associated with `open_page` / `find` actions.
  final String? url;

  /// Search pattern for `find` actions.
  final String? pattern;

  /// Optional list of sources for `search` actions.
  final List<OpenAIResponsesWebSearchSource>? sources;

  const OpenAIResponsesWebSearchAction({
    required this.type,
    this.query,
    this.url,
    this.pattern,
    this.sources,
  });
}

/// Typed view over a single `web_search_call` output item.
class OpenAIResponsesWebSearchCall {
  final String id;
  final String status;
  final OpenAIResponsesWebSearchAction action;

  const OpenAIResponsesWebSearchCall({
    required this.id,
    required this.status,
    required this.action,
  });
}

/// Typed view over a single file search result item.
class OpenAIResponsesFileSearchResultItem {
  final Map<String, dynamic> attributes;
  final String fileId;
  final String filename;
  final double score;
  final String text;

  const OpenAIResponsesFileSearchResultItem({
    required this.attributes,
    required this.fileId,
    required this.filename,
    required this.score,
    required this.text,
  });
}

/// Typed view over a `file_search_call` output item.
class OpenAIResponsesFileSearchCall {
  final String id;
  final List<String> queries;
  final List<OpenAIResponsesFileSearchResultItem>? results;

  const OpenAIResponsesFileSearchCall({
    required this.id,
    required this.queries,
    this.results,
  });
}

/// Typed view over a single code interpreter output item.
class OpenAIResponsesCodeInterpreterOutputItem {
  /// Output type: `logs` or `image`.
  final String type;

  /// Logs content when [type] is `logs`.
  final String? logs;

  /// Image URL when [type] is `image`.
  final String? url;

  const OpenAIResponsesCodeInterpreterOutputItem({
    required this.type,
    this.logs,
    this.url,
  });
}

/// Typed view over a `code_interpreter_call` output item.
class OpenAIResponsesCodeInterpreterCall {
  final String id;
  final String containerId;
  final String? code;
  final List<OpenAIResponsesCodeInterpreterOutputItem>? outputs;

  const OpenAIResponsesCodeInterpreterCall({
    required this.id,
    required this.containerId,
    this.code,
    this.outputs,
  });
}

/// Typed view over an `image_generation_call` output item.
class OpenAIResponsesImageGenerationCall {
  final String id;
  final String result;

  const OpenAIResponsesImageGenerationCall({
    required this.id,
    required this.result,
  });
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

  @override
  CallMetadata? get callMetadata {
    final data = metadata;
    if (data == null) return null;
    return CallMetadata.fromJson(data);
  }

  String? get responseId => _rawResponse['id'] as String?;

  /// Typed access to web search tool calls (if any).
  ///
  /// This inspects the structured `output` list for items of type
  /// `web_search_call` and converts them into strongly-typed
  /// [OpenAIResponsesWebSearchCall] instances. If no such items are
  /// present or the response does not contain an `output` list, this
  /// returns `null`.
  List<OpenAIResponsesWebSearchCall>? get webSearchCalls {
    final output = _rawResponse['output'] as List?;
    if (output == null || output.isEmpty) return null;

    final results = <OpenAIResponsesWebSearchCall>[];

    for (final item in output) {
      if (item is! Map<String, dynamic>) continue;
      if (item['type'] != 'web_search_call') continue;

      final id = item['id'] as String? ?? '';
      final status = item['status'] as String? ?? '';
      final action = item['action'] as Map<String, dynamic>?;
      if (action == null) continue;

      final actionType = action['type'] as String? ?? '';
      String? query;
      String? url;
      String? pattern;
      List<OpenAIResponsesWebSearchSource>? sources;

      if (actionType == 'search') {
        query = action['query'] as String?;
        final rawSources = action['sources'] as List?;
        if (rawSources != null && rawSources.isNotEmpty) {
          sources = <OpenAIResponsesWebSearchSource>[];
          for (final src in rawSources) {
            if (src is! Map<String, dynamic>) continue;
            final type = src['type'] as String? ?? '';
            final urlValue = src['url'] as String?;
            final nameValue = src['name'] as String?;
            sources.add(
              OpenAIResponsesWebSearchSource(
                type: type,
                url: urlValue,
                name: nameValue,
              ),
            );
          }
        }
      } else if (actionType == 'open_page') {
        url = action['url'] as String?;
      } else if (actionType == 'find') {
        url = action['url'] as String?;
        pattern = action['pattern'] as String?;
      }

      results.add(
        OpenAIResponsesWebSearchCall(
          id: id,
          status: status,
          action: OpenAIResponsesWebSearchAction(
            type: actionType,
            query: query,
            url: url,
            pattern: pattern,
            sources: sources,
          ),
        ),
      );
    }

    return results.isEmpty ? null : results;
  }

  /// Typed access to file search tool calls (if any).
  ///
  /// This inspects the `output` list for items of type `file_search_call`
  /// and converts them into [OpenAIResponsesFileSearchCall] instances.
  List<OpenAIResponsesFileSearchCall>? get fileSearchCalls {
    final output = _rawResponse['output'] as List?;
    if (output == null || output.isEmpty) return null;

    final results = <OpenAIResponsesFileSearchCall>[];

    for (final item in output) {
      if (item is! Map<String, dynamic>) continue;
      if (item['type'] != 'file_search_call') continue;

      final id = item['id'] as String? ?? '';
      final rawQueries = item['queries'] as List?;
      final queries = rawQueries != null
          ? rawQueries.map((q) => q.toString()).toList()
          : const <String>[];

      final rawResults = item['results'] as List?;
      List<OpenAIResponsesFileSearchResultItem>? parsedResults;

      if (rawResults != null && rawResults.isNotEmpty) {
        parsedResults = <OpenAIResponsesFileSearchResultItem>[];
        for (final r in rawResults) {
          if (r is! Map<String, dynamic>) continue;
          final attributesRaw = r['attributes'];
          final attributes = attributesRaw is Map<String, dynamic>
              ? attributesRaw
              : attributesRaw is Map
                  ? Map<String, dynamic>.from(attributesRaw)
                  : <String, dynamic>{};
          final fileId = r['file_id'] as String? ?? '';
          final filename = r['filename'] as String? ?? '';
          final score = (r['score'] as num?)?.toDouble() ?? 0.0;
          final text = r['text'] as String? ?? '';

          parsedResults.add(
            OpenAIResponsesFileSearchResultItem(
              attributes: attributes,
              fileId: fileId,
              filename: filename,
              score: score,
              text: text,
            ),
          );
        }
      }

      results.add(
        OpenAIResponsesFileSearchCall(
          id: id,
          queries: queries,
          results: parsedResults,
        ),
      );
    }

    return results.isEmpty ? null : results;
  }

  /// Typed access to code interpreter tool calls (if any).
  ///
  /// This inspects the `output` list for items of type
  /// `code_interpreter_call` and converts them into
  /// [OpenAIResponsesCodeInterpreterCall] instances.
  List<OpenAIResponsesCodeInterpreterCall>? get codeInterpreterCalls {
    final output = _rawResponse['output'] as List?;
    if (output == null || output.isEmpty) return null;

    final results = <OpenAIResponsesCodeInterpreterCall>[];

    for (final item in output) {
      if (item is! Map<String, dynamic>) continue;
      if (item['type'] != 'code_interpreter_call') continue;

      final id = item['id'] as String? ?? '';
      final containerId = item['container_id'] as String? ?? '';
      final code = item['code'] as String?;

      final rawOutputs = item['outputs'] as List?;
      List<OpenAIResponsesCodeInterpreterOutputItem>? outputs;
      if (rawOutputs != null && rawOutputs.isNotEmpty) {
        outputs = <OpenAIResponsesCodeInterpreterOutputItem>[];
        for (final o in rawOutputs) {
          if (o is! Map<String, dynamic>) continue;
          final type = o['type'] as String? ?? '';
          if (type == 'logs') {
            outputs.add(
              OpenAIResponsesCodeInterpreterOutputItem(
                type: type,
                logs: o['logs'] as String? ?? '',
              ),
            );
          } else if (type == 'image') {
            outputs.add(
              OpenAIResponsesCodeInterpreterOutputItem(
                type: type,
                url: o['url'] as String? ?? '',
              ),
            );
          }
        }
      }

      results.add(
        OpenAIResponsesCodeInterpreterCall(
          id: id,
          containerId: containerId,
          code: code,
          outputs: outputs,
        ),
      );
    }

    return results.isEmpty ? null : results;
  }

  /// Typed access to image generation tool calls (if any).
  ///
  /// This inspects the `output` list for items of type
  /// `image_generation_call` and converts them into
  /// [OpenAIResponsesImageGenerationCall] instances.
  List<OpenAIResponsesImageGenerationCall>? get imageGenerationCalls {
    final output = _rawResponse['output'] as List?;
    if (output == null || output.isEmpty) return null;

    final results = <OpenAIResponsesImageGenerationCall>[];

    for (final item in output) {
      if (item is! Map<String, dynamic>) continue;
      if (item['type'] != 'image_generation_call') continue;

      final id = item['id'] as String? ?? '';
      final result = item['result'] as String? ?? '';

      results.add(
        OpenAIResponsesImageGenerationCall(
          id: id,
          result: result,
        ),
      );
    }

    return results.isEmpty ? null : results;
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
