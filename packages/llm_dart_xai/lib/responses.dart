import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:llm_dart_openai_compatible/client.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

class _FunctionCallAccum {
  String? name;
  String arguments = '';
}

Map<String, dynamic> _stringKeyedMap(Map input) {
  return input.map<String, dynamic>((key, value) {
    return MapEntry(key.toString(), value);
  });
}

/// (Tier 3 / opt-in) xAI Responses API implementation (`POST /v1/responses`).
///
/// This mirrors the event stream shape used by the OpenAI Responses API
/// (`response.output_text.delta`, `response.reasoning_summary_text.delta`, etc),
/// but uses xAI's tool definition shapes (e.g. `tools: [{type: "web_search"}]`).
class XAIResponses
    implements
        ChatCapability,
        ChatStreamPartsCapability,
        PromptChatCapability,
        PromptChatStreamPartsCapability {
  final OpenAIClient client;
  final OpenAICompatibleConfig config;

  XAIResponses(this.client, this.config);

  String get responsesEndpoint => 'responses';

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  }) {
    return chatWithTools(messages, null, cancelToken: cancelToken);
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    final body = _buildRequestBody(
      messages: messages,
      tools: tools,
      stream: false,
    );
    final responseData = await client.postJson(
      responsesEndpoint,
      body,
      cancelToken: cancelToken,
    );
    return _parseResponse(responseData);
  }

  @override
  Future<ChatResponse> chatPrompt(
    Prompt prompt, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async {
    final body = _buildRequestBodyFromPrompt(
      prompt: prompt,
      tools: tools,
      stream: false,
    );
    final responseData = await client.postJson(
      responsesEndpoint,
      body,
      cancelToken: cancelToken,
    );
    return _parseResponse(responseData);
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async => null;

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async {
    final prompt = 'Summarize in 2-3 sentences:\n'
        '${messages.map((m) => '${m.role.name}: ${m.content}').join('\n')}';
    final response = await chat([ChatMessage.user(prompt)]);
    final text = response.text;
    if (text == null) {
      throw const GenericError('no text in summary response');
    }
    return text;
  }

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    final body = _buildRequestBody(
      messages: messages,
      tools: tools,
      stream: true,
    );
    yield* _chatStreamPartsFromBody(body, cancelToken: cancelToken);
  }

  @override
  Stream<LLMStreamPart> chatPromptStreamParts(
    Prompt prompt, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    final body = _buildRequestBodyFromPrompt(
      prompt: prompt,
      tools: tools,
      stream: true,
    );
    yield* _chatStreamPartsFromBody(body, cancelToken: cancelToken);
  }

  Stream<LLMStreamPart> _chatStreamPartsFromBody(
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) async* {
    client.resetSSEBuffer();
    var inText = false;
    var inThinking = false;
    var endedText = false;
    var endedThinking = false;

    final fullText = StringBuffer();
    final fullThinking = StringBuffer();
    final currentText = StringBuffer();
    final currentThinking = StringBuffer();

    String? currentTextBlockId;
    String? currentThinkingBlockId;
    var blockCounter = 0;

    final toolAccums = <String, _FunctionCallAccum>{};
    final startedToolCalls = <String>{};
    final endedToolCalls = <String>{};
    final activeProviderToolCalls = <String>{};
    final endedProviderToolCalls = <String>{};
    final providerToolTypeById = <String, String>{};
    final providerToolNameById = <String, String>{};
    final customToolInputById = <String, StringBuffer>{};

    String normalizeCustomToolName(String rawName) {
      const webSearchSubTools = {
        'web_search',
        'web_search_with_snippets',
        'browse_page',
      };

      const xSearchSubTools = {
        'x_user_search',
        'x_keyword_search',
        'x_semantic_search',
        'x_thread_fetch',
      };

      if (webSearchSubTools.contains(rawName)) return 'web_search';
      if (xSearchSubTools.contains(rawName)) return 'x_search';
      if (rawName == 'code_execution') return 'code_execution';
      if (rawName == 'view_image') return 'view_image';
      if (rawName == 'view_x_video') return 'view_x_video';
      return rawName;
    }

    Map<String, dynamic>? finalResponseObject;

    final serverToolCallsById = <String, Map<String, dynamic>>{};
    final sources = <String, Map<String, dynamic>>{};
    final sourceIdByUrl = <String, String>{};
    var nextSourceSeq = 0;

    String? responseId;
    String? responseModel;
    String? responseStatus;
    int? responseCreatedAtSeconds;
    var didEmitResponseMetadata = false;
    String? lastProviderMetadataJson;

    try {
      final stream = client.postStreamRaw(
        responsesEndpoint,
        body,
        cancelToken: cancelToken,
      );

      await for (final chunk in stream) {
        final jsonList = client.parseSSEChunk(chunk);
        if (jsonList.isEmpty) continue;

        for (final json in jsonList) {
          final eventType = json['type'] as String?;
          if (eventType == null || eventType.isEmpty) continue;

          if (eventType == 'response.created' ||
              eventType == 'response.in_progress') {
            final response = json['response'];
            if (response is Map) {
              final map = _stringKeyedMap(response);
              responseId ??= map['id'] as String?;
              responseModel ??= map['model'] as String?;
              responseStatus ??= map['status'] as String?;
              responseCreatedAtSeconds ??= map['created_at'] as int?;
            }
            if (!didEmitResponseMetadata &&
                (responseId != null ||
                    responseModel != null ||
                    responseStatus != null)) {
              didEmitResponseMetadata = true;
              final raw = <String, dynamic>{
                if (responseId != null) 'id': responseId,
                if (responseModel != null) 'model': responseModel,
                if (responseStatus != null) 'status': responseStatus,
                if (responseCreatedAtSeconds != null)
                  'created_at': responseCreatedAtSeconds,
              };
              yield LLMResponseMetadataPart(
                id: responseId,
                timestamp: responseCreatedAtSeconds == null
                    ? null
                    : DateTime.fromMillisecondsSinceEpoch(
                        responseCreatedAtSeconds * 1000,
                        isUtc: true,
                      ),
                model: responseModel,
                status: responseStatus,
                raw: raw.isEmpty ? null : raw,
              );
            }
            continue;
          }

          if (eventType.startsWith('response.')) {
            final segments = eventType.split('.');
            if (segments.length == 3) {
              final rawToolType = segments[1];
              final status = segments[2];
              if (rawToolType.endsWith('_call')) {
                final toolCallId = json['item_id']?.toString();
                if (toolCallId != null && toolCallId.isNotEmpty) {
                  providerToolTypeById[toolCallId] = rawToolType;
                  yield LLMProviderToolDeltaPart(
                    toolCallId: toolCallId,
                    toolName: rawToolType.substring(0, rawToolType.length - 5),
                    status: status,
                    data: _stringKeyedMap(json),
                    providerMetadata: {
                      config.providerId: {'type': eventType},
                    },
                  );
                }
              }
            }
          }

          if (eventType == 'response.custom_tool_call_input.delta') {
            final toolCallId = json['item_id']?.toString();
            final delta = json['delta'] as String?;
            if (toolCallId != null &&
                toolCallId.isNotEmpty &&
                delta != null &&
                delta.isNotEmpty) {
              final buffer = customToolInputById.putIfAbsent(
                toolCallId,
                StringBuffer.new,
              );
              buffer.write(delta);

              yield LLMProviderToolDeltaPart(
                toolCallId: toolCallId,
                toolName: providerToolNameById[toolCallId] ?? 'custom_tool',
                status: 'input_delta',
                data: _stringKeyedMap(json),
                providerMetadata: {
                  config.providerId: {'type': eventType},
                },
              );
            }
            continue;
          }

          if (eventType == 'response.custom_tool_call_input.done') {
            final toolCallId = json['item_id']?.toString();
            final input = json['input'] as String?;
            if (toolCallId != null && toolCallId.isNotEmpty) {
              if (input != null && input.isNotEmpty) {
                customToolInputById[toolCallId] = StringBuffer(input);
              }

              yield LLMProviderToolDeltaPart(
                toolCallId: toolCallId,
                toolName: providerToolNameById[toolCallId] ?? 'custom_tool',
                status: 'input_done',
                data: _stringKeyedMap(json),
                providerMetadata: {
                  config.providerId: {'type': eventType},
                },
              );
            }
            continue;
          }

          if (eventType == 'response.reasoning_summary_part.added') {
            if (!inThinking) {
              inThinking = true;
              currentThinkingBlockId ??= '${blockCounter++}';
              yield LLMReasoningStartPart(blockId: currentThinkingBlockId);
              currentThinking.clear();
            }
            continue;
          }

          if (eventType == 'response.output_text.delta') {
            final delta = json['delta'] as String?;
            if (delta == null || delta.isEmpty) continue;

            if (!inText) {
              inText = true;
              currentTextBlockId ??= '${blockCounter++}';
              yield LLMTextStartPart(blockId: currentTextBlockId);
              currentText.clear();
            }
            fullText.write(delta);
            currentText.write(delta);
            yield LLMTextDeltaPart(delta, blockId: currentTextBlockId);
            continue;
          }

          if (eventType == 'response.reasoning_summary_text.delta') {
            final delta = json['delta'] as String?;
            if (delta == null || delta.isEmpty) continue;

            if (!inThinking) {
              inThinking = true;
              currentThinkingBlockId ??= '${blockCounter++}';
              yield LLMReasoningStartPart(blockId: currentThinkingBlockId);
              currentThinking.clear();
            }
            fullThinking.write(delta);
            currentThinking.write(delta);
            yield LLMReasoningDeltaPart(delta, blockId: currentThinkingBlockId);
            continue;
          }

          if (eventType == 'response.reasoning_summary_text.done') {
            final text = json['text'] as String?;
            if (text != null && text.isNotEmpty) {
              fullThinking
                ..clear()
                ..write(text);
              currentThinking
                ..clear()
                ..write(text);
            }

            if (inThinking && !endedThinking) {
              endedThinking = true;
              yield LLMReasoningEndPart(
                fullThinking.toString(),
                blockId: currentThinkingBlockId,
              );
              inThinking = false;
              currentThinking.clear();
              currentThinkingBlockId = null;
            }
            continue;
          }

          if (eventType == 'response.output_text.done') {
            final text = json['text'] as String?;
            if (text != null && text.isNotEmpty) {
              fullText
                ..clear()
                ..write(text);
              currentText
                ..clear()
                ..write(text);
            }

            if (inText && !endedText) {
              endedText = true;
              yield LLMTextEndPart(
                fullText.toString(),
                blockId: currentTextBlockId,
              );
              inText = false;
              currentText.clear();
              currentTextBlockId = null;
            }
            continue;
          }

          if (eventType == 'response.output_text.annotation.added') {
            final annotation = json['annotation'];
            if (annotation is Map) {
              final a = _stringKeyedMap(annotation);
              if (a['type'] == 'url_citation') {
                final url = a['url'] as String?;
                if (url != null && url.isNotEmpty) {
                  final title = a['title'] as String?;
                  sources[url] = {
                    'type': 'url',
                    'url': url,
                    if (title != null && title.isNotEmpty) 'title': title,
                  };

                  final existingSourceId = sourceIdByUrl[url];
                  if (existingSourceId == null) {
                    final sourceId =
                        sourceIdByUrl[url] = 'source_${nextSourceSeq++}';

                    yield LLMSourceUrlPart(
                      sourceId: sourceId,
                      url: url,
                      title: title != null && title.isNotEmpty ? title : null,
                      providerMetadata: {
                        config.providerId: {
                          'type': 'url_citation',
                          if (a['start_index'] is int)
                            'startIndex': a['start_index'],
                          if (a['end_index'] is int) 'endIndex': a['end_index'],
                        },
                      },
                    );
                  }

                  final metadata = {
                    config.providerId: {
                      if (responseId != null) 'id': responseId,
                      if (responseModel != null) 'model': responseModel,
                      if (responseStatus != null) 'status': responseStatus,
                      'sources': sources.values.toList(growable: false),
                    },
                  };
                  final encoded = tryStableJsonEncode(metadata);
                  if (encoded == null || encoded != lastProviderMetadataJson) {
                    lastProviderMetadataJson = encoded;
                    yield LLMProviderMetadataPart(metadata);
                  }
                }
              }
            }
            continue;
          }

          if (eventType == 'response.output_item.added' ||
              eventType == 'response.output_item.done') {
            final item = json['item'] as Map<String, dynamic>?;
            if (item == null) continue;

            if (item['type'] == 'function_call') {
              final callId =
                  (item['call_id'] as String?) ?? (item['id'] as String?);
              if (callId == null || callId.isEmpty) continue;

              final name = item['name'] as String? ?? '';
              final args = item['arguments'] as String? ?? '';

              final accum = toolAccums.putIfAbsent(
                callId,
                () => _FunctionCallAccum(),
              );
              if (name.isNotEmpty) accum.name = name;
              if (args.isNotEmpty) accum.arguments = args;

              final toolCall = ToolCall(
                id: callId,
                callType: 'function',
                function: FunctionCall(
                  name: name.isNotEmpty ? name : (accum.name ?? ''),
                  arguments: args,
                ),
              );

              if (startedToolCalls.add(callId)) {
                yield LLMToolCallStartPart(toolCall);
              } else {
                yield LLMToolCallDeltaPart(toolCall);
              }

              if (eventType == 'response.output_item.done') {
                if (endedToolCalls.add(callId)) {
                  yield LLMToolCallEndPart(callId);
                }
              }
            }

            final type = item['type'];
            if (type is String &&
                (type.endsWith('_call') || type == 'custom_tool_call')) {
              final id = item['id']?.toString() ?? '';
              if (id.isNotEmpty) {
                final rawName = item['name'] as String? ?? '';
                final toolName = type == 'custom_tool_call'
                    ? (rawName.isNotEmpty
                        ? normalizeCustomToolName(rawName)
                        : 'custom_tool')
                    : (rawName.isNotEmpty
                        ? rawName
                        : type.substring(0, type.length - 5));
                providerToolTypeById[id] = type;
                providerToolNameById[id] = toolName;

                final input = type == 'custom_tool_call'
                    ? (item['input'] ?? customToolInputById[id]?.toString())
                    : (item['arguments'] ?? item['action']);

                if (eventType == 'response.output_item.added') {
                  if (activeProviderToolCalls.add(id)) {
                    yield LLMProviderToolCallPart(
                      toolCallId: id,
                      toolName: toolName,
                      input: input,
                      providerMetadata: {
                        config.providerId: {'type': type},
                      },
                    );
                  }
                } else if (eventType == 'response.output_item.done') {
                  if (!endedProviderToolCalls.add(id)) continue;

                  if (activeProviderToolCalls.add(id)) {
                    yield LLMProviderToolCallPart(
                      toolCallId: id,
                      toolName: toolName,
                      input: input,
                      providerMetadata: {
                        config.providerId: {'type': type},
                      },
                    );
                  }

                  yield LLMProviderToolResultPart(
                    toolCallId: id,
                    toolName: toolName,
                    result: _stringKeyedMap(item),
                    providerMetadata: {
                      config.providerId: {
                        'type': type,
                        if (item['status'] is String) 'status': item['status'],
                      },
                    },
                  );

                  activeProviderToolCalls.remove(id);
                }

                serverToolCallsById[id] = _stringKeyedMap(item);
                if (eventType == 'response.output_item.done') {
                  final metadata = {
                    config.providerId: {
                      if (responseId != null) 'id': responseId,
                      if (responseModel != null) 'model': responseModel,
                      if (responseStatus != null) 'status': responseStatus,
                      'serverToolCalls': serverToolCallsById.values.toList(
                        growable: false,
                      ),
                    },
                  };
                  final encoded = tryStableJsonEncode(metadata);
                  if (encoded == null || encoded != lastProviderMetadataJson) {
                    lastProviderMetadataJson = encoded;
                    yield LLMProviderMetadataPart(metadata);
                  }
                }
              }
            }

            continue;
          }

          if (eventType == 'response.completed' ||
              eventType == 'response.done') {
            final rawResponse = json['response'];
            if (rawResponse is Map<String, dynamic>) {
              finalResponseObject = rawResponse;
            } else if (rawResponse is Map) {
              finalResponseObject = Map<String, dynamic>.from(rawResponse);
            }

            if (finalResponseObject != null) {
              responseId ??= finalResponseObject['id'] as String?;
              responseModel ??= finalResponseObject['model'] as String?;
              responseStatus ??= finalResponseObject['status'] as String?;
              responseCreatedAtSeconds ??=
                  finalResponseObject['created_at'] as int?;

              if (!didEmitResponseMetadata &&
                  (responseId != null ||
                      responseModel != null ||
                      responseStatus != null)) {
                didEmitResponseMetadata = true;
                final raw = <String, dynamic>{
                  if (responseId != null) 'id': responseId,
                  if (responseModel != null) 'model': responseModel,
                  if (responseStatus != null) 'status': responseStatus,
                  if (responseCreatedAtSeconds != null)
                    'created_at': responseCreatedAtSeconds,
                };
                yield LLMResponseMetadataPart(
                  id: responseId,
                  timestamp: responseCreatedAtSeconds == null
                      ? null
                      : DateTime.fromMillisecondsSinceEpoch(
                          responseCreatedAtSeconds * 1000,
                          isUtc: true,
                        ),
                  model: responseModel,
                  status: responseStatus,
                  raw: raw.isEmpty ? null : raw,
                );
              }
            }

            final parsed = finalResponseObject == null
                ? null
                : _parseResponse(finalResponseObject);

            final finishText = fullText.isNotEmpty
                ? fullText.toString()
                : (parsed?.text ?? '');
            final finishThinking = fullThinking.isNotEmpty
                ? fullThinking.toString()
                : (parsed?.thinking ?? '');

            if (inText && !endedText) {
              endedText = true;
              yield LLMTextEndPart(finishText, blockId: currentTextBlockId);
              inText = false;
              currentText.clear();
              currentTextBlockId = null;
            }
            if (inThinking && !endedThinking) {
              endedThinking = true;
              yield LLMReasoningEndPart(
                finishThinking,
                blockId: currentThinkingBlockId,
              );
              inThinking = false;
              currentThinking.clear();
              currentThinkingBlockId = null;
            }

            for (final toolCallId in startedToolCalls) {
              if (endedToolCalls.add(toolCallId)) {
                yield LLMToolCallEndPart(toolCallId);
              }
            }

            final response = parsed ??
                XAIResponsesChatResponse(
                  providerId: config.providerId,
                  text: finishText,
                  thinking: finishThinking.isNotEmpty ? finishThinking : null,
                );

            final metadata = response.providerMetadata;
            if (metadata != null && metadata.isNotEmpty) {
              final encoded = tryStableJsonEncode(metadata);
              if (encoded == null || encoded != lastProviderMetadataJson) {
                lastProviderMetadataJson = encoded;
                yield LLMProviderMetadataPart(metadata);
              }
            }

            final finishReason =
                response is ChatResponseWithFinishReason
                    ? response.finishReason
                    : null;
            yield LLMFinishPart(
              response,
              usage: response.usage,
              finishReason: finishReason,
            );
            return;
          }
        }
      }

      final response = XAIResponsesChatResponse(
        providerId: config.providerId,
        text: fullText.toString(),
        thinking: fullThinking.isNotEmpty ? fullThinking.toString() : null,
      );
      final metadata = response.providerMetadata;
      if (metadata != null && metadata.isNotEmpty) {
        final encoded = tryStableJsonEncode(metadata);
        if (encoded == null || encoded != lastProviderMetadataJson) {
          lastProviderMetadataJson = encoded;
          yield LLMProviderMetadataPart(metadata);
        }
      }
      yield LLMFinishPart(
        response,
        usage: response.usage,
        finishReason: response.finishReason,
      );
    } catch (e) {
      if (e is LLMError) {
        yield LLMErrorPart(e);
        return;
      }
      yield LLMErrorPart(GenericError('Stream error: $e'));
      return;
    } finally {
      client.resetSSEBuffer();
    }
  }

  Map<String, dynamic> _buildRequestBody({
    required List<ChatMessage> messages,
    required List<Tool>? tools,
    required bool stream,
  }) {
    final input = _buildInputMessages(messages);
    return _buildRequestBodyFromInput(
      input: input,
      tools: tools,
      stream: stream,
    );
  }

  Map<String, dynamic> _buildRequestBodyFromPrompt({
    required Prompt prompt,
    required List<Tool>? tools,
    required bool stream,
  }) {
    final input = _buildInputMessagesFromPrompt(prompt);
    return _buildRequestBodyFromInput(
      input: input,
      tools: tools,
      stream: stream,
    );
  }

  Map<String, dynamic> _buildRequestBodyFromInput({
    required List<Map<String, dynamic>> input,
    required List<Tool>? tools,
    required bool stream,
  }) {
    final effectiveTools = tools ?? config.tools;

    final body = <String, dynamic>{
      'model': config.model,
      'input': input,
      'stream': stream,
    };

    if (config.maxTokens != null) {
      body['max_output_tokens'] = config.maxTokens;
    }
    if (config.temperature != null) {
      body['temperature'] = config.temperature;
    }
    if (config.topP != null) body['top_p'] = config.topP;
    if (config.topK != null) body['top_k'] = config.topK;

    if (config.reasoningEffort != null) {
      body['reasoning'] = {'effort': config.reasoningEffort!.value};
    }

    final previousResponseId =
        config.getProviderOption<String>('previousResponseId') ??
            config.getProviderOption<String>('previous_response_id');
    if (previousResponseId != null && previousResponseId.isNotEmpty) {
      body['previous_response_id'] = previousResponseId;
    }

    final store = config.getProviderOption<bool>('store');
    if (store != null) {
      body['store'] = store;
    }

    final toolsJson = <Map<String, dynamic>>[];

    final providerTools = config.originalConfig?.providerTools;
    if (providerTools != null && providerTools.isNotEmpty) {
      toolsJson.addAll(providerTools.map(_convertProviderTool));
    }

    if (effectiveTools != null && effectiveTools.isNotEmpty) {
      toolsJson.addAll(effectiveTools.map(_convertFunctionTool));
    }

    if (toolsJson.isNotEmpty) {
      body['tools'] = toolsJson;

      final toolChoice = config.toolChoice;
      if (toolChoice != null) {
        body['tool_choice'] = _convertToolChoice(toolChoice);
      }
    }

    final parallelToolCalls = config.getProviderOption<bool>(
      'parallelToolCalls',
    );
    if (parallelToolCalls != null) {
      body['parallel_tool_calls'] = parallelToolCalls;
    }

    final extraBodyFromConfig = config.extraBody;
    if (extraBodyFromConfig != null && extraBodyFromConfig.isNotEmpty) {
      body.addAll(extraBodyFromConfig);
    }

    return body;
  }

  List<Map<String, dynamic>> _buildInputMessages(List<ChatMessage> messages) {
    final input = <Map<String, dynamic>>[];
    var hasSystemMessage = false;

    for (final message in messages) {
      if (message.role == ChatRole.system) {
        hasSystemMessage = true;
      }

      switch (message.messageType) {
        case TextMessage():
          input.add({
            'role': switch (message.role) {
              ChatRole.system => 'system',
              ChatRole.user => 'user',
              ChatRole.assistant => 'assistant',
            },
            'content': message.content,
          });
          break;

        case ToolUseMessage(toolCalls: final calls):
          for (final call in calls) {
            input.add({
              'type': 'function_call',
              'id': call.id,
              'call_id': call.id,
              'name': call.function.name,
              'arguments': call.function.arguments,
              'status': 'completed',
            });
          }
          break;

        case ToolResultMessage(results: final results):
          for (final result in results) {
            input.add({
              'type': 'function_call_output',
              'call_id': result.id,
              'output': message.content.isNotEmpty
                  ? message.content
                  : (result.function.arguments.isNotEmpty
                      ? result.function.arguments
                      : 'Tool result'),
            });
          }
          break;

        default:
          throw UnsupportedError(
            'xAI Responses API does not support ${message.messageType.runtimeType} messages',
          );
      }
    }

    if (!hasSystemMessage && config.systemPrompt != null) {
      input.insert(0, {'role': 'system', 'content': config.systemPrompt});
    }

    return input;
  }

  List<Map<String, dynamic>> _buildInputMessagesFromPrompt(Prompt prompt) {
    final input = <Map<String, dynamic>>[];
    var hasSystemMessage = false;

    String? currentRole;
    final currentText = StringBuffer();

    void flushText() {
      final role = currentRole;
      if (role == null) return;
      final text = currentText.toString();
      if (text.trim().isNotEmpty) {
        input.add({'role': role, 'content': text});
      }
      currentRole = null;
      currentText.clear();
    }

    void ensureRole(String role) {
      if (currentRole == role) return;
      flushText();
      currentRole = role;
    }

    for (final message in prompt.messages) {
      if (message.role == ChatRole.system) {
        hasSystemMessage = true;
      }

      for (final part in message.parts) {
        ChatRole effectiveRole;
        if (part case ToolCallPart(:final overrideRole)) {
          effectiveRole = overrideRole ?? message.role;
        } else if (part case ToolResultPart(:final overrideRole)) {
          effectiveRole = overrideRole ?? message.role;
        } else {
          effectiveRole = message.role;
        }

        if (effectiveRole == ChatRole.system) {
          if (part case TextPart(:final text)) {
            ensureRole('system');
            if (currentText.isNotEmpty) currentText.write('\n\n');
            currentText.write(text);
            continue;
          }
          throw UnsupportedError(
            'xAI Responses API does not support ${part.runtimeType} in system messages',
          );
        }

        if (part case ToolCallPart(:final toolCall)) {
          if (effectiveRole != ChatRole.assistant) {
            throw const InvalidRequestError(
              'ToolCallPart must be emitted from an assistant message.',
            );
          }
          flushText();
          input.add({
            'type': 'function_call',
            'id': toolCall.id,
            'call_id': toolCall.id,
            'name': toolCall.function.name,
            'arguments': toolCall.function.arguments,
            'status': 'completed',
          });
          continue;
        }

        if (part case ToolResultPart(:final toolResult)) {
          if (effectiveRole != ChatRole.user) {
            throw const InvalidRequestError(
              'ToolResultPart must be emitted from a user message.',
            );
          }
          flushText();
          input.add({
            'type': 'function_call_output',
            'call_id': toolResult.id,
            'output': toolResult.function.arguments.isNotEmpty
                ? toolResult.function.arguments
                : 'Tool result',
          });
          continue;
        }

        if (part case TextPart(:final text)) {
          ensureRole(effectiveRole == ChatRole.user ? 'user' : 'assistant');
          if (currentText.isNotEmpty) currentText.write('\n\n');
          currentText.write(text);
          continue;
        }

        throw UnsupportedError(
          'xAI Responses API does not support ${part.runtimeType} parts',
        );
      }

      flushText();
    }

    if (!hasSystemMessage && config.systemPrompt != null) {
      input.insert(0, {'role': 'system', 'content': config.systemPrompt});
    }

    return input;
  }

  Map<String, dynamic> _convertFunctionTool(Tool tool) {
    return {
      'type': 'function',
      'function': {
        'name': tool.function.name,
        'description': tool.function.description,
        'parameters': tool.function.parameters.toJson(),
      },
    };
  }

  Map<String, dynamic> _convertProviderTool(ProviderTool tool) {
    final rawId = tool.id;
    final id = rawId.startsWith('xai.') ? rawId.substring(4) : rawId;

    Map<String, dynamic> applyOptions(Map<String, dynamic> base) {
      if (tool.options.isEmpty) return base;
      return {...base, ..._normalizeXaiToolOptions(tool.options)};
    }

    return switch (id) {
      'web_search' => applyOptions({'type': 'web_search'}),
      'x_search' => applyOptions({'type': 'x_search'}),
      'code_execution' => applyOptions({'type': 'code_interpreter'}),
      'view_image' => applyOptions({'type': 'view_image'}),
      'view_x_video' => applyOptions({'type': 'view_x_video'}),
      'file_search' => applyOptions({'type': 'file_search'}),
      'mcp' => applyOptions({'type': 'mcp'}),
      _ => applyOptions({'type': id}),
    };
  }

  Map<String, dynamic> _normalizeXaiToolOptions(Map<String, dynamic> options) {
    final out = <String, dynamic>{};

    void mapKey(String from, String to) {
      if (!options.containsKey(from)) return;
      out[to] = options[from];
    }

    mapKey('allowedDomains', 'allowed_domains');
    mapKey('excludedDomains', 'excluded_domains');
    mapKey('enableImageUnderstanding', 'enable_image_understanding');

    mapKey('allowedXHandles', 'allowed_x_handles');
    mapKey('excludedXHandles', 'excluded_x_handles');
    mapKey('fromDate', 'from_date');
    mapKey('toDate', 'to_date');
    mapKey('enableVideoUnderstanding', 'enable_video_understanding');

    mapKey('vectorStoreIds', 'vector_store_ids');
    mapKey('maxNumResults', 'max_num_results');

    mapKey('serverUrl', 'server_url');
    mapKey('serverLabel', 'server_label');
    mapKey('serverDescription', 'server_description');
    mapKey('allowedTools', 'allowed_tools');

    // xAI MCP tool uses non-snake keys for these fields.
    mapKey('headers', 'headers');
    mapKey('authorization', 'authorization');

    // Pass through already-snake_case keys.
    for (final entry in options.entries) {
      final k = entry.key;
      if (!k.contains('_')) continue;
      out[k] = entry.value;
    }

    return out;
  }

  dynamic _convertToolChoice(ToolChoice choice) {
    return switch (choice) {
      AutoToolChoice() => 'auto',
      NoneToolChoice() => 'none',
      AnyToolChoice() => 'required',
      SpecificToolChoice(toolName: final name) => {
          'type': 'function',
          'name': name,
        },
    };
  }

  ChatResponse _parseResponse(Map<String, dynamic> responseData) {
    final output = responseData['output'] as List?;

    final text = StringBuffer();
    final thinking = StringBuffer();
    final toolCalls = <ToolCall>[];

    final serverToolCalls = <Map<String, dynamic>>[];
    final sources = <Map<String, dynamic>>[];

    if (output != null) {
      for (final item in output) {
        if (item is! Map) continue;
        final type = item['type'];

        if (type == 'message') {
          final content = item['content'];
          if (content is List) {
            for (final part in content) {
              if (part is! Map) continue;
              if (part['type'] != 'output_text') continue;
              final t = part['text'];
              if (t is String) text.write(t);

              final annotations = part['annotations'];
              if (annotations is List) {
                for (final a in annotations) {
                  if (a is! Map) continue;
                  if (a['type'] != 'url_citation') continue;
                  final url = a['url'];
                  if (url is! String || url.isEmpty) continue;
                  final title = a['title'];
                  sources.add({
                    'type': 'url',
                    'url': url,
                    if (title is String && title.isNotEmpty) 'title': title,
                  });
                }
              }
            }
          }
          continue;
        }

        if (type == 'reasoning') {
          final summary = item['summary'];
          if (summary is List) {
            for (final part in summary) {
              if (part is! Map) continue;
              if (part['type'] != 'summary_text') continue;
              final t = part['text'];
              if (t is String) thinking.write(t);
            }
          }
          continue;
        }

        if (type == 'function_call') {
          final callId =
              (item['call_id'] as String?) ?? (item['id'] as String?);
          final name = item['name'] as String? ?? '';
          final args = item['arguments'] as String? ?? '';
          if (callId == null || callId.isEmpty || name.isEmpty) continue;

          toolCalls.add(
            ToolCall(
              id: callId,
              callType: 'function',
              function: FunctionCall(name: name, arguments: args),
            ),
          );
          continue;
        }

        if (type is String &&
            (type.endsWith('_call') || type == 'custom_tool_call')) {
          serverToolCalls.add(_stringKeyedMap(item));
        }
      }
    }

    final usageRaw = responseData['usage'];
    UsageInfo? usage;
    if (usageRaw is Map) {
      final usageMap = usageRaw.cast<String, dynamic>();
      final inputTokens = usageMap['input_tokens'] as int?;
      final outputTokens = usageMap['output_tokens'] as int?;
      final totalTokens = usageMap['total_tokens'] as int? ??
          ((inputTokens ?? 0) + (outputTokens ?? 0));

      final outputDetails = usageMap['output_tokens_details'];
      final reasoningTokens = outputDetails is Map
          ? (outputDetails['reasoning_tokens'] as int?)
          : null;

      usage = UsageInfo(
        promptTokens: inputTokens,
        completionTokens: outputTokens,
        totalTokens: totalTokens,
        reasoningTokens: reasoningTokens,
      );
    }

    final id = responseData['id'] as String?;
    final model = responseData['model'] as String?;
    final status = responseData['status'] as String?;

    return XAIResponsesChatResponse(
      providerId: config.providerId,
      text: text.toString(),
      thinking: thinking.isNotEmpty ? thinking.toString() : null,
      toolCalls: toolCalls.isNotEmpty ? toolCalls : null,
      usage: usage,
      responseId: id,
      model: model,
      status: status,
      serverToolCalls: serverToolCalls.isNotEmpty ? serverToolCalls : null,
      sources: sources.isNotEmpty ? sources : null,
    );
  }
}

class XAIResponsesChatResponse implements ChatResponseWithFinishReason {
  final String providerId;
  @override
  final String? text;
  @override
  final String? thinking;
  @override
  final List<ToolCall>? toolCalls;
  @override
  final UsageInfo? usage;

  final String? responseId;
  final String? model;
  final String? status;
  final List<Map<String, dynamic>>? serverToolCalls;
  final List<Map<String, dynamic>>? sources;

  XAIResponsesChatResponse({
    required this.providerId,
    required this.text,
    this.thinking,
    this.toolCalls,
    this.usage,
    this.responseId,
    this.model,
    this.status,
    this.serverToolCalls,
    this.sources,
  });

  @override
  LLMFinishReason? get finishReason {
    final st = status;
    if (st == null || st.isEmpty) return null;

    if (st == 'failed' || st == 'cancelled') {
      return LLMFinishReason(unified: LLMUnifiedFinishReason.error, raw: st);
    }

    if (st == 'incomplete') {
      return LLMFinishReason(unified: LLMUnifiedFinishReason.other, raw: st);
    }

    if (toolCalls != null && toolCalls!.isNotEmpty) {
      return const LLMFinishReason(
        unified: LLMUnifiedFinishReason.toolCalls,
        raw: 'tool_calls',
      );
    }

    return LLMFinishReason(unified: LLMUnifiedFinishReason.stop, raw: st);
  }

  @override
  Map<String, dynamic>? get providerMetadata => {
        providerId: {
          if (responseId != null) 'id': responseId,
          if (model != null) 'model': model,
          if (status != null) 'status': status,
          if (serverToolCalls != null) 'serverToolCalls': serverToolCalls,
          if (sources != null) 'sources': sources,
        },
      };
}
