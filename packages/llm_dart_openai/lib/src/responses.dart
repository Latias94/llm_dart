import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'client.dart';
import 'builtin_tools.dart';
import 'config.dart';
import 'models/responses_models.dart';
import 'responses_capability.dart';
import 'responses_message_converter.dart';

class _OpenAIResponsesBuiltRequest {
  final Map<String, dynamic> body;
  final ToolNameMapping toolNameMapping;

  const _OpenAIResponsesBuiltRequest({
    required this.body,
    required this.toolNameMapping,
  });
}

/// OpenAI Responses API capability implementation
///
/// This module handles the new Responses API which combines the simplicity
/// of Chat Completions with the tool-use capabilities of the Assistants API.
/// It supports built-in tools like web search, file search, and computer use.
class OpenAIResponses
    implements
        ChatCapability,
        OpenAIResponsesCapability,
        ChatStreamPartsCapability {
  final OpenAIClient client;
  final OpenAIConfig config;

  // State tracking for stream processing
  bool _hasReasoningContent = false;
  String _lastChunk = '';
  final StringBuffer _thinkingBuffer = StringBuffer();
  final StringBuffer _outputTextBuffer = StringBuffer();
  final List<dynamic> _outputTextAnnotations = [];
  Map<String, dynamic>? _partialResponse;
  List<dynamic>? _partialOutput;
  // Track tool call IDs by index for streaming tool calls in the Responses API.
  // The Responses stream can send tool_calls incrementally where only the
  // first chunk contains the id and later chunks reference the same call
  // via an index. This map keeps a stable id per index so that every
  // ToolCallDeltaEvent carries a consistent toolCall.id.
  final Map<int, String> _toolCallIds = {};
  // Track tool call function names by index for streaming tool calls.
  //
  // The Responses stream may omit function.name after the first chunk and
  // only send function.arguments deltas. We cache the latest known name so
  // that downstream tool execution can reliably match the tool.
  final Map<int, String> _toolCallNames = {};

  OpenAIResponses(this.client, this.config);

  String get responsesEndpoint => 'responses';

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    final builtRequest = _buildRequest(messages, tools, false, false);
    final responseData = await client.postJson(
      responsesEndpoint,
      builtRequest.body,
      cancelToken: cancelToken,
    );
    return _parseResponse(
      responseData,
      toolNameMapping: builtRequest.toolNameMapping,
    );
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
    final builtRequest = _buildRequest(messages, tools, false, true);
    final responseData =
        await client.postJson(responsesEndpoint, builtRequest.body);
    return _parseResponse(
      responseData,
      toolNameMapping: builtRequest.toolNameMapping,
    );
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    final builtRequest = _buildRequest(messages, tools, true, false);

    // Reset stream state
    _resetStreamState();
    var didEmitCompletion = false;

    try {
      // Create SSE stream
      final stream = client.postStreamRaw(
        responsesEndpoint,
        builtRequest.body,
        cancelToken: cancelToken,
      );

      await for (final chunk in stream) {
        try {
          final events = _parseStreamEvents(
            chunk,
            toolNameMapping: builtRequest.toolNameMapping,
          );
          for (final event in events) {
            if (event is CompletionEvent) {
              didEmitCompletion = true;
            }
            yield event;
          }
        } catch (e) {
          // Log parsing errors but continue processing
          client.logger.warning('Failed to parse stream chunk: $e');
        }
      }

      // Some Responses streams may end with [DONE] without a `response.completed`
      // event. Emit a best-effort completion to keep stream consumers
      // consistent and to surface providerMetadata/tool summaries.
      if (!didEmitCompletion) {
        final thinkingContent =
            _thinkingBuffer.isNotEmpty ? _thinkingBuffer.toString() : null;
        final response = OpenAIResponsesResponse(
          _buildPartialResponse(),
          thinkingContent,
          builtRequest.toolNameMapping,
        );
        yield CompletionEvent(response);
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
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    final builtRequest = _buildRequest(messages, tools, true, false);
    final toolNameMapping = builtRequest.toolNameMapping;

    _resetStreamState();

    var inText = false;
    var inThinking = false;
    final startedToolCalls = <String>{};

    var didFinish = false;

    try {
      final stream = client.postStreamRaw(
        responsesEndpoint,
        builtRequest.body,
        cancelToken: cancelToken,
      );

      await for (final chunk in stream) {
        final jsonList = client.parseSSEChunk(chunk);
        if (jsonList.isEmpty) continue;

        for (final json in jsonList) {
          final eventType = json['type'] as String?;

          if (eventType == 'response.created' ||
              eventType == 'response.in_progress') {
            _captureResponseObject(json['response']);
            continue;
          }

          if (eventType == 'response.output_item.added' ||
              eventType == 'response.output_item.done') {
            final outputIndex = json['output_index'] as int?;
            if (outputIndex != null) {
              _upsertOutputItem(outputIndex, json['item']);
            }

            if (eventType == 'response.output_item.done') {
              final metadata = OpenAIResponsesResponse(_buildPartialResponse())
                  .providerMetadata;
              if (metadata != null && metadata.isNotEmpty) {
                yield LLMProviderMetadataPart(metadata);
              }
            }
            continue;
          }

          if (eventType == 'response.output_text.annotation.added') {
            final annotation = json['annotation'];
            if (annotation != null) {
              _outputTextAnnotations.add(annotation);
              final metadata = OpenAIResponsesResponse(_buildPartialResponse())
                  .providerMetadata;
              if (metadata != null && metadata.isNotEmpty) {
                yield LLMProviderMetadataPart(metadata);
              }
            }
            continue;
          }

          if (eventType == 'response.output_text.done') {
            final text = json['text'] as String?;
            if (text != null) {
              _outputTextBuffer.clear();
              _outputTextBuffer.write(text);
            }
            continue;
          }

          // OpenAI Responses: encrypted reasoning comes as a summary stream.
          // We map it to `thinking` (same as other reasoning deltas).
          if (eventType == 'response.reasoning_summary_text.delta') {
            final delta = json['delta'] as String?;
            if (delta == null || delta.isEmpty) continue;

            if (!inThinking) {
              inThinking = true;
              yield const LLMReasoningStartPart();
            }
            _thinkingBuffer.write(delta);
            yield LLMReasoningDeltaPart(delta);
            continue;
          }

          if (eventType == 'response.reasoning_summary_text.done') {
            final text = json['text'] as String?;
            if (text != null) {
              if (!inThinking) {
                inThinking = true;
                yield const LLMReasoningStartPart();
              }
              _thinkingBuffer
                ..clear()
                ..write(text);
            }
            continue;
          }

          if (eventType == 'response.output_text.delta') {
            final delta = json['delta'] as String?;
            if (delta == null || delta.isEmpty) continue;

            _lastChunk = delta;

            if (ReasoningUtils.containsThinkingTags(delta)) {
              final thinkMatch = RegExp(
                r'<think>(.*?)</think>',
                dotAll: true,
              ).firstMatch(delta);
              final thinkingText = thinkMatch?.group(1)?.trim();
              if (thinkingText != null && thinkingText.isNotEmpty) {
                if (!inThinking) {
                  inThinking = true;
                  yield const LLMReasoningStartPart();
                }
                _thinkingBuffer.write(thinkingText);
                yield LLMReasoningDeltaPart(thinkingText);
              }
              continue;
            }

            if (!inText) {
              inText = true;
              yield const LLMTextStartPart();
            }
            _outputTextBuffer.write(delta);
            yield LLMTextDeltaPart(delta);
            continue;
          }

          // Fallback: reasoning content in other fields
          final reasoningContent = ReasoningUtils.extractReasoningContent(json);
          if (reasoningContent != null && reasoningContent.isNotEmpty) {
            if (!inThinking) {
              inThinking = true;
              yield const LLMReasoningStartPart();
            }
            _thinkingBuffer.write(reasoningContent);
            _hasReasoningContent = true;
            yield LLMReasoningDeltaPart(reasoningContent);
            continue;
          }

          // Function tool calls (client-side tools)
          final toolCalls = json['tool_calls'] as List?;
          if (toolCalls != null && toolCalls.isNotEmpty) {
            final toolCallMap = toolCalls.first as Map<String, dynamic>;
            final index = toolCallMap['index'] as int?;

            if (index != null) {
              final id = toolCallMap['id'] as String?;
              if (id != null && id.isNotEmpty) {
                _toolCallIds[index] = id;
              }

              final stableId = _toolCallIds[index];
              if (stableId != null) {
                final functionMap =
                    toolCallMap['function'] as Map<String, dynamic>?;
                if (functionMap != null) {
                  final rawName = functionMap['name'] as String?;
                  if (rawName != null && rawName.isNotEmpty) {
                    _toolCallNames[index] = rawName;
                  }
                  final requestName = _toolCallNames[index] ?? '';
                  final name =
                      toolNameMapping.originalFunctionNameForRequestName(
                            requestName,
                          ) ??
                          requestName;
                  final args = functionMap['arguments'] as String? ?? '';
                  if (name.isNotEmpty || args.isNotEmpty) {
                    final toolCall = ToolCall(
                      id: stableId,
                      callType: 'function',
                      function: FunctionCall(
                        name: name,
                        arguments: args,
                      ),
                    );
                    if (startedToolCalls.add(toolCall.id)) {
                      yield LLMToolCallStartPart(toolCall);
                    } else {
                      yield LLMToolCallDeltaPart(toolCall);
                    }
                  }
                }
              }
            } else if (toolCallMap.containsKey('id') &&
                toolCallMap.containsKey('function')) {
              try {
                final toolCall = ToolCall.fromJson(toolCallMap);
                final requestName = toolCall.function.name;
                final originalName =
                    toolNameMapping.originalFunctionNameForRequestName(
                          requestName,
                        ) ??
                        requestName;
                if (startedToolCalls.add(toolCall.id)) {
                  yield LLMToolCallStartPart(
                    ToolCall(
                      id: toolCall.id,
                      callType: toolCall.callType,
                      function: FunctionCall(
                        name: originalName,
                        arguments: toolCall.function.arguments,
                      ),
                    ),
                  );
                } else {
                  yield LLMToolCallDeltaPart(
                    ToolCall(
                      id: toolCall.id,
                      callType: toolCall.callType,
                      function: FunctionCall(
                        name: originalName,
                        arguments: toolCall.function.arguments,
                      ),
                    ),
                  );
                }
              } catch (_) {
                // Ignore malformed tool calls
              }
            }
          }

          if (eventType == 'response.completed') {
            didFinish = true;

            final completedResponse = json['response'];
            if (completedResponse is Map) {
              _captureResponseObject(completedResponse);
            }

            final thinkingContent =
                _thinkingBuffer.isNotEmpty ? _thinkingBuffer.toString() : null;
            final response = OpenAIResponsesResponse(
              _buildPartialResponse(),
              thinkingContent,
              toolNameMapping,
            );

            if (inText) {
              yield LLMTextEndPart(_outputTextBuffer.toString());
            }
            if (inThinking) {
              yield LLMReasoningEndPart(_thinkingBuffer.toString());
            }
            for (final id in startedToolCalls) {
              yield LLMToolCallEndPart(id);
            }

            final metadata = response.providerMetadata;
            if (metadata != null && metadata.isNotEmpty) {
              yield LLMProviderMetadataPart(metadata);
            }

            yield LLMFinishPart(response);
            return;
          }
        }
      }

      // Best-effort finish if stream ends with [DONE] but no response.completed.
      if (!didFinish) {
        final thinkingContent =
            _thinkingBuffer.isNotEmpty ? _thinkingBuffer.toString() : null;
        final response = OpenAIResponsesResponse(
          _buildPartialResponse(),
          thinkingContent,
          toolNameMapping,
        );

        if (inText) {
          yield LLMTextEndPart(_outputTextBuffer.toString());
        }
        if (inThinking) {
          yield LLMReasoningEndPart(_thinkingBuffer.toString());
        }
        for (final id in startedToolCalls) {
          yield LLMToolCallEndPart(id);
        }

        final metadata = response.providerMetadata;
        if (metadata != null && metadata.isNotEmpty) {
          yield LLMProviderMetadataPart(metadata);
        }
        yield LLMFinishPart(response);
      }
    } catch (e) {
      if (e is LLMError) {
        yield LLMErrorPart(e);
        return;
      }
      yield LLMErrorPart(GenericError('Stream error: $e'));
      return;
    } finally {
      _resetStreamState();
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

    final builtRequest =
        tempResponses._buildRequest(newMessages, tools, false, background);
    final responseData =
        await client.postJson(responsesEndpoint, builtRequest.body);
    return _parseResponse(
      responseData,
      toolNameMapping: builtRequest.toolNameMapping,
    );
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

  _OpenAIResponsesBuiltRequest _buildRequest(
    List<ChatMessage> messages,
    List<Tool>? tools,
    bool stream,
    bool background,
  ) {
    final effectiveTools = tools ?? config.tools;
    final toolNameMapping = _createToolNameMapping(effectiveTools);
    final body = _buildRequestBody(
      messages,
      effectiveTools,
      stream,
      background,
      toolNameMapping,
    );

    return _OpenAIResponsesBuiltRequest(
        body: body, toolNameMapping: toolNameMapping);
  }

  ToolNameMapping _createToolNameMapping(List<Tool>? tools) {
    final functionToolNames =
        (tools ?? const <Tool>[]).map((t) => t.function.name);

    final providerToolRequestNamesById = <String, String>{};
    final builtInTools = config.builtInTools;
    if (builtInTools != null) {
      for (final tool in builtInTools) {
        final rawType = tool.toJson()['type'];
        if (rawType is String && rawType.isNotEmpty) {
          providerToolRequestNamesById['openai.$rawType'] = rawType;
        }
      }
    }

    return createToolNameMapping(
      functionToolNames: functionToolNames,
      providerToolRequestNamesById: providerToolRequestNamesById,
    );
  }

  /// Build request body for Responses API
  Map<String, dynamic> _buildRequestBody(
    List<ChatMessage> messages,
    List<Tool>? tools,
    bool stream,
    bool background,
    ToolNameMapping toolNameMapping,
  ) {
    // Convert messages to Responses API format.
    final apiMessages =
        OpenAIResponsesMessageConverter.buildInputMessages(messages);

    // Handle system prompt: prefer explicit system messages over config
    final hasSystemMessage = messages.any((m) => m.role == ChatRole.system);

    // Only add config system prompt if no explicit system message exists
    if (!hasSystemMessage && config.systemPrompt != null) {
      apiMessages.insert(0, {'role': 'system', 'content': config.systemPrompt});
    }

    final body = <String, dynamic>{
      'model': config.model,
      'input': apiMessages,
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

    // Add temperature (provider will validate support).
    if (config.temperature != null) {
      body['temperature'] = config.temperature;
    }

    // Add top_p (provider will validate support).
    if (config.topP != null) {
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
    final functionTools = tools ?? config.tools;
    if (functionTools != null && functionTools.isNotEmpty) {
      allTools.addAll(
        functionTools.map(
          (t) => _convertToolToResponsesFormat(t, toolNameMapping),
        ),
      );
    }

    // Add built-in tools
    if (config.builtInTools != null && config.builtInTools!.isNotEmpty) {
      allTools.addAll(config.builtInTools!.map((t) => t.toJson()));
    }

    if (allTools.isNotEmpty) {
      body['tools'] = allTools;

      // Add tool choice if configured.
      //
      // Vercel AI SDK serializes `tool_choice` as:
      // - strings for `auto` / `none` / `required`
      // - objects for specific tool selection
      final effectiveToolChoice = config.toolChoice;
      if (effectiveToolChoice != null) {
        final toolChoiceValue = _convertToolChoiceForResponses(
          effectiveToolChoice,
          functionTools: functionTools,
          builtInTools: config.builtInTools,
          toolNameMapping: toolNameMapping,
        );
        if (toolChoiceValue != null) {
          body['tool_choice'] = toolChoiceValue;
        }
      }
    }

    // Add include options (Responses API)
    //
    // Vercel AI SDK auto-includes web search sources when the built-in tool is
    // present. We mirror that behavior so that providerMetadata can expose
    // `webSearchCalls[*].sources` reliably.
    final include = <String>[];

    final rawInclude =
        config.originalConfig?.getProviderOption<dynamic>('openai', 'include');
    if (rawInclude is List) {
      include.addAll(rawInclude.whereType<String>());
    }

    final builtInTools = config.builtInTools;

    final hasWebSearchTool = builtInTools?.any(
          (t) =>
              t.type == OpenAIBuiltInToolType.webSearch ||
              t.type == OpenAIBuiltInToolType.webSearchFull,
        ) ??
        false;
    if (hasWebSearchTool) {
      include.add('web_search_call.action.sources');
    }

    final hasFileSearchTool = builtInTools?.any(
          (t) => t.type == OpenAIBuiltInToolType.fileSearch,
        ) ??
        false;
    if (hasFileSearchTool) {
      include.add('file_search_call.results');
    }

    final hasComputerUseTool = builtInTools?.any(
          (t) => t.type == OpenAIBuiltInToolType.computerUse,
        ) ??
        false;
    if (hasComputerUseTool) {
      include.add('computer_call_output.output.image_url');
    }

    final hasCodeInterpreterTool = builtInTools?.any(
          (t) => t.type == OpenAIBuiltInToolType.codeInterpreter,
        ) ??
        false;
    if (hasCodeInterpreterTool) {
      include.add('code_interpreter_call.outputs');
    }

    if (include.isNotEmpty) {
      body['include'] = include.toSet().toList();
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

    // Add OpenAI-specific provider options
    final frequencyPenalty =
        config.getProviderOption<double>('frequencyPenalty');
    if (frequencyPenalty != null) {
      body['frequency_penalty'] = frequencyPenalty;
    }

    final presencePenalty = config.getProviderOption<double>('presencePenalty');
    if (presencePenalty != null) {
      body['presence_penalty'] = presencePenalty;
    }

    final logitBias =
        config.getProviderOption<Map<String, double>>('logitBias');
    if (logitBias != null && logitBias.isNotEmpty) {
      body['logit_bias'] = logitBias;
    }

    final seed = config.getProviderOption<int>('seed');
    if (seed != null) {
      body['seed'] = seed;
    }

    final parallelToolCalls = config.getProviderOption<bool>(
      'parallelToolCalls',
    );
    if (parallelToolCalls != null) {
      body['parallel_tool_calls'] = parallelToolCalls;
    }

    final logprobs = config.getProviderOption<bool>('logprobs');
    if (logprobs != null) {
      body['logprobs'] = logprobs;
    }

    final topLogprobs = config.getProviderOption<int>('topLogprobs');
    if (topLogprobs != null) {
      body['top_logprobs'] = topLogprobs;
    }

    final extraBodyFromConfig = config.extraBody;
    if (extraBodyFromConfig != null && extraBodyFromConfig.isNotEmpty) {
      body.addAll(extraBodyFromConfig);
    }

    return body;
  }

  dynamic _convertToolChoiceForResponses(
    ToolChoice toolChoice, {
    required List<Tool>? functionTools,
    required List<OpenAIBuiltInTool>? builtInTools,
    required ToolNameMapping toolNameMapping,
  }) {
    return switch (toolChoice) {
      AutoToolChoice() => 'auto',
      NoneToolChoice() => 'none',
      AnyToolChoice() => 'required',
      SpecificToolChoice(toolName: final toolName) =>
        _convertSpecificToolChoiceForResponses(
          toolName,
          functionTools: functionTools,
          builtInTools: builtInTools,
          toolNameMapping: toolNameMapping,
        ),
    };
  }

  Map<String, dynamic>? _convertSpecificToolChoiceForResponses(
    String toolName, {
    required List<Tool>? functionTools,
    required List<OpenAIBuiltInTool>? builtInTools,
    required ToolNameMapping toolNameMapping,
  }) {
    final functionToolNames =
        (functionTools ?? const <Tool>[]).map((t) => t.function.name).toSet();

    // Prefer matching original function tool names (supports collision-safe
    // rewriting via ToolNameMapping).
    if (functionToolNames.contains(toolName)) {
      return {
        'type': 'function',
        'name': toolNameMapping.requestNameForFunction(toolName),
      };
    }

    // If the caller did not configure function tools but did configure an
    // OpenAI built-in tool, allow selecting it by the built-in `type` name.
    final builtInTypes = (builtInTools ?? const <OpenAIBuiltInTool>[])
        .map((t) => t.toJson()['type'])
        .whereType<String>()
        .toSet();
    if (builtInTypes.contains(toolName)) {
      return {'type': toolName};
    }

    // Fallback: treat the provided name as a request tool name. This enables
    // advanced callers to target collision-rewritten function tool names (e.g.
    // `tool__1`) without requiring a new public API surface.
    if (functionToolNames.isNotEmpty) {
      return {'type': 'function', 'name': toolName};
    }

    // No tools matched; omit `tool_choice` to avoid invalid requests.
    return null;
  }

  /// Parse non-streaming response
  ChatResponse _parseResponse(
    Map<String, dynamic> responseData, {
    ToolNameMapping? toolNameMapping,
  }) {
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

    return OpenAIResponsesResponse(
        responseData, thinkingContent, toolNameMapping);
  }

  /// Parse streaming events
  List<ChatStreamEvent> _parseStreamEvents(
    String chunk, {
    required ToolNameMapping toolNameMapping,
  }) {
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
        toolNameMapping: toolNameMapping,
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
    _toolCallIds.clear();
    _toolCallNames.clear();
    _outputTextBuffer.clear();
    _outputTextAnnotations.clear();
    _partialResponse = null;
    _partialOutput = null;
  }

  Map<String, dynamic> _buildPartialResponse() {
    final result = <String, dynamic>{};

    final base = _partialResponse;
    if (base != null) {
      result.addAll(base);
    }

    final output = _partialOutput;
    if (output != null) {
      result['output'] = output;
    }

    if (_outputTextBuffer.isNotEmpty) {
      result['output_text'] = _outputTextBuffer.toString();
    }

    if (_outputTextAnnotations.isNotEmpty) {
      result['output_text_annotations'] =
          List<dynamic>.from(_outputTextAnnotations);
    }

    return result;
  }

  void _captureResponseObject(dynamic rawResponse) {
    if (rawResponse is! Map) return;
    _partialResponse = Map<String, dynamic>.from(rawResponse);

    final output = _partialResponse?['output'];
    if (output is List) {
      _partialOutput = List<dynamic>.from(output);
    }
  }

  void _upsertOutputItem(int outputIndex, dynamic rawItem) {
    if (rawItem is! Map) return;
    _partialOutput ??= <dynamic>[];
    while (_partialOutput!.length <= outputIndex) {
      _partialOutput!.add(null);
    }
    _partialOutput![outputIndex] = Map<String, dynamic>.from(rawItem);
    _partialResponse ??= <String, dynamic>{};
    _partialResponse!['output'] = _partialOutput;
  }

  /// Parse stream events with reasoning support
  List<ChatStreamEvent> _parseStreamEventWithReasoning(
      Map<String, dynamic> json,
      bool hasReasoningContent,
      String lastChunk,
      StringBuffer thinkingBuffer,
      {required ToolNameMapping toolNameMapping}) {
    final events = <ChatStreamEvent>[];

    // Handle Responses API streaming events
    final eventType = json['type'] as String?;

    if (eventType == 'response.created' ||
        eventType == 'response.in_progress') {
      _captureResponseObject(json['response']);
      return events;
    }

    if (eventType == 'response.output_item.added' ||
        eventType == 'response.output_item.done') {
      final outputIndex = json['output_index'] as int?;
      if (outputIndex != null) {
        _upsertOutputItem(outputIndex, json['item']);
      }
      return events;
    }

    if (eventType == 'response.output_text.annotation.added') {
      final annotation = json['annotation'];
      if (annotation != null) {
        _outputTextAnnotations.add(annotation);
      }
      return events;
    }

    if (eventType == 'response.output_text.done') {
      final text = json['text'] as String?;
      if (text != null) {
        _outputTextBuffer.clear();
        _outputTextBuffer.write(text);
      }
      return events;
    }

    if (eventType == 'response.reasoning_summary_text.delta') {
      final delta = json['delta'] as String?;
      if (delta != null && delta.isNotEmpty) {
        thinkingBuffer.write(delta);
        events.add(ThinkingDeltaEvent(delta));
      }
      return events;
    }

    if (eventType == 'response.reasoning_summary_text.done') {
      final text = json['text'] as String?;
      if (text != null) {
        thinkingBuffer
          ..clear()
          ..write(text);
      }
      return events;
    }

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

        _outputTextBuffer.write(delta);
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
            OpenAIResponsesResponse(response, thinkingContent, toolNameMapping);
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

    // Handle tool calls (if supported in Responses API).
    //
    // The Responses API can stream tool_calls incrementally. The first chunk
    // typically includes index + id + function.name + initial arguments,
    // while subsequent chunks often only provide index + function.arguments.
    //
    // We mirror the chat implementation and cache ids by index so that each
    // ToolCallDeltaEvent has a stable id for callers to aggregate arguments.
    final toolCalls = json['tool_calls'] as List?;
    if (toolCalls != null && toolCalls.isNotEmpty) {
      final toolCallMap = toolCalls.first as Map<String, dynamic>;
      final index = toolCallMap['index'] as int?;

      if (index != null) {
        // Update mapping when an id is present on this chunk.
        final id = toolCallMap['id'] as String?;
        if (id != null && id.isNotEmpty) {
          _toolCallIds[index] = id;
        }

        final stableId = _toolCallIds[index];
        if (stableId != null) {
          final functionMap = toolCallMap['function'] as Map<String, dynamic>?;
          if (functionMap != null) {
            final rawName = functionMap['name'] as String?;
            if (rawName != null && rawName.isNotEmpty) {
              _toolCallNames[index] = rawName;
            }
            final requestName = _toolCallNames[index] ?? '';
            final name = toolNameMapping.originalFunctionNameForRequestName(
                  requestName,
                ) ??
                requestName;
            final args = functionMap['arguments'] as String? ?? '';

            if (name.isNotEmpty || args.isNotEmpty) {
              final toolCall = ToolCall(
                id: stableId,
                callType: 'function',
                function: FunctionCall(
                  name: name,
                  arguments: args,
                ),
              );
              events.add(ToolCallDeltaEvent(toolCall));
            }
          }
        }
      } else if (toolCallMap.containsKey('id') &&
          toolCallMap.containsKey('function')) {
        // Fallback: handle tool calls that provide a full object without index.
        try {
          final toolCall = ToolCall.fromJson(toolCallMap);
          final requestName = toolCall.function.name;
          final originalName =
              toolNameMapping.originalFunctionNameForRequestName(requestName) ??
                  requestName;
          events.add(
            ToolCallDeltaEvent(
              ToolCall(
                id: toolCall.id,
                callType: toolCall.callType,
                function: FunctionCall(
                  name: originalName,
                  arguments: toolCall.function.arguments,
                ),
              ),
            ),
          );
        } catch (e) {
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

      final partialResponse = _buildPartialResponse();
      if (usage != null) {
        partialResponse['usage'] = usage;
      }

      final response = OpenAIResponsesResponse(
        partialResponse.isEmpty
            ? {
                'output_text': '',
                if (usage != null) 'usage': usage,
              }
            : partialResponse,
        thinkingContent,
        toolNameMapping,
      );

      events.add(CompletionEvent(response));

      // Reset state after completion
      _resetStreamState();
    }

    return events;
  }

  /// Convert Tool to Responses API format
  ///
  /// Responses API expects a flattened format instead of nested function object
  Map<String, dynamic> _convertToolToResponsesFormat(
    Tool tool,
    ToolNameMapping toolNameMapping,
  ) {
    final requestName =
        toolNameMapping.requestNameForFunction(tool.function.name);
    return {
      'type': 'function',
      'name': requestName,
      'description': tool.function.description,
      'parameters': tool.function.parameters.toJson(),
      if (tool.strict != null) 'strict': tool.strict,
    };
  }
}

/// OpenAI Responses API response implementation
class OpenAIResponsesResponse implements ChatResponse {
  final Map<String, dynamic> _rawResponse;
  final String? _thinkingContent;
  final ToolNameMapping? _toolNameMapping;

  OpenAIResponsesResponse(
    this._rawResponse, [
    this._thinkingContent,
    this._toolNameMapping,
  ]);

  List<Map<String, dynamic>>? _extractFileSearchCalls() {
    final output = _rawResponse['output'] as List?;
    if (output == null) return null;

    final calls = <Map<String, dynamic>>[];

    for (final item in output) {
      if (item is! Map<String, dynamic>) continue;
      if (item['type'] != 'file_search_call') continue;

      final id = item['id'];
      final status = item['status'];
      final queries = item['queries'];
      final results = item['results'];

      final call = <String, dynamic>{
        if (id != null) 'id': id,
        if (status != null) 'status': status,
        if (queries is List) 'queries': queries,
        if (results is List || results == null) 'results': results,
      };

      if (call.isNotEmpty) {
        calls.add(call);
      }
    }

    return calls.isEmpty ? null : calls;
  }

  List<Map<String, dynamic>>? _extractComputerCalls() {
    final output = _rawResponse['output'] as List?;
    if (output == null) return null;

    final calls = <Map<String, dynamic>>[];

    for (final item in output) {
      if (item is! Map<String, dynamic>) continue;
      if (item['type'] != 'computer_call') continue;

      final id = item['id'];
      final status = item['status'];

      final call = <String, dynamic>{
        if (id != null) 'id': id,
        if (status != null) 'status': status,
      };

      if (call.isNotEmpty) {
        calls.add(call);
      }
    }

    return calls.isEmpty ? null : calls;
  }

  List<Map<String, dynamic>>? _extractWebSearchCalls() {
    final output = _rawResponse['output'] as List?;
    if (output == null) return null;

    final calls = <Map<String, dynamic>>[];

    for (final item in output) {
      if (item is! Map<String, dynamic>) continue;
      if (item['type'] != 'web_search_call') continue;

      final id = item['id'];
      final status = item['status'];

      final actionRaw = item['action'];
      Map<String, dynamic>? action;
      Object? sources;

      if (actionRaw is Map) {
        action = Map<String, dynamic>.from(actionRaw);
        sources = action.remove('sources') ?? item['sources'];

        final rawType = action['type'];
        if (rawType is String) {
          action['type'] = switch (rawType) {
            'open_page' => 'openPage',
            'find_in_page' => 'findInPage',
            _ => rawType,
          };
        }
      }

      final call = <String, dynamic>{
        if (id != null) 'id': id,
        if (status != null) 'status': status,
        if (action != null) 'action': action,
        if (sources != null) 'sources': sources,
      };

      if (call.isNotEmpty) {
        calls.add(call);
      }
    }

    return calls.isEmpty ? null : calls;
  }

  List<Map<String, dynamic>>? _extractOutputItemsByType(String expectedType) {
    final output = _rawResponse['output'] as List?;
    if (output == null) return null;

    final items = <Map<String, dynamic>>[];
    for (final item in output) {
      if (item is! Map<String, dynamic>) continue;
      if (item['type'] != expectedType) continue;
      items.add(Map<String, dynamic>.from(item));
    }

    return items.isEmpty ? null : items;
  }

  List<Map<String, dynamic>>? _extractServerToolCalls() {
    final output = _rawResponse['output'] as List?;
    if (output == null) return null;

    final calls = <Map<String, dynamic>>[];

    for (final item in output) {
      if (item is! Map<String, dynamic>) continue;
      final type = item['type'];
      if (type is! String) continue;

      // Messages and reasoning are handled separately; `function_call` is mapped
      // to `toolCalls`.
      if (type == 'message' || type == 'reasoning' || type == 'function_call') {
        continue;
      }

      // Keep the full item payload so provider-native tools (e.g. web search,
      // code interpreter, mcp) can be inspected without losing tool-specific
      // fields.
      calls.add(Map<String, dynamic>.from(item));
    }

    return calls.isEmpty ? null : calls;
  }

  List<dynamic>? _extractOutputTextAnnotations() {
    final output = _rawResponse['output'] as List?;
    final annotations = <dynamic>[];

    if (output != null) {
      for (final item in output) {
        if (item is! Map<String, dynamic>) continue;
        if (item['type'] != 'message') continue;

        final content = item['content'] as List?;
        if (content == null) continue;

        for (final contentItem in content) {
          if (contentItem is! Map<String, dynamic>) continue;
          if (contentItem['type'] != 'output_text') continue;

          final rawAnnotations = contentItem['annotations'] as List?;
          if (rawAnnotations == null || rawAnnotations.isEmpty) continue;
          annotations.addAll(rawAnnotations);
        }
      }
    }

    final streamAnnotations = _rawResponse['output_text_annotations'] as List?;
    if (streamAnnotations != null && streamAnnotations.isNotEmpty) {
      annotations.addAll(streamAnnotations);
    }

    return annotations.isEmpty ? null : annotations;
  }

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
                name: _toolNameMapping?.originalFunctionNameForRequestName(
                      item['name'] as String? ?? '',
                    ) ??
                    (item['name'] as String? ?? ''),
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

    return toolCalls.map((tc) {
      final toolCall = ToolCall.fromJson(tc as Map<String, dynamic>);
      final requestName = toolCall.function.name;
      final originalName =
          _toolNameMapping?.originalFunctionNameForRequestName(requestName) ??
              requestName;
      return ToolCall(
        id: toolCall.id,
        callType: toolCall.callType,
        function: FunctionCall(
          name: originalName,
          arguments: toolCall.function.arguments,
        ),
      );
    }).toList();
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
  Map<String, dynamic>? get providerMetadata {
    final id = _rawResponse['id'];
    final model = _rawResponse['model'];

    final serverToolCalls = _extractServerToolCalls();
    final fileSearchCalls = _extractFileSearchCalls();
    final computerCalls = _extractComputerCalls();
    final webSearchCalls = _extractWebSearchCalls();
    final annotations = _extractOutputTextAnnotations();

    final codeInterpreterCalls =
        _extractOutputItemsByType('code_interpreter_call');
    final imageGenerationCalls =
        _extractOutputItemsByType('image_generation_call');

    final mcpCalls = _extractOutputItemsByType('mcp_call');
    final mcpListTools = _extractOutputItemsByType('mcp_list_tools');
    final mcpApprovalRequests =
        _extractOutputItemsByType('mcp_approval_request');

    final shellCalls = _extractOutputItemsByType('shell_call');
    final shellCallOutputs = _extractOutputItemsByType('shell_call_output');

    final localShellCalls = _extractOutputItemsByType('local_shell_call');
    final localShellCallOutputs =
        _extractOutputItemsByType('local_shell_call_output');

    final applyPatchCalls = _extractOutputItemsByType('apply_patch_call');
    final applyPatchCallOutputs =
        _extractOutputItemsByType('apply_patch_call_output');

    if (id == null &&
        model == null &&
        serverToolCalls == null &&
        fileSearchCalls == null &&
        computerCalls == null &&
        webSearchCalls == null &&
        annotations == null &&
        codeInterpreterCalls == null &&
        imageGenerationCalls == null &&
        mcpCalls == null &&
        mcpListTools == null &&
        mcpApprovalRequests == null &&
        shellCalls == null &&
        shellCallOutputs == null &&
        localShellCalls == null &&
        localShellCallOutputs == null &&
        applyPatchCalls == null &&
        applyPatchCallOutputs == null) {
      return null;
    }

    return {
      'openai': {
        if (id != null) 'id': id,
        if (model != null) 'model': model,
        if (serverToolCalls != null) 'serverToolCalls': serverToolCalls,
        if (fileSearchCalls != null) 'fileSearchCalls': fileSearchCalls,
        if (computerCalls != null) 'computerCalls': computerCalls,
        if (webSearchCalls != null) 'webSearchCalls': webSearchCalls,
        if (annotations != null) 'annotations': annotations,
        if (codeInterpreterCalls != null)
          'codeInterpreterCalls': codeInterpreterCalls,
        if (imageGenerationCalls != null)
          'imageGenerationCalls': imageGenerationCalls,
        if (mcpCalls != null) 'mcpCalls': mcpCalls,
        if (mcpListTools != null) 'mcpListTools': mcpListTools,
        if (mcpApprovalRequests != null)
          'mcpApprovalRequests': mcpApprovalRequests,
        if (shellCalls != null) 'shellCalls': shellCalls,
        if (shellCallOutputs != null) 'shellCallOutputs': shellCallOutputs,
        if (localShellCalls != null) 'localShellCalls': localShellCalls,
        if (localShellCallOutputs != null)
          'localShellCallOutputs': localShellCallOutputs,
        if (applyPatchCalls != null) 'applyPatchCalls': applyPatchCalls,
        if (applyPatchCallOutputs != null)
          'applyPatchCallOutputs': applyPatchCallOutputs,
      },
    };
  }

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
