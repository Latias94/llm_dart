import 'dart:async';
import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:llm_dart_openai_compatible/client.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:llm_dart_provider_utils/utils/request_metadata_sanitizer.dart';

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
        ModelIdentityCapability,
        ChatStreamPartsCapability,
        ChatStreamPartsCallOptionsCapability,
        PromptChatCapability,
        PromptChatStreamPartsCapability,
        ChatCallOptionsCapability,
        PromptChatCallOptionsCapability,
        PromptChatStreamPartsCallOptionsCapability {
  final OpenAIClient client;
  final OpenAICompatibleConfig config;

  XAIResponses(this.client, this.config);

  @override
  String get providerId => config.providerId;

  @override
  String get modelId => config.model;

  String get responsesEndpoint => 'responses';

  bool _emitRequestMetadataEnabled() {
    return config.getProviderOption<bool>('emitRequestMetadata') ?? false;
  }

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) {
    return chatWithTools(
      messages,
      null,
      providerTools: providerTools,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) async {
    return chatWithToolsWithCallOptions(
      messages,
      tools,
      providerTools: providerTools,
      callOptions: const LLMCallOptions(),
      cancelToken: cancelToken,
    );
  }

  @override
  Future<ChatResponse> chatWithToolsWithCallOptions(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    List<ProviderTool>? providerTools,
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) async {
    final requestProviderTools = mergeProviderToolsById(
      config.originalConfig?.providerTools,
      providerTools,
    );
    final built = _buildRequestBody(
      messages: messages,
      tools: tools,
      stream: false,
      providerTools: requestProviderTools,
    );
    var body = Map<String, dynamic>.from(built.body);
    body = callOptions.mergeIntoRequestBody(body);
    final requestMetadata = _emitRequestMetadataEnabled()
        ? LLMRequestMetadataPart(body: sanitizeRequestBodyForMetadata(body))
        : null;
    final responseWithHeaders = await client.postJsonWithHeaders(
      responsesEndpoint,
      body,
      headers: callOptions.headers,
      cancelToken: cancelToken,
    );
    return _parseResponse(
      responseWithHeaders.json,
      responseHeaders: responseWithHeaders.headers,
      requestMetadata: requestMetadata,
      requestWarnings: built.warnings,
    );
  }

  @override
  Future<ChatResponse> chatPrompt(
    Prompt prompt, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async {
    return chatPromptWithCallOptions(
      prompt,
      providerTools: providerTools,
      tools: tools,
      callOptions: const LLMCallOptions(),
      cancelToken: cancelToken,
    );
  }

  @override
  Future<ChatResponse> chatPromptWithCallOptions(
    Prompt prompt, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) async {
    final requestProviderTools = mergeProviderToolsById(
      config.originalConfig?.providerTools,
      providerTools,
    );
    final built = _buildRequestBodyFromPrompt(
      prompt: prompt,
      tools: tools,
      stream: false,
      providerTools: requestProviderTools,
    );
    var body = Map<String, dynamic>.from(built.body);
    body = callOptions.mergeIntoRequestBody(body);
    final requestMetadata = _emitRequestMetadataEnabled()
        ? LLMRequestMetadataPart(body: sanitizeRequestBodyForMetadata(body))
        : null;
    final responseWithHeaders = await client.postJsonWithHeaders(
      responsesEndpoint,
      body,
      headers: callOptions.headers,
      cancelToken: cancelToken,
    );
    return _parseResponse(
      responseWithHeaders.json,
      responseHeaders: responseWithHeaders.headers,
      requestMetadata: requestMetadata,
      requestWarnings: built.warnings,
    );
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
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    yield* chatStreamPartsWithCallOptions(
      messages,
      providerTools: providerTools,
      tools: tools,
      callOptions: const LLMCallOptions(),
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<LLMStreamPart> chatStreamPartsWithCallOptions(
    List<ChatMessage> messages, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) async* {
    final requestProviderTools = mergeProviderToolsById(
      config.originalConfig?.providerTools,
      providerTools,
    );
    final built = _buildRequestBody(
      messages: messages,
      tools: tools,
      stream: true,
      providerTools: requestProviderTools,
    );
    yield LLMStreamStartPart(warnings: built.warnings);
    var body = Map<String, dynamic>.from(built.body);
    body = callOptions.mergeIntoRequestBody(body);
    if (_emitRequestMetadataEnabled()) {
      yield LLMRequestMetadataPart(
        body: sanitizeRequestBodyForMetadata(body),
      );
    }
    yield* _chatStreamPartsFromBody(
      body,
      requestProviderTools: requestProviderTools,
      headers: callOptions.headers,
      requestWarnings: built.warnings,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<LLMStreamPart> chatPromptStreamParts(
    Prompt prompt, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    yield* chatPromptStreamPartsWithCallOptions(
      prompt,
      providerTools: providerTools,
      tools: tools,
      callOptions: const LLMCallOptions(),
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<LLMStreamPart> chatPromptStreamPartsWithCallOptions(
    Prompt prompt, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) async* {
    final requestProviderTools = mergeProviderToolsById(
      config.originalConfig?.providerTools,
      providerTools,
    );
    final built = _buildRequestBodyFromPrompt(
      prompt: prompt,
      tools: tools,
      stream: true,
      providerTools: requestProviderTools,
    );
    yield LLMStreamStartPart(warnings: built.warnings);
    var body = Map<String, dynamic>.from(built.body);
    body = callOptions.mergeIntoRequestBody(body);
    if (_emitRequestMetadataEnabled()) {
      yield LLMRequestMetadataPart(
        body: sanitizeRequestBodyForMetadata(body),
      );
    }
    yield* _chatStreamPartsFromBody(
      body,
      requestProviderTools: requestProviderTools,
      headers: callOptions.headers,
      requestWarnings: built.warnings,
      cancelToken: cancelToken,
    );
  }

  Stream<LLMStreamPart> _chatStreamPartsFromBody(
    Map<String, dynamic> body, {
    List<ProviderTool>? requestProviderTools,
    Map<String, String>? headers,
    List<LLMWarning> requestWarnings = const <LLMWarning>[],
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
    final providerToolParts = ProviderToolPartEmitter(
      providerMetadataNamespace: config.providerId,
    );
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
    final sourceParts = SourcePartEmitter(
      providerMetadataNamespace: config.providerId,
    );

    String? responseId;
    String? responseModel;
    String? responseStatus;
    int? responseCreatedAtSeconds;
    var didEmitResponseMetadata = false;
    String? lastProviderMetadataJson;
    Map<String, dynamic>? lastStreamChunk;

    try {
      final streamed = await client.postStreamRawWithHeaders(
        responsesEndpoint,
        body,
        headers: headers,
        cancelToken: cancelToken,
      );
      final responseHeaders = streamed.headers;
      final stream = streamed.stream;

      await for (final chunk in stream) {
        final jsonList = client.parseSSEChunk(chunk);
        if (jsonList.isEmpty) continue;

        for (final json in jsonList) {
          lastStreamChunk = json;
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
                headers: responseHeaders.isEmpty ? null : responseHeaders,
                status: responseStatus,
                raw: raw.isEmpty ? null : raw,
              );
            }
            continue;
          }

          final toolDelta = parseResponsesToolDeltaEvent(
            eventType: eventType,
            json: _stringKeyedMap(json),
          );
          if (toolDelta != null) {
            providerToolTypeById[toolDelta.toolCallId] = toolDelta.rawToolType;
            yield providerToolDeltaPartFromResponsesEvent(
              providerId: config.providerId,
              event: toolDelta,
              providerTools: requestProviderTools,
              data: _stringKeyedMap(json),
              providerMetadataPayload: {'type': eventType},
            );
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
                toolName: resolveProviderToolName(
                  providerId: config.providerId,
                  rawToolName:
                      providerToolNameById[toolCallId] ?? 'custom_tool',
                  providerTools: requestProviderTools,
                ),
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
                toolName: resolveProviderToolName(
                  providerId: config.providerId,
                  rawToolName:
                      providerToolNameById[toolCallId] ?? 'custom_tool',
                  providerTools: requestProviderTools,
                ),
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

                  final part = sourceParts.url(
                    url,
                    title: title != null && title.isNotEmpty ? title : null,
                    providerMetadataPayload: {
                      'type': 'url_citation',
                      if (a['start_index'] is int)
                        'startIndex': a['start_index'],
                      if (a['end_index'] is int) 'endIndex': a['end_index'],
                    },
                  );
                  if (part != null) yield part;

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
                final toolType = type == 'custom_tool_call'
                    ? null
                    : type.substring(0, type.length - 5);

                final rawToolName = type == 'custom_tool_call'
                    ? (rawName.isNotEmpty
                        ? normalizeCustomToolName(rawName)
                        : 'custom_tool')
                    : (rawName.isNotEmpty ? rawName : toolType!);

                final toolName = resolveProviderToolName(
                  providerId: config.providerId,
                  rawToolName: rawToolName,
                  providerTools: requestProviderTools,
                );
                providerToolTypeById[id] = type;
                providerToolNameById[id] = toolName;

                final input = type == 'custom_tool_call'
                    ? (item['input'] ?? customToolInputById[id]?.toString())
                    : (item['arguments'] ?? item['action']);

                final providerTool = findProviderToolByRawName(
                  providerId: config.providerId,
                  rawToolName: rawToolName,
                  providerTools: requestProviderTools,
                );
                final supportsDeferredResults =
                    providerTool?.supportsDeferredResults == true ? true : null;

                if (eventType == 'response.output_item.added') {
                  final part = providerToolParts.call(
                    toolCallId: id,
                    toolName: toolName,
                    input: input,
                    providerExecuted: true,
                    supportsDeferredResults: supportsDeferredResults,
                    providerMetadataPayload: {'type': type},
                  );
                  if (part != null) yield part;
                } else if (eventType == 'response.output_item.done') {
                  final callPart = providerToolParts.call(
                    toolCallId: id,
                    toolName: toolName,
                    input: input,
                    providerExecuted: true,
                    supportsDeferredResults: supportsDeferredResults,
                    providerMetadataPayload: {'type': type},
                  );
                  if (callPart != null) yield callPart;

                  final resultPart = providerToolParts.result(
                    toolCallId: id,
                    toolName: toolName,
                    result: _stringKeyedMap(item),
                    providerMetadataPayload: {
                      'type': type,
                      if (item['status'] is String) 'status': item['status'],
                    },
                  );
                  if (resultPart != null) yield resultPart;
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
                  headers: responseHeaders.isEmpty ? null : responseHeaders,
                  status: responseStatus,
                  raw: raw.isEmpty ? null : raw,
                );
              }
            }

            final parsed = finalResponseObject == null
                ? null
                : _parseResponse(
                    finalResponseObject,
                    requestWarnings: requestWarnings,
                  );

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
                  warnings: requestWarnings,
                );

            final metadata = response.providerMetadata;
            if (metadata != null && metadata.isNotEmpty) {
              final encoded = tryStableJsonEncode(metadata);
              if (encoded == null || encoded != lastProviderMetadataJson) {
                lastProviderMetadataJson = encoded;
                yield LLMProviderMetadataPart(metadata);
              }
            }

            final finishReason = response is ChatResponseWithFinishReason
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
        warnings: requestWarnings,
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
      yield LLMErrorPart(
        InvalidStreamPartError(
          chunk: lastStreamChunk ?? const <String, dynamic>{},
          message: 'Stream part decode error: $e',
        ),
      );
      return;
    } finally {
      client.resetSSEBuffer();
    }
  }

  ({Map<String, dynamic> body, List<LLMWarning> warnings}) _buildRequestBody({
    required List<ChatMessage> messages,
    required List<Tool>? tools,
    required bool stream,
    List<ProviderTool>? providerTools,
  }) {
    final built = _buildInputMessages(messages);
    return (
      body: _buildRequestBodyFromInput(
        input: built.input,
        tools: tools,
        stream: stream,
        providerTools: providerTools,
      ),
      warnings: built.warnings,
    );
  }

  ({Map<String, dynamic> body, List<LLMWarning> warnings})
      _buildRequestBodyFromPrompt({
    required Prompt prompt,
    required List<Tool>? tools,
    required bool stream,
    List<ProviderTool>? providerTools,
  }) {
    final built = _buildInputMessagesFromPrompt(prompt);
    return (
      body: _buildRequestBodyFromInput(
        input: built.input,
        tools: tools,
        stream: stream,
        providerTools: providerTools,
      ),
      warnings: built.warnings,
    );
  }

  Map<String, dynamic> _buildRequestBodyFromInput({
    required List<Map<String, dynamic>> input,
    required List<Tool>? tools,
    required bool stream,
    List<ProviderTool>? providerTools,
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

    final effectiveProviderTools =
        providerTools ?? config.originalConfig?.providerTools;
    if (effectiveProviderTools != null && effectiveProviderTools.isNotEmpty) {
      toolsJson.addAll(effectiveProviderTools.map(_convertProviderTool));
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

  ({List<Map<String, dynamic>> input, List<LLMWarning> warnings})
      _buildInputMessages(List<ChatMessage> messages) {
    final input = <Map<String, dynamic>>[];
    var hasSystemMessage = false;
    var mappedToolRoleToUser = false;

    for (final message in messages) {
      if (message.role == ChatRole.system) {
        hasSystemMessage = true;
      }

      switch (message.messageType) {
        case TextMessage():
          if (message.role == ChatRole.tool) mappedToolRoleToUser = true;
          input.add({
            'role': switch (message.role) {
              ChatRole.system => 'system',
              ChatRole.user => 'user',
              ChatRole.assistant => 'assistant',
              // xAI Responses API does not support a dedicated `tool` role for
              // plain text items. Tool outputs should be sent as
              // `function_call_output` items (ToolResultMessage).
              ChatRole.tool => 'user',
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

    final warnings = <LLMWarning>[];
    if (mappedToolRoleToUser) {
      warnings.add(
        const LLMCompatibilityWarning(
          feature: 'tool role mapped to user',
          details:
              'xAI Responses API does not support a dedicated `tool` role for plain text items. Tool-role text messages were mapped to the `user` role.',
        ),
      );
    }

    return (
      input: input,
      warnings: warnings.isEmpty
          ? const <LLMWarning>[]
          : List<LLMWarning>.unmodifiable(warnings),
    );
  }

  ({List<Map<String, dynamic>> input, List<LLMWarning> warnings})
      _buildInputMessagesFromPrompt(Prompt prompt) {
    final input = <Map<String, dynamic>>[];
    var hasSystemMessage = false;

    var didOmitProviderExecutedToolCall = false;
    var didStringifyToolInput = false;
    var didNormalizeImageWildcard = false;

    String? currentRole;
    final currentText = StringBuffer();

    final currentUserText = StringBuffer();
    final currentUserParts = <Map<String, dynamic>>[];

    String? itemIdFromProviderOptions(ProviderOptions providerOptions) {
      final byProviderId = providerOptions[config.providerId];
      final byXai = providerOptions['xai'];

      Object? raw = byProviderId?['itemId'] ??
          byProviderId?['item_id'] ??
          byXai?['itemId'] ??
          byXai?['item_id'];

      if (raw is String && raw.trim().isNotEmpty) return raw.trim();
      return null;
    }

    void flushUserText() {
      final text = currentUserText.toString();
      if (text.trim().isEmpty) {
        currentUserText.clear();
        return;
      }

      currentUserParts.add({
        'type': 'input_text',
        'text': text,
      });
      currentUserText
        ..clear()
        ..write('');
    }

    void flushRole() {
      final role = currentRole;
      if (role == null) return;

      if (role == 'user') {
        flushUserText();
        if (currentUserParts.isNotEmpty) {
          input.add({
            'role': 'user',
            'content':
                List<Map<String, dynamic>>.unmodifiable(currentUserParts),
          });
        }
        currentUserParts.clear();
      } else {
        final text = currentText.toString();
        if (text.trim().isNotEmpty) {
          input.add({'role': role, 'content': text});
        }
      }
      currentRole = null;
      currentText.clear();
      currentUserText.clear();
    }

    void ensureRole(String role) {
      if (currentRole == role) return;
      flushRole();
      currentRole = role;
    }

    for (final message in prompt.messages) {
      if (message.role == PromptRole.system) {
        hasSystemMessage = true;
      }

      for (final part in message.parts) {
        PromptRole effectiveRole;
        if (part case ToolCallPart(:final overrideRole)) {
          effectiveRole = overrideRole ?? message.role;
        } else if (part case ToolResultPart(:final overrideRole)) {
          effectiveRole = overrideRole ?? message.role;
        } else {
          effectiveRole = message.role;
        }

        if (effectiveRole == PromptRole.system) {
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

        if (part case ToolApprovalResponsePart()) {
          throw const InvalidRequestError(
            'ToolApprovalResponsePart is not supported by xAI Responses.',
          );
        }

        if (part
            case ToolCallPart(
              :final toolCallId,
              :final toolName,
              input: final toolInput,
              :final providerExecuted,
            )) {
          if (providerExecuted == true) {
            didOmitProviderExecutedToolCall = true;
            continue;
          }
          if (effectiveRole != PromptRole.assistant) {
            throw const InvalidRequestError(
              'ToolCallPart must be emitted from an assistant message.',
            );
          }
          flushRole();
          String arguments;
          try {
            arguments = jsonEncode(toolInput);
          } catch (_) {
            didStringifyToolInput = true;
            arguments = jsonEncode(toolInput.toString());
          }

          final id =
              itemIdFromProviderOptions(part.providerOptions) ?? toolCallId;
          input.add({
            'type': 'function_call',
            'id': id,
            'call_id': toolCallId,
            'name': toolName,
            'arguments': arguments,
            'status': 'completed',
          });
          continue;
        }

        if (part
            case ToolResultPart(
              :final toolCallId,
              :final output,
            )) {
          if (effectiveRole != PromptRole.tool) {
            throw const InvalidRequestError(
              'ToolResultPart must be emitted from a tool message.',
            );
          }
          flushRole();
          String content;
          switch (output) {
            case ToolResultTextOutput(:final value):
            case ToolResultErrorTextOutput(:final value):
              content = value;
              break;
            case ToolResultExecutionDeniedOutput(:final reason):
              content = (reason != null && reason.trim().isNotEmpty)
                  ? reason.trim()
                  : 'Tool execution denied.';
              break;
            case ToolResultJsonOutput(:final value):
            case ToolResultErrorJsonOutput(:final value):
              content = jsonEncode(value);
              break;
            case ToolResultContentOutput():
              content = jsonEncode(output.toJson()['value']);
              break;
          }
          input.add({
            'type': 'function_call_output',
            'call_id': toolCallId,
            'output': content.isNotEmpty ? content : 'Tool result',
          });
          continue;
        }

        if (part case TextPart(:final text)) {
          ensureRole(
            switch (effectiveRole) {
              PromptRole.user => 'user',
              PromptRole.assistant => 'assistant',
              PromptRole.tool => throw const InvalidRequestError(
                  "Tool role messages cannot contain text parts."),
              PromptRole.system => 'system',
            },
          );
          if (currentRole == 'user') {
            if (currentUserText.isNotEmpty) currentUserText.write('\n\n');
            currentUserText.write(text);
          } else {
            if (currentText.isNotEmpty) currentText.write('\n\n');
            currentText.write(text);
          }
          continue;
        }

        if (part case ImagePart(:final mime, :final data, :final text)) {
          if (effectiveRole != PromptRole.user) {
            throw UnsupportedError(
              'xAI Responses API does not support ${part.runtimeType} in assistant messages',
            );
          }

          ensureRole('user');

          if (text != null && text.trim().isNotEmpty) {
            if (currentUserText.isNotEmpty) currentUserText.write('\n\n');
            currentUserText.write(text.trim());
          }

          flushUserText();

          final imageUrl = 'data:${mime.mimeType};base64,${base64Encode(data)}';
          currentUserParts.add({
            'type': 'input_image',
            'image_url': imageUrl,
          });
          continue;
        }

        if (part case ImageUrlPart(:final url, :final text)) {
          if (effectiveRole != PromptRole.user) {
            throw UnsupportedError(
              'xAI Responses API does not support ${part.runtimeType} in assistant messages',
            );
          }

          ensureRole('user');

          if (text != null && text.trim().isNotEmpty) {
            if (currentUserText.isNotEmpty) currentUserText.write('\n\n');
            currentUserText.write(text.trim());
          }

          flushUserText();

          currentUserParts.add({
            'type': 'input_image',
            'image_url': url,
          });
          continue;
        }

        if (part case FilePart(:final mime, :final data, :final text)) {
          if (!mime.mimeType.startsWith('image/')) {
            throw UnsupportedError(
              'xAI Responses API does not support file part media type ${mime.mimeType}',
            );
          }
          if (effectiveRole != PromptRole.user) {
            throw UnsupportedError(
              'xAI Responses API does not support ${part.runtimeType} in assistant messages',
            );
          }

          ensureRole('user');

          if (text != null && text.trim().isNotEmpty) {
            if (currentUserText.isNotEmpty) currentUserText.write('\n\n');
            currentUserText.write(text.trim());
          }

          flushUserText();

          final normalizedMime = mime.mimeType == 'image/*'
              ? (() {
                  didNormalizeImageWildcard = true;
                  return 'image/jpeg';
                })()
              : mime.mimeType;
          final imageUrl = 'data:$normalizedMime;base64,${base64Encode(data)}';
          currentUserParts.add({
            'type': 'input_image',
            'image_url': imageUrl,
          });
          continue;
        }

        throw UnsupportedError(
          'xAI Responses API does not support ${part.runtimeType} parts',
        );
      }

      flushRole();
    }

    if (!hasSystemMessage && config.systemPrompt != null) {
      input.insert(0, {'role': 'system', 'content': config.systemPrompt});
    }

    final warnings = <LLMWarning>[];
    if (didOmitProviderExecutedToolCall) {
      warnings.add(
        const LLMCompatibilityWarning(
          feature: 'provider-executed tool call omitted',
          details:
              'ToolCallPart(providerExecuted: true) is provider-executed and is omitted from the xAI request input for compatibility.',
        ),
      );
    }
    if (didStringifyToolInput) {
      warnings.add(
        const LLMCompatibilityWarning(
          feature: 'tool input stringified',
          details:
              'Tool input could not be JSON-encoded and was stringified for compatibility.',
        ),
      );
    }
    if (didNormalizeImageWildcard) {
      warnings.add(
        const LLMCompatibilityWarning(
          feature: 'image/* normalized to image/jpeg',
          details:
              'xAI Responses API requires a concrete image MIME type. `image/*` was normalized to `image/jpeg`.',
        ),
      );
    }

    return (
      input: input,
      warnings: warnings.isEmpty
          ? const <LLMWarning>[]
          : List<LLMWarning>.unmodifiable(warnings),
    );
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

  ChatResponse _parseResponse(
    Map<String, dynamic> responseData, {
    Map<String, String>? responseHeaders,
    LLMRequestMetadataPart? requestMetadata,
    List<LLMWarning> requestWarnings = const <LLMWarning>[],
  }) {
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
      usage = UsageInfo.fromProviderUsage(usageMap);
    }

    final id = responseData['id'] as String?;
    final model = responseData['model'] as String?;
    final status = responseData['status'] as String?;

    final createdAt = responseData['created_at'];
    DateTime? timestamp;
    if (createdAt is int) {
      timestamp =
          DateTime.fromMillisecondsSinceEpoch(createdAt * 1000, isUtc: true);
    }

    final headers = (responseHeaders != null && responseHeaders.isNotEmpty)
        ? responseHeaders
        : null;

    final responseMetadata =
        (id != null || model != null || timestamp != null || headers != null)
            ? LLMResponseMetadataPart(
                id: id,
                timestamp: timestamp,
                model: model,
                headers: headers,
                body: responseData,
                status: status,
              )
            : null;

    return XAIResponsesChatResponse(
      providerId: config.providerId,
      text: text.toString(),
      thinking: thinking.isNotEmpty ? thinking.toString() : null,
      toolCalls: toolCalls.isNotEmpty ? toolCalls : null,
      usage: usage,
      responseId: id,
      model: model,
      status: status,
      responseMetadata: responseMetadata,
      requestMetadata: requestMetadata,
      serverToolCalls: serverToolCalls.isNotEmpty ? serverToolCalls : null,
      sources: sources.isNotEmpty ? sources : null,
      warnings: requestWarnings,
    );
  }
}

class XAIResponsesChatResponse
    implements
        ChatResponseWithFinishReason,
        ChatResponseWithResponseMetadata,
        ChatResponseWithRequestMetadata,
        ChatResponseWithWarnings {
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
  final LLMResponseMetadataPart? _responseMetadata;
  final LLMRequestMetadataPart? _requestMetadata;
  final List<Map<String, dynamic>>? serverToolCalls;
  final List<Map<String, dynamic>>? sources;
  final List<LLMWarning> _warnings;

  XAIResponsesChatResponse({
    required this.providerId,
    required this.text,
    this.thinking,
    this.toolCalls,
    this.usage,
    this.responseId,
    this.model,
    this.status,
    LLMResponseMetadataPart? responseMetadata,
    LLMRequestMetadataPart? requestMetadata,
    this.serverToolCalls,
    this.sources,
    List<LLMWarning> warnings = const <LLMWarning>[],
  })  : _responseMetadata = responseMetadata,
        _requestMetadata = requestMetadata,
        _warnings = (() {
          final out = <LLMWarning>[...warnings];
          final server = serverToolCalls;
          if (server != null && server.isNotEmpty) {
            out.add(
              LLMCompatibilityWarning(
                feature: 'provider-native tool calls not surfaced',
                details:
                    'xAI Responses server tool calls are provider-executed and are not returned as local tool calls. '
                    'See providerMetadata["$providerId"]["serverToolCalls"].',
              ),
            );
          }
          return out.isEmpty
              ? const <LLMWarning>[]
              : List<LLMWarning>.unmodifiable(out);
        })();

  @override
  LLMResponseMetadataPart? get responseMetadata => _responseMetadata;

  @override
  LLMRequestMetadataPart? get requestMetadata => _requestMetadata;

  @override
  List<LLMWarning> get warnings => _warnings;

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
