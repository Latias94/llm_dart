import 'dart:async';
import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'client.dart';
import 'builtin_tools.dart';
import 'models/responses_models.dart';
import 'openai_responses_config.dart';
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
        ChatStreamPartsCapability,
        PromptChatCapability,
        PromptChatStreamPartsCapability {
  final OpenAIClient client;
  final OpenAIResponsesConfig config;

  // State tracking for stream processing
  final StringBuffer _thinkingBuffer = StringBuffer();
  final StringBuffer _activeReasoningBuffer = StringBuffer();
  final StringBuffer _outputTextBuffer = StringBuffer();
  final List<dynamic> _outputTextAnnotations = [];
  Map<String, dynamic>? _partialResponse;
  List<dynamic>? _partialOutput;
  final Map<String, String> _sourceIdByUrl = {};
  final Map<String, String> _sourceIdByDocumentKey = {};
  int _nextSourceSeq = 0;

  // Capture Responses API logprobs emitted on `response.output_text.delta`.
  // These are surfaced via providerMetadata for AI SDK parity.
  final List<dynamic> _streamLogprobs = [];

  // Capture encrypted reasoning content for reasoning blocks.
  final Map<String, String?> _reasoningEncryptedByItemId = {};

  // Track the active reasoning summary block (`{item_id}:{summary_index}`).
  String? _activeReasoningBlockId;
  // Track tool call IDs by index for streaming tool calls in the Responses API.
  // The Responses stream can send tool_calls incrementally where only the
  // first chunk contains the id and later chunks reference the same call
  // via an index. This map keeps a stable id per index so that every
  final Map<int, String> _toolCallIds = {};
  // Track tool call function names by index for streaming tool calls.
  //
  // The Responses stream may omit function.name after the first chunk and
  // only send function.arguments deltas. We cache the latest known name so
  // that downstream tool execution can reliably match the tool.
  final Map<int, String> _toolCallNames = {};
  // Track Responses API `function_call` items by `output_index`.
  //
  // These are emitted via `response.output_item.*` events, and arguments are
  // streamed separately via `response.function_call_arguments.delta`.
  final Map<int, String> _functionCallIdsByOutputIndex = {};
  final Map<int, String> _functionCallNamesByOutputIndex = {};
  // Track function_call arguments streamed via `response.function_call_arguments.delta`.
  // Keyed by `output_index` (Responses API event field).
  final Map<int, StringBuffer> _functionCallArgsByOutputIndex = {};

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

  @override
  Future<ChatResponse> chatPrompt(
    Prompt prompt, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async {
    final builtRequest = _buildPromptRequest(prompt, tools, false, false);
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
    final responseData = await client.postJson(
      responsesEndpoint,
      builtRequest.body,
    );
    return _parseResponse(
      responseData,
      toolNameMapping: builtRequest.toolNameMapping,
    );
  }

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    final builtRequest = _buildRequest(messages, tools, true, false);
    yield* _chatStreamPartsFromBuiltRequest(
      builtRequest,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<LLMStreamPart> chatPromptStreamParts(
    Prompt prompt, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    final builtRequest = _buildPromptRequest(prompt, tools, true, false);
    yield* _chatStreamPartsFromBuiltRequest(
      builtRequest,
      cancelToken: cancelToken,
    );
  }

  Stream<LLMStreamPart> _chatStreamPartsFromBuiltRequest(
    _OpenAIResponsesBuiltRequest builtRequest, {
    CancelToken? cancelToken,
  }) async* {
    final toolNameMapping = builtRequest.toolNameMapping;

    _resetStreamState();

    var inText = false;
    var inThinking = false;

    String? currentTextBlockId;
    String? currentThinkingBlockId;
    var blockCounter = 0;

    final activeToolCalls = <String>{};
    final toolCallArgsById = <String, StringBuffer>{};
    final endedToolCalls = <String>{};
    final activeProviderToolCalls = <String>{};
    final endedProviderToolCalls = <String>{};
    final emittedProviderApprovalRequests = <String>{};

    var didFinish = false;
    var didEmitResponseMetadata = false;
    String? lastProviderMetadataJson;
    final providerToolTypeById = <String, String>{};

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
            if (!didEmitResponseMetadata) {
              final response = _partialResponse;
              final id = response?['id'] as String?;
              final model = response?['model'] as String?;
              final status = response?['status'] as String?;
              final createdAtSeconds = response?['created_at'] as int?;
              final systemFingerprint =
                  response?['system_fingerprint'] as String?;

              if (id != null ||
                  model != null ||
                  status != null ||
                  systemFingerprint != null) {
                didEmitResponseMetadata = true;
                final raw = <String, dynamic>{
                  if (id != null) 'id': id,
                  if (model != null) 'model': model,
                  if (status != null) 'status': status,
                  if (createdAtSeconds != null) 'created_at': createdAtSeconds,
                  if (systemFingerprint != null)
                    'system_fingerprint': systemFingerprint,
                };
                yield LLMResponseMetadataPart(
                  id: id,
                  timestamp: createdAtSeconds == null
                      ? null
                      : DateTime.fromMillisecondsSinceEpoch(
                          createdAtSeconds * 1000,
                          isUtc: true,
                        ),
                  model: model,
                  status: status,
                  systemFingerprint: systemFingerprint,
                  raw: raw.isEmpty ? null : raw,
                );
              }
            }
            continue;
          }

          if (eventType != null && eventType.startsWith('response.')) {
            final segments = eventType.split('.');
            if (segments.length == 3) {
              final rawToolType = segments[1];
              final status = segments[2];
              if (rawToolType.endsWith('_call')) {
                final toolCallId = json['item_id'] as String?;
                if (toolCallId != null && toolCallId.isNotEmpty) {
                  providerToolTypeById[toolCallId] = rawToolType;
                  yield LLMProviderToolDeltaPart(
                    toolCallId: toolCallId,
                    toolName: rawToolType.substring(0, rawToolType.length - 5),
                    status: status,
                    data: json,
                    providerMetadata: {
                      config.providerId: {'type': eventType},
                    },
                  );
                }
              }
            }
          }

          if (eventType == 'response.output_item.added' ||
              eventType == 'response.output_item.done') {
            final outputIndex = json['output_index'] as int?;
            if (outputIndex != null) {
              _upsertOutputItem(outputIndex, json['item']);
            }

            final item = json['item'];

            // Capture encrypted reasoning content so we can surface it in
            // reasoning block providerMetadata (AI SDK parity).
            if (item is Map && item['type'] == 'reasoning') {
              final itemId = item['id'] as String?;
              final encrypted = item['encrypted_content'];
              if (itemId != null &&
                  itemId.isNotEmpty &&
                  encrypted is String &&
                  encrypted.isNotEmpty) {
                _reasoningEncryptedByItemId[itemId] = encrypted;
              }
            }

            if (outputIndex != null &&
                item is Map &&
                item['type'] == 'function_call') {
              final callId =
                  item['call_id'] as String? ?? item['id'] as String?;
              final rawName = item['name'] as String?;
              final rawArgs = item['arguments'] as String?;

              if (callId != null && callId.isNotEmpty) {
                _functionCallIdsByOutputIndex[outputIndex] = callId;
                if (rawName != null && rawName.isNotEmpty) {
                  _functionCallNamesByOutputIndex[outputIndex] = rawName;
                }

                final requestName =
                    _functionCallNamesByOutputIndex[outputIndex] ?? '';
                final originalName =
                    toolNameMapping.originalFunctionNameForRequestName(
                          requestName,
                        ) ??
                        requestName;

                if (eventType == 'response.output_item.added') {
                  if (activeToolCalls.add(callId)) {
                    yield LLMToolCallStartPart(
                      ToolCall(
                        id: callId,
                        callType: 'function',
                        function: FunctionCall(
                          name: originalName,
                          arguments: '',
                        ),
                      ),
                    );
                  }
                } else if (eventType == 'response.output_item.done') {
                  if (rawArgs != null) {
                    _functionCallArgsByOutputIndex[outputIndex] = StringBuffer(
                      rawArgs,
                    );
                    final output = _partialOutput;
                    if (output != null && outputIndex < output.length) {
                      final current = output[outputIndex];
                      if (current is Map<String, dynamic>) {
                        current['arguments'] = rawArgs;
                      } else if (current is Map) {
                        current['arguments'] = rawArgs;
                      }
                    }
                  }

                  if (activeToolCalls.remove(callId)) {
                    yield LLMToolCallEndPart(callId);
                  }
                }
              }
            }

            if (item is Map) {
              final rawType = item['type'];

              if (rawType == 'mcp_approval_request') {
                final id = item['id'] as String? ?? '';
                if (id.isNotEmpty && emittedProviderApprovalRequests.add(id)) {
                  final name = item['name'] as String? ?? 'mcp';
                  final argsRaw = item['arguments'];
                  Object? input = argsRaw;
                  if (argsRaw is String && argsRaw.isNotEmpty) {
                    try {
                      final decoded = jsonDecode(argsRaw);
                      if (decoded is Map || decoded is List) {
                        input = decoded;
                      }
                    } catch (_) {
                      // Keep raw string as-is.
                    }
                  }

                  yield LLMProviderToolApprovalRequestPart(
                    approvalId: id,
                    toolCallId: id,
                    toolName: name,
                    input: input,
                    providerMetadata: {
                      config.providerId: {
                        'type': 'mcp_approval_request',
                        if (item['server_label'] is String)
                          'serverLabel': item['server_label'],
                      },
                    },
                  );
                }
              }

              if (rawType is String &&
                  rawType.endsWith('_call') &&
                  rawType != 'function_call') {
                final id = item['id'] as String? ?? '';
                if (id.isNotEmpty) {
                  final toolName = rawType.substring(0, rawType.length - 5);
                  providerToolTypeById[id] = rawType;

                  if (eventType == 'response.output_item.added') {
                    if (activeProviderToolCalls.add(id)) {
                      yield LLMProviderToolCallPart(
                        toolCallId: id,
                        toolName: toolName,
                        input: item['arguments'] ?? item['action'],
                        providerMetadata: {
                          config.providerId: {'type': rawType},
                        },
                      );
                    }
                  } else if (eventType == 'response.output_item.done') {
                    if (!endedProviderToolCalls.add(id)) {
                      // Ignore duplicate done events for the same provider tool call.
                      continue;
                    }

                    if (activeProviderToolCalls.add(id)) {
                      // Some fixtures may only include a `done` item. Emit a call
                      // part best-effort so consumers always see the invocation.
                      yield LLMProviderToolCallPart(
                        toolCallId: id,
                        toolName: toolName,
                        input: item['arguments'] ?? item['action'],
                        providerMetadata: {
                          config.providerId: {'type': rawType},
                        },
                      );
                    }

                    {
                      yield LLMProviderToolResultPart(
                        toolCallId: id,
                        toolName: toolName,
                        result: item.map<String, dynamic>(
                          (key, value) => MapEntry(key.toString(), value),
                        ),
                        providerMetadata: {
                          config.providerId: {
                            'type': rawType,
                            if (item['status'] is String)
                              'status': item['status'],
                          },
                        },
                      );
                    }

                    activeProviderToolCalls.remove(id);
                  }
                }
              }
            }

            if (eventType == 'response.output_item.done') {
              if (item is Map && item['type'] == 'web_search_call') {
                final action = item['action'];
                if (action is Map) {
                  final sources = action['sources'];
                  if (sources is List) {
                    for (final s in sources) {
                      if (s is! Map) continue;
                      if (s['type'] != 'url') continue;
                      final url = s['url'];
                      if (url is! String || url.isEmpty) continue;

                      final part = _newSourceUrlPart(
                        url: url,
                        title:
                            s['title'] is String ? s['title'] as String : null,
                        providerMetadata: {
                          config.providerId: {'type': 'web_search_call'},
                        },
                      );
                      if (part != null) yield part;
                    }
                  }
                }
              }

              final metadata = OpenAIResponsesResponse(
                _buildPartialResponse(),
                null,
                null,
                config.providerId,
              ).providerMetadata;
              if (metadata != null && metadata.isNotEmpty) {
                final encoded = tryStableJsonEncode(metadata);
                if (encoded == null || encoded != lastProviderMetadataJson) {
                  lastProviderMetadataJson = encoded;
                  yield LLMProviderMetadataPart(metadata);
                }
              }
            }
            continue;
          }

          if (eventType == 'response.output_text.annotation.added') {
            final annotation = json['annotation'];
            if (annotation is Map) {
              _outputTextAnnotations.add(annotation);

              if (annotation['type'] == 'url_citation') {
                final url = annotation['url'];
                if (url is String && url.isNotEmpty) {
                  final part = _newSourceUrlPart(
                    url: url,
                    title: annotation['title'] is String
                        ? annotation['title'] as String
                        : null,
                    providerMetadata: {
                      config.providerId: {
                        'type': 'url_citation',
                        if (annotation['start_index'] is int)
                          'startIndex': annotation['start_index'],
                        if (annotation['end_index'] is int)
                          'endIndex': annotation['end_index'],
                      },
                    },
                  );
                  if (part != null) yield part;
                }
              }

              // OpenAI Responses file citations: surface as source-document parts
              // (AI SDK parity).
              final type = annotation['type'];
              if (type == 'file_citation' ||
                  type == 'container_file_citation' ||
                  type == 'file_path') {
                final fileId = annotation['file_id'];
                final index = annotation['index'];
                final containerId = annotation['container_id'];
                final filename = annotation['filename'];

                if (fileId is String && fileId.isNotEmpty) {
                  final isFilePath = type == 'file_path';
                  final mediaType =
                      isFilePath ? 'application/octet-stream' : 'text/plain';
                  final title = (filename is String && filename.isNotEmpty)
                      ? filename
                      : fileId;

                  final key = [
                    type.toString(),
                    fileId,
                    index is int ? index.toString() : '',
                    containerId is String ? containerId : '',
                  ].join(':');

                  final docPart = _newSourceDocumentPart(
                    dedupeKey: key,
                    mediaType: mediaType,
                    title: title,
                    filename: title,
                    providerMetadata: {
                      config.providerId: {
                        'type': type,
                        'fileId': fileId,
                        if (index is int) 'index': index,
                        if (containerId is String && containerId.isNotEmpty)
                          'containerId': containerId,
                      },
                    },
                  );

                  if (docPart != null) yield docPart;
                }
              }

              final metadata = OpenAIResponsesResponse(
                _buildPartialResponse(),
                null,
                null,
                config.providerId,
              ).providerMetadata;
              if (metadata != null && metadata.isNotEmpty) {
                final encoded = tryStableJsonEncode(metadata);
                if (encoded == null || encoded != lastProviderMetadataJson) {
                  lastProviderMetadataJson = encoded;
                  yield LLMProviderMetadataPart(metadata);
                }
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
          if (eventType == 'response.reasoning_summary_part.added') {
            final itemId = json['item_id'] as String?;
            final summaryIndex = json['summary_index'] as int?;
            if (itemId == null || itemId.isEmpty || summaryIndex == null) {
              continue;
            }

            final nextBlockId = '$itemId:$summaryIndex';
            if (_activeReasoningBlockId != nextBlockId) {
              if (inThinking && _activeReasoningBlockId != null) {
                final prevItemId = _activeReasoningBlockId!.split(':').first;
                yield LLMReasoningEndPart(
                  _activeReasoningBuffer.toString(),
                  blockId: _activeReasoningBlockId,
                  providerMetadata: {
                    config.providerId: {'itemId': prevItemId},
                  },
                );
                _activeReasoningBuffer.clear();
              }

              _activeReasoningBlockId = nextBlockId;
              inThinking = true;
              currentThinkingBlockId = nextBlockId;

              yield LLMReasoningStartPart(
                blockId: nextBlockId,
                providerMetadata: {
                  config.providerId: {
                    'itemId': itemId,
                    if (_reasoningEncryptedByItemId[itemId] != null)
                      'reasoningEncryptedContent':
                          _reasoningEncryptedByItemId[itemId],
                  },
                },
              );
            }
            continue;
          }

          if (eventType == 'response.reasoning_summary_text.delta') {
            final delta = json['delta'] as String?;
            if (delta == null || delta.isEmpty) continue;

            final itemId = json['item_id'] as String?;
            final summaryIndex = json['summary_index'] as int?;

            final nextBlockId = (itemId == null || itemId.isEmpty)
                ? (currentThinkingBlockId ?? '${blockCounter++}')
                : '$itemId:${summaryIndex ?? 0}';

            if (_activeReasoningBlockId != nextBlockId) {
              if (inThinking && _activeReasoningBlockId != null) {
                final prevItemId = _activeReasoningBlockId!.split(':').first;
                yield LLMReasoningEndPart(
                  _activeReasoningBuffer.toString(),
                  blockId: _activeReasoningBlockId,
                  providerMetadata: {
                    config.providerId: {'itemId': prevItemId},
                  },
                );
                _activeReasoningBuffer.clear();
              }

              _activeReasoningBlockId = nextBlockId;
              inThinking = true;
              currentThinkingBlockId = nextBlockId;

              yield LLMReasoningStartPart(
                blockId: nextBlockId,
                providerMetadata: itemId == null || itemId.isEmpty
                    ? null
                    : {
                        config.providerId: {
                          'itemId': itemId,
                          if (_reasoningEncryptedByItemId[itemId] != null)
                            'reasoningEncryptedContent':
                                _reasoningEncryptedByItemId[itemId],
                        },
                      },
              );
            }

            _thinkingBuffer.write(delta);
            _activeReasoningBuffer.write(delta);
            yield LLMReasoningDeltaPart(
              delta,
              blockId: currentThinkingBlockId,
              providerMetadata: itemId == null || itemId.isEmpty
                  ? null
                  : {
                      config.providerId: {'itemId': itemId},
                    },
            );
            continue;
          }

          if (eventType == 'response.reasoning_summary_text.done') {
            final text = json['text'] as String?;
            if (text != null) {
              final itemId = json['item_id'] as String?;
              final summaryIndex = json['summary_index'] as int?;
              final nextBlockId = (itemId == null || itemId.isEmpty)
                  ? (currentThinkingBlockId ?? '${blockCounter++}')
                  : '$itemId:${summaryIndex ?? 0}';

              if (_activeReasoningBlockId != nextBlockId) {
                if (inThinking && _activeReasoningBlockId != null) {
                  final prevItemId = _activeReasoningBlockId!.split(':').first;
                  yield LLMReasoningEndPart(
                    _activeReasoningBuffer.toString(),
                    blockId: _activeReasoningBlockId,
                    providerMetadata: {
                      config.providerId: {'itemId': prevItemId},
                    },
                  );
                  _activeReasoningBuffer.clear();
                }

                _activeReasoningBlockId = nextBlockId;
                inThinking = true;
                currentThinkingBlockId = nextBlockId;
                yield LLMReasoningStartPart(
                  blockId: nextBlockId,
                  providerMetadata: itemId == null || itemId.isEmpty
                      ? null
                      : {
                          config.providerId: {
                            'itemId': itemId,
                            if (_reasoningEncryptedByItemId[itemId] != null)
                              'reasoningEncryptedContent':
                                  _reasoningEncryptedByItemId[itemId],
                          },
                        },
                );
              }

              // If the stream provides only a final done value, ensure buffers
              // reflect it. If deltas were already observed, keep the delta
              // accumulation as the source of truth.
              if (_activeReasoningBuffer.isEmpty) {
                _thinkingBuffer.write(text);
                _activeReasoningBuffer.write(text);
              }
            }
            continue;
          }

          if (eventType == 'response.reasoning_summary_part.done') {
            final itemId = json['item_id'] as String?;
            final summaryIndex = json['summary_index'] as int?;
            if (itemId == null || itemId.isEmpty || summaryIndex == null) {
              continue;
            }

            final blockId = '$itemId:$summaryIndex';
            if (inThinking && _activeReasoningBlockId == blockId) {
              yield LLMReasoningEndPart(
                _activeReasoningBuffer.toString(),
                blockId: blockId,
                providerMetadata: {
                  config.providerId: {'itemId': itemId},
                },
              );
              _activeReasoningBuffer.clear();
              _activeReasoningBlockId = null;
              inThinking = false;
              currentThinkingBlockId = null;
            }
            continue;
          }

          if (eventType == 'response.output_text.delta') {
            final delta = json['delta'] as String?;
            if (delta == null || delta.isEmpty) continue;

            final logprobs = json['logprobs'];
            if (logprobs != null) {
              _streamLogprobs.add(logprobs);
            }

            if (ReasoningUtils.containsThinkingTags(delta)) {
              final thinkMatch = RegExp(
                r'<think>(.*?)</think>',
                dotAll: true,
              ).firstMatch(delta);
              final thinkingText = thinkMatch?.group(1)?.trim();
              if (thinkingText != null && thinkingText.isNotEmpty) {
                if (!inThinking) {
                  inThinking = true;
                  currentThinkingBlockId ??= '${blockCounter++}';
                  yield LLMReasoningStartPart(blockId: currentThinkingBlockId);
                }
                _thinkingBuffer.write(thinkingText);
                yield LLMReasoningDeltaPart(
                  thinkingText,
                  blockId: currentThinkingBlockId,
                );
              }
              continue;
            }

            if (!inText) {
              inText = true;
              currentTextBlockId ??= '${blockCounter++}';
              yield LLMTextStartPart(blockId: currentTextBlockId);
            }
            _outputTextBuffer.write(delta);
            yield LLMTextDeltaPart(delta, blockId: currentTextBlockId);
            continue;
          }

          // Fallback: reasoning content in other fields
          final reasoningContent = ReasoningUtils.extractReasoningContent(json);
          if (reasoningContent != null && reasoningContent.isNotEmpty) {
            if (!inThinking) {
              inThinking = true;
              currentThinkingBlockId ??= '${blockCounter++}';
              yield LLMReasoningStartPart(blockId: currentThinkingBlockId);
            }
            _thinkingBuffer.write(reasoningContent);
            yield LLMReasoningDeltaPart(
              reasoningContent,
              blockId: currentThinkingBlockId,
            );
            continue;
          }

          if (eventType == 'response.function_call_arguments.delta') {
            final outputIndex = json['output_index'] as int?;
            final delta = json['delta'] as String?;
            if (outputIndex == null || delta == null || delta.isEmpty) continue;

            final callId = _functionCallIdsByOutputIndex[outputIndex];
            if (callId == null || callId.isEmpty) continue;

            final buf = _functionCallArgsByOutputIndex.putIfAbsent(
              outputIndex,
              StringBuffer.new,
            );
            buf.write(delta);

            final output = _partialOutput;
            if (output != null && outputIndex < output.length) {
              final current = output[outputIndex];
              if (current is Map<String, dynamic>) {
                current['arguments'] = buf.toString();
              } else if (current is Map) {
                current['arguments'] = buf.toString();
              }
            }

            var requestName =
                _functionCallNamesByOutputIndex[outputIndex] ?? '';
            if (requestName.isEmpty) {
              if (output != null && outputIndex < output.length) {
                final current = output[outputIndex];
                if (current is Map) {
                  final name = current['name'];
                  if (name is String && name.isNotEmpty) {
                    requestName = name;
                  }
                }
              }
            }

            final originalName =
                toolNameMapping.originalFunctionNameForRequestName(
                      requestName,
                    ) ??
                    requestName;

            if (originalName.isNotEmpty) {
              if (activeToolCalls.add(callId)) {
                yield LLMToolCallStartPart(
                  ToolCall(
                    id: callId,
                    callType: 'function',
                    function: FunctionCall(name: originalName, arguments: ''),
                  ),
                );
              }

              yield LLMToolCallDeltaPart(
                ToolCall(
                  id: callId,
                  callType: 'function',
                  function: FunctionCall(name: originalName, arguments: delta),
                ),
              );
            }

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
                      function: FunctionCall(name: name, arguments: args),
                    );
                    if (activeToolCalls.add(toolCall.id)) {
                      yield LLMToolCallStartPart(toolCall);
                    } else {
                      yield LLMToolCallDeltaPart(toolCall);
                    }

                    if (args.isNotEmpty) {
                      final buf = toolCallArgsById.putIfAbsent(
                        stableId,
                        StringBuffer.new,
                      );
                      buf.write(args);
                      final fullArgs = buf.toString();
                      if (fullArgs.isNotEmpty &&
                          isParsableJson(fullArgs) &&
                          endedToolCalls.add(stableId)) {
                        yield LLMToolCallEndPart(stableId);
                        activeToolCalls.remove(stableId);
                      }
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
                if (activeToolCalls.add(toolCall.id)) {
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

                final args = toolCall.function.arguments;
                if (args.isNotEmpty) {
                  final buf = toolCallArgsById.putIfAbsent(
                    toolCall.id,
                    StringBuffer.new,
                  );
                  buf.write(args);
                  final fullArgs = buf.toString();
                  if (fullArgs.isNotEmpty &&
                      isParsableJson(fullArgs) &&
                      endedToolCalls.add(toolCall.id)) {
                    yield LLMToolCallEndPart(toolCall.id);
                    activeToolCalls.remove(toolCall.id);
                  }
                }
              } catch (_) {
                // Ignore malformed tool calls
              }
            }
          }

          if (eventType == 'response.failed' ||
              eventType == 'response.cancelled') {
            didFinish = true;

            final raw = json['error'];
            String message = eventType == 'response.cancelled'
                ? 'Responses stream cancelled'
                : 'Responses stream failed';
            if (raw is Map) {
              final rawMessage = raw['message'];
              if (rawMessage is String && rawMessage.isNotEmpty) {
                message = rawMessage;
              }
            }

            yield LLMErrorPart(GenericError(message));
            return;
          }

          if (eventType == 'response.completed' ||
              eventType == 'response.incomplete') {
            didFinish = true;

            final completedResponse = json['response'];
            if (completedResponse is Map) {
              _captureResponseObject(completedResponse);
              if (!didEmitResponseMetadata) {
                final response = _partialResponse;
                final id = response?['id'] as String?;
                final model = response?['model'] as String?;
                final status = response?['status'] as String?;
                final createdAtSeconds = response?['created_at'] as int?;
                final systemFingerprint =
                    response?['system_fingerprint'] as String?;

                if (id != null ||
                    model != null ||
                    status != null ||
                    systemFingerprint != null) {
                  didEmitResponseMetadata = true;
                  final raw = <String, dynamic>{
                    if (id != null) 'id': id,
                    if (model != null) 'model': model,
                    if (status != null) 'status': status,
                    if (createdAtSeconds != null)
                      'created_at': createdAtSeconds,
                    if (systemFingerprint != null)
                      'system_fingerprint': systemFingerprint,
                  };
                  yield LLMResponseMetadataPart(
                    id: id,
                    timestamp: createdAtSeconds == null
                        ? null
                        : DateTime.fromMillisecondsSinceEpoch(
                            createdAtSeconds * 1000,
                            isUtc: true,
                          ),
                    model: model,
                    status: status,
                    systemFingerprint: systemFingerprint,
                    raw: raw.isEmpty ? null : raw,
                  );
                }
              }
            }

            final thinkingContent =
                _thinkingBuffer.isNotEmpty ? _thinkingBuffer.toString() : null;
            final response = OpenAIResponsesResponse(
              _buildPartialResponse(),
              thinkingContent,
              toolNameMapping,
              config.providerId,
            );

            if (inText) {
              yield LLMTextEndPart(
                _outputTextBuffer.toString(),
                blockId: currentTextBlockId,
              );
              inText = false;
              currentTextBlockId = null;
            }
            if (inThinking) {
              if (_activeReasoningBlockId != null) {
                final itemId = _activeReasoningBlockId!.split(':').first;
                yield LLMReasoningEndPart(
                  _activeReasoningBuffer.toString(),
                  blockId: _activeReasoningBlockId,
                  providerMetadata: {
                    config.providerId: {'itemId': itemId},
                  },
                );
                _activeReasoningBuffer.clear();
                _activeReasoningBlockId = null;
              } else {
                yield LLMReasoningEndPart(
                  _thinkingBuffer.toString(),
                  blockId: currentThinkingBlockId,
                );
              }
              inThinking = false;
              currentThinkingBlockId = null;
            }
            for (final id in activeToolCalls) {
              if (endedToolCalls.contains(id)) continue;
              final fullArgs = toolCallArgsById[id]?.toString() ?? '';
              if (fullArgs.isNotEmpty && isParsableJson(fullArgs)) {
                yield LLMToolCallEndPart(id);
              }
            }

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
          config.providerId,
        );

        if (inText) {
          yield LLMTextEndPart(
            _outputTextBuffer.toString(),
            blockId: currentTextBlockId,
          );
          inText = false;
          currentTextBlockId = null;
        }
        if (inThinking) {
          if (_activeReasoningBlockId != null) {
            final itemId = _activeReasoningBlockId!.split(':').first;
            yield LLMReasoningEndPart(
              _activeReasoningBuffer.toString(),
              blockId: _activeReasoningBlockId,
              providerMetadata: {
                config.providerId: {'itemId': itemId},
              },
            );
            _activeReasoningBuffer.clear();
            _activeReasoningBlockId = null;
          } else {
            yield LLMReasoningEndPart(
              _thinkingBuffer.toString(),
              blockId: currentThinkingBlockId,
            );
          }
          inThinking = false;
          currentThinkingBlockId = null;
        }
        for (final id in activeToolCalls) {
          if (endedToolCalls.contains(id)) continue;
          final fullArgs = toolCallArgsById[id]?.toString() ?? '';
          if (fullArgs.isNotEmpty && isParsableJson(fullArgs)) {
            yield LLMToolCallEndPart(id);
          }
        }

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
          .map(
            (e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
          )
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
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
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
    final builtRequest = _buildRequest(
      newMessages,
      tools,
      false,
      background,
      previousResponseId: previousResponseId,
    );
    final responseData = await client.postJson(
      responsesEndpoint,
      builtRequest.body,
    );
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
    return continueConversation(
      fromResponseId,
      newMessages,
      tools: tools,
      background: background,
    );
  }

  _OpenAIResponsesBuiltRequest _buildRequest(
    List<ChatMessage> messages,
    List<Tool>? tools,
    bool stream,
    bool background, {
    String? previousResponseId,
  }) {
    final effectiveTools = tools ?? config.tools;
    final toolNameMapping = _createToolNameMapping(effectiveTools);
    final body = _buildRequestBody(
      messages,
      effectiveTools,
      stream,
      background,
      toolNameMapping,
      previousResponseId: previousResponseId,
    );

    return _OpenAIResponsesBuiltRequest(
      body: body,
      toolNameMapping: toolNameMapping,
    );
  }

  _OpenAIResponsesBuiltRequest _buildPromptRequest(
    Prompt prompt,
    List<Tool>? tools,
    bool stream,
    bool background, {
    String? previousResponseId,
  }) {
    final effectiveTools = tools ?? config.tools;
    final toolNameMapping = _createToolNameMapping(effectiveTools);

    final apiMessages =
        OpenAIResponsesMessageConverter.buildInputMessagesFromPrompt(prompt);
    final body = _buildRequestBodyFromApiMessages(
      apiMessages,
      effectiveTools,
      stream,
      background,
      toolNameMapping,
      previousResponseId: previousResponseId,
    );

    return _OpenAIResponsesBuiltRequest(
      body: body,
      toolNameMapping: toolNameMapping,
    );
  }

  ToolNameMapping _createToolNameMapping(List<Tool>? tools) {
    final functionToolNames = (tools ?? const <Tool>[]).map(
      (t) => t.function.name,
    );

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
    ToolNameMapping toolNameMapping, {
    String? previousResponseId,
  }) {
    final apiMessages = OpenAIResponsesMessageConverter.buildInputMessages(
      messages,
    );
    return _buildRequestBodyFromApiMessages(
      apiMessages,
      tools,
      stream,
      background,
      toolNameMapping,
      previousResponseId: previousResponseId,
    );
  }

  Map<String, dynamic> _buildRequestBodyFromApiMessages(
    List<Map<String, dynamic>> apiMessages,
    List<Tool>? tools,
    bool stream,
    bool background,
    ToolNameMapping toolNameMapping, {
    String? previousResponseId,
  }) {
    final inputMessages = List<Map<String, dynamic>>.from(apiMessages);

    // Handle system prompt: prefer explicit system messages over config
    final hasSystemMessage =
        inputMessages.any((m) => m['role']?.toString() == 'system');

    // Only add config system prompt if no explicit system message exists
    if (!hasSystemMessage && config.systemPrompt != null) {
      inputMessages
          .insert(0, {'role': 'system', 'content': config.systemPrompt});
    }

    final body = <String, dynamic>{
      'model': config.model,
      'input': inputMessages,
      'stream': stream,
      'background': background,
    };

    // Add previous response ID for chaining
    final effectivePreviousResponseId =
        previousResponseId ?? config.previousResponseId;
    if (effectivePreviousResponseId != null &&
        effectivePreviousResponseId.isNotEmpty) {
      body['previous_response_id'] = effectivePreviousResponseId;
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
      body['reasoning'] = {'effort': config.reasoningEffort!.value};
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

    final rawInclude = config.originalConfig?.getProviderOption<dynamic>(
      config.providerId,
      'include',
    );
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

    final hasFileSearchTool =
        builtInTools?.any((t) => t.type == OpenAIBuiltInToolType.fileSearch) ??
            false;
    if (hasFileSearchTool) {
      include.add('file_search_call.results');
    }

    final hasComputerUseTool =
        builtInTools?.any((t) => t.type == OpenAIBuiltInToolType.computerUse) ??
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
    final frequencyPenalty = config.getProviderOption<double>(
      'frequencyPenalty',
    );
    if (frequencyPenalty != null) {
      body['frequency_penalty'] = frequencyPenalty;
    }

    final presencePenalty = config.getProviderOption<double>('presencePenalty');
    if (presencePenalty != null) {
      body['presence_penalty'] = presencePenalty;
    }

    final logitBias = config.getProviderOption<Map<String, double>>(
      'logitBias',
    );
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
      responseData,
      thinkingContent,
      toolNameMapping,
      config.providerId,
    );
  }

  /// Reset stream state (call this when starting a new stream)
  void _resetStreamState() {
    _thinkingBuffer.clear();
    _activeReasoningBuffer.clear();
    _toolCallIds.clear();
    _toolCallNames.clear();
    _functionCallIdsByOutputIndex.clear();
    _functionCallNamesByOutputIndex.clear();
    _functionCallArgsByOutputIndex.clear();
    _outputTextBuffer.clear();
    _outputTextAnnotations.clear();
    _partialResponse = null;
    _partialOutput = null;
    _sourceIdByUrl.clear();
    _sourceIdByDocumentKey.clear();
    _nextSourceSeq = 0;
    _streamLogprobs.clear();
    _reasoningEncryptedByItemId.clear();
    _activeReasoningBlockId = null;
  }

  String _sourceIdForUrl(String url) {
    return _sourceIdByUrl.putIfAbsent(url, () => 'source_${_nextSourceSeq++}');
  }

  LLMSourceUrlPart? _newSourceUrlPart({
    required String url,
    String? title,
    Map<String, dynamic>? providerMetadata,
  }) {
    if (_sourceIdByUrl.containsKey(url)) return null;
    return LLMSourceUrlPart(
      sourceId: _sourceIdForUrl(url),
      url: url,
      title: title,
      providerMetadata: providerMetadata,
    );
  }

  String _sourceIdForDocumentKey(String key) {
    return _sourceIdByDocumentKey.putIfAbsent(
      key,
      () => 'source_${_nextSourceSeq++}',
    );
  }

  LLMSourceDocumentPart? _newSourceDocumentPart({
    required String dedupeKey,
    required String mediaType,
    required String title,
    String? filename,
    Map<String, dynamic>? providerMetadata,
  }) {
    if (_sourceIdByDocumentKey.containsKey(dedupeKey)) return null;
    return LLMSourceDocumentPart(
      sourceId: _sourceIdForDocumentKey(dedupeKey),
      mediaType: mediaType,
      title: title,
      filename: filename,
      providerMetadata: providerMetadata,
    );
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
      result['output_text_annotations'] = List<dynamic>.from(
        _outputTextAnnotations,
      );
    }

    if (_streamLogprobs.isNotEmpty) {
      result['logprobs'] = List<dynamic>.from(_streamLogprobs);
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

  /// Convert Tool to Responses API format
  ///
  /// Responses API expects a flattened format instead of nested function object
  Map<String, dynamic> _convertToolToResponsesFormat(
    Tool tool,
    ToolNameMapping toolNameMapping,
  ) {
    final requestName = toolNameMapping.requestNameForFunction(
      tool.function.name,
    );
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
class OpenAIResponsesResponse implements ChatResponseWithFinishReason {
  final Map<String, dynamic> _rawResponse;
  final String? _thinkingContent;
  final ToolNameMapping? _toolNameMapping;
  final String _providerId;

  OpenAIResponsesResponse(
    this._rawResponse, [
    this._thinkingContent,
    this._toolNameMapping,
    String providerId = 'openai',
  ]) : _providerId = providerId;

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

    // OpenAI Responses API reports token usage with `input_tokens`/`output_tokens`.
    // Normalize it into the standard `UsageInfo` fields.
    final promptTokens =
        usageData['prompt_tokens'] ?? usageData['input_tokens'];
    final completionTokens =
        usageData['completion_tokens'] ?? usageData['output_tokens'];

    int? reasoningTokens;
    final rawReasoning = usageData['reasoning_tokens'];
    if (rawReasoning is int) {
      reasoningTokens = rawReasoning;
    } else {
      final outputDetails = usageData['output_tokens_details'];
      if (outputDetails is Map) {
        final value = outputDetails['reasoning_tokens'];
        if (value is int) reasoningTokens = value;
      }
    }

    return UsageInfo(
      promptTokens: promptTokens is int ? promptTokens : null,
      completionTokens: completionTokens is int ? completionTokens : null,
      totalTokens:
          usageData['total_tokens'] is int ? usageData['total_tokens'] : null,
      reasoningTokens: reasoningTokens,
    );
  }

  @override
  String? get thinking => _thinkingContent;

  @override
  LLMFinishReason? get finishReason {
    final status = _rawResponse['status'] as String?;
    final incompleteDetails = _rawResponse['incomplete_details'];
    final error = _rawResponse['error'];

    if (error != null) {
      return const LLMFinishReason(
        unified: LLMUnifiedFinishReason.error,
        raw: 'error',
      );
    }

    if (status == null || status.isEmpty) return null;

    if (status == 'failed' || status == 'cancelled') {
      return LLMFinishReason(
        unified: LLMUnifiedFinishReason.error,
        raw: status,
      );
    }

    if (status == 'incomplete') {
      String? rawReason;
      if (incompleteDetails is Map) {
        final reason = incompleteDetails['reason'];
        if (reason is String && reason.isNotEmpty) rawReason = reason;
      }

      final reason = rawReason ?? status;
      final unified = switch (reason) {
        'max_output_tokens' || 'max_tokens' => LLMUnifiedFinishReason.length,
        'content_filter' ||
        'content_filter_violation' =>
          LLMUnifiedFinishReason.contentFilter,
        _ => LLMUnifiedFinishReason.other,
      };

      return LLMFinishReason(unified: unified, raw: reason);
    }

    if (status == 'completed') {
      // The Responses API does not expose a Chat Completions-style finish_reason.
      // Align with AI SDK: treat completion as stop unless function tool calls exist.
      if (toolCalls != null && toolCalls!.isNotEmpty) {
        return const LLMFinishReason(
          unified: LLMUnifiedFinishReason.toolCalls,
          raw: null,
        );
      }
      return const LLMFinishReason(
        unified: LLMUnifiedFinishReason.stop,
        raw: null,
      );
    }

    // Fallback for unexpected status values.
    return LLMFinishReason(unified: LLMUnifiedFinishReason.other, raw: status);
  }

  @override
  Map<String, dynamic>? get providerMetadata {
    final id = _rawResponse['id'];
    final model = _rawResponse['model'];
    final serviceTier = _rawResponse['service_tier'];
    final logprobs = _rawResponse['logprobs'];

    final serverToolCalls = _extractServerToolCalls();
    final fileSearchCalls = _extractFileSearchCalls();
    final computerCalls = _extractComputerCalls();
    final webSearchCalls = _extractWebSearchCalls();
    final annotations = _extractOutputTextAnnotations();

    final codeInterpreterCalls = _extractOutputItemsByType(
      'code_interpreter_call',
    );
    final imageGenerationCalls = _extractOutputItemsByType(
      'image_generation_call',
    );

    final mcpCalls = _extractOutputItemsByType('mcp_call');
    final mcpListTools = _extractOutputItemsByType('mcp_list_tools');
    final mcpApprovalRequests = _extractOutputItemsByType(
      'mcp_approval_request',
    );

    final shellCalls = _extractOutputItemsByType('shell_call');
    final shellCallOutputs = _extractOutputItemsByType('shell_call_output');

    final localShellCalls = _extractOutputItemsByType('local_shell_call');
    final localShellCallOutputs = _extractOutputItemsByType(
      'local_shell_call_output',
    );

    final applyPatchCalls = _extractOutputItemsByType('apply_patch_call');
    final applyPatchCallOutputs = _extractOutputItemsByType(
      'apply_patch_call_output',
    );

    if (id == null &&
        model == null &&
        serviceTier == null &&
        logprobs == null &&
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
      _providerId: {
        if (id != null) 'id': id,
        if (id != null) 'responseId': id,
        if (model != null) 'model': model,
        if (serviceTier is String && serviceTier.isNotEmpty)
          'serviceTier': serviceTier,
        if (logprobs is List && logprobs.isNotEmpty) 'logprobs': logprobs,
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
