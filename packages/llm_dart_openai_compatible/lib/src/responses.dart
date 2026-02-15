import 'dart:async';
import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:llm_dart_provider_utils/utils/request_metadata_sanitizer.dart';
import 'client.dart';
import 'builtin_tools.dart';
import 'models/responses_models.dart';
import 'openai_responses_config.dart';
import 'responses_capability.dart';
import 'responses_message_converter.dart';
import 'web_search_context_size.dart';

class _OpenAIResponsesBuiltRequest {
  final Map<String, dynamic> body;
  final ToolNameMapping toolNameMapping;
  final List<ProviderTool>? providerTools;

  const _OpenAIResponsesBuiltRequest({
    required this.body,
    required this.toolNameMapping,
    required this.providerTools,
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
        ModelIdentityCapability,
        OpenAIResponsesCapability,
        ChatStreamPartsCapability,
        PromptChatCapability,
        PromptChatStreamPartsCapability,
        ChatCallOptionsCapability,
        PromptChatCallOptionsCapability,
        ChatStreamPartsCallOptionsCapability,
        PromptChatStreamPartsCallOptionsCapability {
  final OpenAIClient client;
  final OpenAIResponsesConfig config;

  // State tracking for stream processing
  final StringBuffer _thinkingBuffer = StringBuffer();
  final StringBuffer _activeReasoningBuffer = StringBuffer();
  final StringBuffer _outputTextBuffer = StringBuffer();
  final List<dynamic> _outputTextAnnotations = [];
  Map<String, dynamic>? _partialResponse;
  List<dynamic>? _partialOutput;
  late final SourcePartEmitter _sourceParts;

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

  OpenAIResponses(this.client, this.config) {
    _sourceParts = SourcePartEmitter(
      providerMetadataNamespace: config.providerId,
      sourceIdPrefix: 'id-',
    );
  }

  @override
  String get providerId => config.providerId;

  @override
  String get modelId => config.model;

  String get responsesEndpoint => 'responses';

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
    final builtRequest = _buildRequest(
      messages,
      tools,
      false,
      false,
      providerTools: providerTools,
    );
    var requestBody = Map<String, dynamic>.from(builtRequest.body);
    requestBody = callOptions.mergeIntoRequestBody(requestBody);
    final emitRequestMetadata = config.getProviderOption<bool>(
          'emitRequestMetadata',
        ) ??
        config.getProviderOption<bool>(
          'emit_request_metadata',
        ) ??
        false;
    final requestMetadata = emitRequestMetadata
        ? LLMRequestMetadataPart(
            body: sanitizeRequestBodyForMetadata(requestBody),
          )
        : null;
    final responseWithHeaders = await client.postJsonWithHeaders(
      responsesEndpoint,
      requestBody,
      headers: callOptions.headers,
      cancelToken: cancelToken,
    );
    return _parseResponse(
      responseWithHeaders.json,
      toolNameMapping: builtRequest.toolNameMapping,
      responseHeaders: responseWithHeaders.headers,
      requestMetadata: requestMetadata,
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
    final builtRequest = _buildPromptRequest(
      prompt,
      tools,
      false,
      false,
      providerTools: providerTools,
    );
    var requestBody = Map<String, dynamic>.from(builtRequest.body);
    requestBody = callOptions.mergeIntoRequestBody(requestBody);
    final emitRequestMetadata = config.getProviderOption<bool>(
          'emitRequestMetadata',
        ) ??
        config.getProviderOption<bool>(
          'emit_request_metadata',
        ) ??
        false;
    final requestMetadata = emitRequestMetadata
        ? LLMRequestMetadataPart(
            body: sanitizeRequestBodyForMetadata(requestBody),
          )
        : null;
    final responseWithHeaders = await client.postJsonWithHeaders(
      responsesEndpoint,
      requestBody,
      headers: callOptions.headers,
      cancelToken: cancelToken,
    );
    return _parseResponse(
      responseWithHeaders.json,
      toolNameMapping: builtRequest.toolNameMapping,
      responseHeaders: responseWithHeaders.headers,
      requestMetadata: requestMetadata,
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
    final emitRequestMetadata = config.getProviderOption<bool>(
          'emitRequestMetadata',
        ) ??
        config.getProviderOption<bool>(
          'emit_request_metadata',
        ) ??
        false;
    final requestMetadata = emitRequestMetadata
        ? LLMRequestMetadataPart(
            body: sanitizeRequestBodyForMetadata(builtRequest.body),
          )
        : null;
    final responseWithHeaders = await client.postJsonWithHeaders(
      responsesEndpoint,
      builtRequest.body,
    );
    return _parseResponse(
      responseWithHeaders.json,
      toolNameMapping: builtRequest.toolNameMapping,
      responseHeaders: responseWithHeaders.headers,
      requestMetadata: requestMetadata,
    );
  }

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) async* {
    yield* chatStreamPartsWithCallOptions(
      messages,
      tools: tools,
      providerTools: providerTools,
      callOptions: const LLMCallOptions(),
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<LLMStreamPart> chatStreamPartsWithCallOptions(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    List<ProviderTool>? providerTools,
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) async* {
    yield const LLMStreamStartPart();
    final builtRequest = _buildRequest(
      messages,
      tools,
      true,
      false,
      providerTools: providerTools,
    );
    var requestBody = Map<String, dynamic>.from(builtRequest.body);
    requestBody = callOptions.mergeIntoRequestBody(requestBody);
    final effectiveBuiltRequest = _OpenAIResponsesBuiltRequest(
      body: requestBody,
      toolNameMapping: builtRequest.toolNameMapping,
      providerTools: builtRequest.providerTools,
    );
    yield* _chatStreamPartsFromBuiltRequest(
      effectiveBuiltRequest,
      requestHeaders: callOptions.headers,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<LLMStreamPart> chatPromptStreamParts(
    Prompt prompt, {
    List<Tool>? tools,
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) async* {
    yield* chatPromptStreamPartsWithCallOptions(
      prompt,
      tools: tools,
      providerTools: providerTools,
      callOptions: const LLMCallOptions(),
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<LLMStreamPart> chatPromptStreamPartsWithCallOptions(
    Prompt prompt, {
    List<Tool>? tools,
    List<ProviderTool>? providerTools,
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) async* {
    yield const LLMStreamStartPart();
    final builtRequest = _buildPromptRequest(
      prompt,
      tools,
      true,
      false,
      providerTools: providerTools,
    );
    var requestBody = Map<String, dynamic>.from(builtRequest.body);
    requestBody = callOptions.mergeIntoRequestBody(requestBody);
    final effectiveBuiltRequest = _OpenAIResponsesBuiltRequest(
      body: requestBody,
      toolNameMapping: builtRequest.toolNameMapping,
      providerTools: builtRequest.providerTools,
    );
    yield* _chatStreamPartsFromBuiltRequest(
      effectiveBuiltRequest,
      requestHeaders: callOptions.headers,
      cancelToken: cancelToken,
    );
  }

  Stream<LLMStreamPart> _chatStreamPartsFromBuiltRequest(
    _OpenAIResponsesBuiltRequest builtRequest, {
    Map<String, String>? requestHeaders,
    CancelToken? cancelToken,
  }) async* {
    final toolNameMapping = builtRequest.toolNameMapping;
    final requestProviderTools = builtRequest.providerTools;

    _resetStreamState();

    var inText = false;
    var inThinking = false;

    String? currentTextBlockId;
    String? currentThinkingBlockId;
    var blockCounter = 0;

    final activeToolCalls = <String>{};
    final toolCallArgsById = <String, StringBuffer>{};
    final endedToolCalls = <String>{};
    final providerToolParts = ProviderToolPartEmitter(
      providerMetadataNamespace: config.providerId,
    );
    final emittedProviderApprovalRequests = <String>{};
    final emittedReasoningItems = <String>{};
    final endedReasoningItems = <String>{};
    final reasoningItemsWithSummaries = <String>{};

    // Tool-input streaming state for provider-triggered tools that stream
    // structured inputs via dedicated delta events (AI SDK parity).
    final codeInterpreterCodeByToolCallId = <String, StringBuffer>{};
    final codeInterpreterCodeDeltasByToolCallId = <String, List<String>>{};
    final codeInterpreterContainerIdByToolCallId = <String, String>{};
    final codeInterpreterToolNameByToolCallId = <String, String>{};
    final startedCodeInterpreterToolInput = <String>{};

    final applyPatchDiffByItemId = <String, StringBuffer>{};
    final applyPatchDiffDeltasByItemId = <String, List<String>>{};
    final applyPatchCallIdByItemId = <String, String>{};
    final applyPatchToolNameByItemId = <String, String>{};
    final applyPatchOperationByItemId = <String, Map<String, dynamic>>{};
    final startedApplyPatchToolInput = <String>{};

    String jsonStringFragment(String value) {
      if (value.isEmpty) return '';
      final encoded = jsonEncode(value);
      if (encoded.length >= 2 &&
          encoded.startsWith('"') &&
          encoded.endsWith('"')) {
        return encoded.substring(1, encoded.length - 1);
      }
      return value;
    }

    Iterable<LLMToolInputDeltaPart> drainCodeInterpreterToolInputDeltas(
      String toolCallId,
    ) sync* {
      final pending = codeInterpreterCodeDeltasByToolCallId[toolCallId];
      if (pending == null || pending.isEmpty) return;

      final copy = List<String>.from(pending);
      pending.clear();

      for (final delta in copy) {
        if (delta.isEmpty) continue;
        yield LLMToolInputDeltaPart(
          id: toolCallId,
          delta: jsonStringFragment(delta),
        );
      }
    }

    Iterable<LLMToolInputDeltaPart> drainApplyPatchToolInputDeltas({
      required String itemId,
      required String toolCallId,
    }) sync* {
      final pending = applyPatchDiffDeltasByItemId[itemId];
      if (pending == null || pending.isEmpty) return;

      final copy = List<String>.from(pending);
      pending.clear();

      for (final delta in copy) {
        if (delta.isEmpty) continue;
        yield LLMToolInputDeltaPart(
          id: toolCallId,
          delta: jsonStringFragment(delta),
        );
      }
    }

    var mcpApprovalSeq = 0;
    final mcpApprovalToolCallIdByApprovalId = <String, String>{};

    var didFinish = false;
    var didEmitResponseMetadata = false;
    final emitProviderToolDeltas =
        config.originalConfig?.getProviderOption<bool>(
              config.providerId,
              'emitProviderToolDeltas',
            ) ??
            false;
    final emitRequestMetadata = config.getProviderOption<bool>(
          'emitRequestMetadata',
        ) ??
        config.getProviderOption<bool>(
          'emit_request_metadata',
        ) ??
        false;

    try {
      if (emitRequestMetadata) {
        yield LLMRequestMetadataPart(
          body: sanitizeRequestBodyForMetadata(builtRequest.body),
        );
      }

      final streamed = await client.postStreamRawWithHeaders(
        responsesEndpoint,
        builtRequest.body,
        headers: requestHeaders,
        cancelToken: cancelToken,
      );
      final responseHeaders = streamed.headers;
      final stream = streamed.stream;

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
                  headers: responseHeaders.isEmpty ? null : responseHeaders,
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
                  final toolType =
                      rawToolType.substring(0, rawToolType.length - 5);

                  // AI SDK parity: emit preliminary tool results for streamed
                  // image generation partials.
                  if (rawToolType == 'image_generation_call' &&
                      status == 'partial_image') {
                    final partial = json['partial_image_b64'];
                    if (partial is String && partial.isNotEmpty) {
                      final toolName = resolveProviderToolName(
                        providerId: config.providerId,
                        rawToolName: toolType,
                        providerTools: requestProviderTools,
                      );

                      yield LLMProviderToolResultPart(
                        toolCallId: toolCallId,
                        toolName: toolName,
                        result: {'result': partial},
                        preliminary: true,
                      );
                      continue;
                    }
                  }

                  if (emitProviderToolDeltas) {
                    final evt = parseResponsesToolDeltaEvent(
                      eventType: eventType,
                      json: json,
                    );
                    if (evt != null) {
                      yield providerToolDeltaPartFromResponsesEvent(
                        providerId: config.providerId,
                        event: evt,
                        providerTools: requestProviderTools,
                        data: json,
                        providerMetadataPayload: {'type': eventType},
                      );
                    }
                  }
                }
              }
            }
          }

          // OpenAI Responses: code interpreter streams code via dedicated delta
          // events. AI SDK models this as tool-input deltas that build a JSON
          // string for the tool-call input.
          if (eventType == 'response.code_interpreter_call_code.delta') {
            final toolCallId = json['item_id'] as String?;
            final delta = json['delta'] as String?;
            if (toolCallId == null ||
                toolCallId.isEmpty ||
                delta == null ||
                delta.isEmpty) {
              continue;
            }

            codeInterpreterCodeByToolCallId
                .putIfAbsent(toolCallId, () => StringBuffer())
                .write(delta);

            // Robustness: if deltas arrive before `output_item.added`, buffer
            // them and emit after the tool-input-start boundary is known.
            if (startedCodeInterpreterToolInput.contains(toolCallId)) {
              yield LLMToolInputDeltaPart(
                id: toolCallId,
                delta: jsonStringFragment(delta),
              );
            } else {
              (codeInterpreterCodeDeltasByToolCallId[toolCallId] ??= <String>[])
                  .add(delta);
            }
            continue;
          }

          // OpenAI Responses: apply_patch streams `operation.diff` deltas.
          if (eventType == 'response.apply_patch_call_operation_diff.delta') {
            final itemId = json['item_id'] as String?;
            final delta = json['delta'] as String?;
            if (itemId == null ||
                itemId.isEmpty ||
                delta == null ||
                delta.isEmpty) {
              continue;
            }

            applyPatchDiffByItemId
                .putIfAbsent(itemId, () => StringBuffer())
                .write(delta);

            final callId = applyPatchCallIdByItemId[itemId];
            if (callId == null || callId.isEmpty) {
              (applyPatchDiffDeltasByItemId[itemId] ??= <String>[]).add(delta);
              continue;
            }

            // Robustness: if deltas arrive before `output_item.added`, buffer
            // them and emit after the tool-input-start boundary is known.
            if (startedApplyPatchToolInput.contains(callId)) {
              yield LLMToolInputDeltaPart(
                id: callId,
                delta: jsonStringFragment(delta),
              );
            } else {
              (applyPatchDiffDeltasByItemId[itemId] ??= <String>[]).add(delta);
            }
            continue;
          }

          if (eventType == 'response.apply_patch_call_operation_diff.done') {
            final itemId = json['item_id'] as String?;
            final diff = json['diff'] as String?;
            if (itemId == null || itemId.isEmpty || diff == null) continue;

            final buf = applyPatchDiffByItemId.putIfAbsent(
              itemId,
              () => StringBuffer(),
            );
            if (buf.isEmpty) {
              buf.write(diff);
            }
            continue;
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

            // Emit reasoning block boundaries even if the reasoning content is
            // empty (AI SDK v3 parity). Responses can emit `reasoning` items
            // with only summaries/encrypted content.
            if (item is Map && item['type'] == 'reasoning') {
              final itemId = item['id'] as String? ?? '';
              if (itemId.isNotEmpty) {
                final blockId = '$itemId:0';
                final pm = <String, dynamic>{
                  config.providerId: {
                    'itemId': itemId,
                    'reasoningEncryptedContent':
                        _reasoningEncryptedByItemId[itemId],
                  },
                };

                if (eventType == 'response.output_item.done' &&
                    !reasoningItemsWithSummaries.contains(itemId)) {
                  if (emittedReasoningItems.add(itemId)) {
                    yield LLMReasoningStartPart(
                      blockId: blockId,
                      providerMetadata: pm,
                    );
                  }

                  if (endedReasoningItems.add(itemId)) {
                    yield LLMReasoningEndPart(
                      '',
                      blockId: blockId,
                      providerMetadata: pm,
                    );
                  }
                }
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
                final approvalId = item['id'] as String? ?? '';
                if (approvalId.isNotEmpty) {
                  final toolCallId =
                      mcpApprovalToolCallIdByApprovalId.putIfAbsent(
                    approvalId,
                    () => 'id-${mcpApprovalSeq++}',
                  );

                  final rawName = item['name'] as String? ?? 'mcp';
                  final toolName =
                      rawName.startsWith('mcp.') ? rawName : 'mcp.$rawName';

                  final argsRaw = item['arguments'] as String?;
                  Object? parsedArgs;
                  if (argsRaw != null && argsRaw.isNotEmpty) {
                    try {
                      parsedArgs = jsonDecode(argsRaw);
                    } catch (_) {
                      parsedArgs = argsRaw;
                    }
                  } else {
                    parsedArgs = const <String, dynamic>{};
                  }

                  final callPart = providerToolParts.call(
                    toolCallId: toolCallId,
                    toolName: toolName,
                    input: parsedArgs,
                    providerExecuted: true,
                    isDynamic: true,
                  );
                  if (callPart != null) yield callPart;

                  if (emittedProviderApprovalRequests.add(approvalId)) {
                    yield LLMProviderToolApprovalRequestPart(
                      approvalId: approvalId,
                      toolCallId: toolCallId,
                      toolName: toolName,
                      input: parsedArgs,
                      providerMetadata: {
                        config.providerId: {
                          if (item['server_label'] is String)
                            'serverLabel': item['server_label'],
                        },
                      },
                    );
                  }
                }
              }

              if (rawType is String &&
                  rawType.endsWith('_call') &&
                  rawType != 'function_call') {
                final id = item['id'] as String? ?? '';
                if (id.isNotEmpty) {
                  final toolType = rawType.substring(0, rawType.length - 5);

                  // Dynamic MCP tool calls have different semantics in AI SDK:
                  // - toolName includes the MCP tool name (e.g. `mcp.foo`)
                  // - input comes from streamed `arguments`
                  // - no tool-input-* boundaries are emitted
                  if (toolType == 'mcp') {
                    final rawName = item['name'] as String? ?? 'mcp';
                    final toolName =
                        rawName.startsWith('mcp.') ? rawName : 'mcp.$rawName';
                    final argsRaw = item['arguments'] as String?;
                    Object? parsedArgs;
                    if (argsRaw != null && argsRaw.isNotEmpty) {
                      try {
                        parsedArgs = jsonDecode(argsRaw);
                      } catch (_) {
                        parsedArgs = argsRaw;
                      }
                    } else {
                      parsedArgs = const <String, dynamic>{};
                    }

                    if (eventType == 'response.output_item.added') {
                      final part = providerToolParts.call(
                        toolCallId: id,
                        toolName: toolName,
                        input: parsedArgs,
                        providerExecuted: true,
                        isDynamic: true,
                        providerMetadataPayload: {
                          if (item['server_label'] is String)
                            'serverLabel': item['server_label'],
                          if (item['id'] is String) 'itemId': item['id'],
                        },
                      );
                      if (part != null) yield part;
                    } else if (eventType == 'response.output_item.done') {
                      final callPart = providerToolParts.call(
                        toolCallId: id,
                        toolName: toolName,
                        input: parsedArgs,
                        providerExecuted: true,
                        isDynamic: true,
                        providerMetadataPayload: {
                          if (item['server_label'] is String)
                            'serverLabel': item['server_label'],
                          if (item['id'] is String) 'itemId': item['id'],
                        },
                      );
                      if (callPart != null) yield callPart;

                      final resultPart = providerToolParts.result(
                        toolCallId: id,
                        toolName: toolName,
                        result: item.map<String, dynamic>(
                          (key, value) => MapEntry(key.toString(), value),
                        ),
                        isDynamic: true,
                        providerMetadataPayload: {
                          if (item['server_label'] is String)
                            'serverLabel': item['server_label'],
                          if (item['id'] is String) 'itemId': item['id'],
                        },
                      );
                      if (resultPart != null) yield resultPart;
                    }
                    continue;
                  }

                  final resolvedToolName = resolveProviderToolName(
                    providerId: config.providerId,
                    rawToolName: toolType,
                    providerTools: requestProviderTools,
                  );
                  final providerTool = findProviderToolByRawName(
                    providerId: config.providerId,
                    rawToolName: toolType,
                    providerTools: requestProviderTools,
                  );
                  final supportsDeferredResults =
                      providerTool?.supportsDeferredResults == true
                          ? true
                          : null;

                  final callId = item['call_id'] as String?;
                  final toolCallId =
                      (callId != null && callId.isNotEmpty) ? callId : id;

                  Object resolvedCallInput = const <String, dynamic>{};
                  Map<String, dynamic>? callProviderMetadataPayload;

                  if (toolType == 'local_shell' || toolType == 'shell') {
                    resolvedCallInput = {
                      'action': item['action'],
                    };
                    callProviderMetadataPayload = {'itemId': id};
                  }

                  if (toolType == 'apply_patch') {
                    callProviderMetadataPayload = {'itemId': id};
                  }

                  Object? resolvedResultPayload(Map item) {
                    switch (toolType) {
                      case 'web_search':
                        final action = item['action'];
                        if (action is! Map) {
                          return const <String, dynamic>{
                            'action': null,
                            'sources': <Object>[],
                          };
                        }

                        final sourcesRaw = action['sources'];
                        final sources = <Map<String, dynamic>>[];
                        if (sourcesRaw is List) {
                          for (final s in sourcesRaw) {
                            if (s is! Map) continue;
                            if (s['type'] != 'url') continue;
                            final url = s['url'];
                            if (url is! String || url.isEmpty) continue;
                            sources.add({'type': 'url', 'url': url});
                          }
                        }

                        final actionCopy = action.map<String, dynamic>(
                          (k, v) => MapEntry(k.toString(), v),
                        );
                        actionCopy.remove('sources');

                        return {
                          'action': actionCopy,
                          'sources': sources,
                        };

                      case 'file_search':
                        return {
                          'queries': item['queries'],
                          'results': item['results'],
                        };

                      case 'image_generation':
                        return {'result': item['result']};

                      case 'code_interpreter':
                        return {'outputs': item['outputs']};

                      case 'local_shell':
                      case 'shell':
                        // No tool-result is emitted for shell tools in AI SDK.
                        return null;

                      case 'apply_patch':
                        // No tool-result is emitted for apply_patch tools in AI SDK.
                        return null;

                      default:
                        return item.map<String, dynamic>(
                          (key, value) => MapEntry(key.toString(), value),
                        );
                    }
                  }

                  if (eventType == 'response.output_item.added') {
                    if (toolType == 'local_shell' || toolType == 'shell') {
                      // Shell tools only become meaningful once the provider
                      // supplies the final action (command/env) on `done`.
                      continue;
                    }

                    if (toolType == 'code_interpreter') {
                      final containerId = item['container_id'];
                      if (containerId is String && containerId.isNotEmpty) {
                        codeInterpreterContainerIdByToolCallId[toolCallId] =
                            containerId;
                      }
                      codeInterpreterToolNameByToolCallId[toolCallId] =
                          resolvedToolName;

                      yield LLMToolInputStartPart(
                        id: toolCallId,
                        toolName: resolvedToolName,
                        providerExecuted: true,
                      );
                      yield LLMToolInputDeltaPart(
                        id: toolCallId,
                        delta:
                            '{"containerId":${jsonEncode(codeInterpreterContainerIdByToolCallId[toolCallId] ?? '')},"code":"',
                      );

                      startedCodeInterpreterToolInput.add(toolCallId);
                      for (final part
                          in drainCodeInterpreterToolInputDeltas(toolCallId)) {
                        yield part;
                      }
                      continue;
                    }

                    if (toolType == 'apply_patch') {
                      applyPatchCallIdByItemId[id] = toolCallId;
                      applyPatchToolNameByItemId[id] = resolvedToolName;

                      final opRaw = item['operation'];
                      final op = opRaw is Map
                          ? opRaw.map<String, dynamic>(
                              (k, v) => MapEntry(k.toString(), v),
                            )
                          : const <String, dynamic>{};
                      applyPatchOperationByItemId[id] = op;

                      yield LLMToolInputStartPart(
                        id: toolCallId,
                        toolName: resolvedToolName,
                      );

                      final opType = op['type'];
                      final path = op['path'];
                      final hasDiff = op.containsKey('diff');

                      if (hasDiff) {
                        yield LLMToolInputDeltaPart(
                          id: toolCallId,
                          delta:
                              '{"callId":${jsonEncode(toolCallId)},"operation":{"type":${jsonEncode(opType)},"path":${jsonEncode(path)},"diff":"',
                        );

                        startedApplyPatchToolInput.add(toolCallId);
                        for (final part in drainApplyPatchToolInputDeltas(
                          itemId: id,
                          toolCallId: toolCallId,
                        )) {
                          yield part;
                        }
                      } else {
                        final input = jsonEncode({
                          'callId': toolCallId,
                          'operation': {
                            'type': opType,
                            'path': path,
                          },
                        });
                        yield LLMToolInputDeltaPart(
                          id: toolCallId,
                          delta: input,
                        );
                        yield LLMToolInputEndPart(id: toolCallId);
                        startedApplyPatchToolInput.add(toolCallId);
                      }
                      continue;
                    }

                    final part = providerToolParts.call(
                      toolCallId: toolCallId,
                      toolName: resolvedToolName,
                      input: resolvedCallInput,
                      providerExecuted: toolType != 'local_shell' &&
                          toolType != 'shell' &&
                          toolType != 'apply_patch',
                      supportsDeferredResults: supportsDeferredResults,
                      providerMetadataPayload: callProviderMetadataPayload,
                    );
                    if (part != null) {
                      if (toolType == 'web_search') {
                        yield LLMToolInputStartPart(
                          id: toolCallId,
                          toolName: resolvedToolName,
                          providerExecuted: true,
                        );
                        yield LLMToolInputEndPart(id: toolCallId);
                      }
                      yield part;
                    }
                  } else if (eventType == 'response.output_item.done') {
                    if (toolType == 'code_interpreter') {
                      final buf = codeInterpreterCodeByToolCallId[toolCallId];
                      final code = buf?.toString() ??
                          (item['code'] is String
                              ? item['code'] as String
                              : '');
                      final containerId =
                          codeInterpreterContainerIdByToolCallId[toolCallId] ??
                              (item['container_id'] is String
                                  ? item['container_id'] as String
                                  : '');

                      // Robustness: some streams may deliver code deltas before
                      // `output_item.added`. Ensure the tool-input block has a
                      // start boundary before we end it.
                      if (!startedCodeInterpreterToolInput
                          .contains(toolCallId)) {
                        yield LLMToolInputStartPart(
                          id: toolCallId,
                          toolName: resolvedToolName,
                          providerExecuted: true,
                        );
                        yield LLMToolInputDeltaPart(
                          id: toolCallId,
                          delta:
                              '{"containerId":${jsonEncode(containerId)},"code":"',
                        );
                        startedCodeInterpreterToolInput.add(toolCallId);
                        for (final part in drainCodeInterpreterToolInputDeltas(
                            toolCallId)) {
                          yield part;
                        }
                      }

                      yield LLMToolInputDeltaPart(
                        id: toolCallId,
                        delta: '"}',
                      );
                      yield LLMToolInputEndPart(id: toolCallId);

                      final input = jsonEncode({
                        'code': code,
                        'containerId': containerId,
                      });

                      final callPart = providerToolParts.call(
                        toolCallId: toolCallId,
                        toolName: resolvedToolName,
                        input: input,
                        providerExecuted: true,
                        supportsDeferredResults: supportsDeferredResults,
                      );
                      if (callPart != null) yield callPart;

                      final payload = resolvedResultPayload(item);
                      if (payload == null) continue;

                      final resultPart = providerToolParts.result(
                        toolCallId: toolCallId,
                        toolName: resolvedToolName,
                        result: payload,
                      );
                      if (resultPart != null) yield resultPart;
                      continue;
                    }

                    if (toolType == 'apply_patch') {
                      final op = applyPatchOperationByItemId[id] ??
                          (item['operation'] is Map
                              ? (item['operation'] as Map).map<String, dynamic>(
                                  (k, v) => MapEntry(k.toString(), v),
                                )
                              : const <String, dynamic>{});

                      final opType = op['type'];
                      final path = op['path'];
                      final buf = applyPatchDiffByItemId[id];
                      final diff = buf?.toString() ??
                          (op['diff'] is String ? op['diff'] as String : null);

                      final hasDiff = diff != null;
                      if (hasDiff) {
                        // Robustness: some streams may deliver diff deltas
                        // before `output_item.added`. Ensure the tool-input
                        // block has a start boundary before we end it.
                        if (!startedApplyPatchToolInput.contains(toolCallId)) {
                          yield LLMToolInputStartPart(
                            id: toolCallId,
                            toolName: resolvedToolName,
                          );
                          yield LLMToolInputDeltaPart(
                            id: toolCallId,
                            delta:
                                '{"callId":${jsonEncode(toolCallId)},"operation":{"type":${jsonEncode(opType)},"path":${jsonEncode(path)},"diff":"',
                          );
                          startedApplyPatchToolInput.add(toolCallId);
                          for (final part in drainApplyPatchToolInputDeltas(
                            itemId: id,
                            toolCallId: toolCallId,
                          )) {
                            yield part;
                          }
                        }

                        yield LLMToolInputDeltaPart(
                          id: toolCallId,
                          delta: '"}}',
                        );
                        yield LLMToolInputEndPart(id: toolCallId);
                      }

                      final opFinal = <String, dynamic>{
                        'type': opType,
                        'path': path,
                        if (diff != null) 'diff': diff,
                      };
                      final input = jsonEncode({
                        'callId': toolCallId,
                        'operation': opFinal,
                      });

                      final callPart = providerToolParts.call(
                        toolCallId: toolCallId,
                        toolName: resolvedToolName,
                        input: input,
                        providerExecuted: false,
                        providerMetadataPayload: callProviderMetadataPayload,
                      );
                      if (callPart != null) yield callPart;
                      continue;
                    }

                    final callPart = providerToolParts.call(
                      toolCallId: toolCallId,
                      toolName: resolvedToolName,
                      input: resolvedCallInput,
                      providerExecuted: toolType != 'local_shell' &&
                          toolType != 'shell' &&
                          toolType != 'apply_patch',
                      providerMetadataPayload: callProviderMetadataPayload,
                    );
                    if (callPart != null) {
                      if (toolType == 'web_search') {
                        yield LLMToolInputStartPart(
                          id: toolCallId,
                          toolName: resolvedToolName,
                          providerExecuted: true,
                        );
                        yield LLMToolInputEndPart(id: toolCallId);
                      }
                      yield callPart;
                    }

                    final payload = resolvedResultPayload(item);
                    if (payload == null) continue;

                    final resultPart = providerToolParts.result(
                      toolCallId: toolCallId,
                      toolName: resolvedToolName,
                      result: payload,
                    );
                    if (resultPart != null) yield resultPart;
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
                        providerMetadata: null,
                      );
                      if (part != null) yield part;
                    }
                  }
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
                    providerMetadata: null,
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

            reasoningItemsWithSummaries.add(itemId);

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
                    headers: responseHeaders.isEmpty ? null : responseHeaders,
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
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) async {
    return chatWithTools(
      messages,
      null,
      providerTools: providerTools,
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
    List<ProviderTool>? providerTools,
  }) {
    final effectiveTools = tools ?? config.tools;
    final effectiveProviderTools = mergeProviderToolsById(
      config.originalConfig?.providerTools,
      providerTools,
    );
    final builtInToolJson = _mergeToolJsonByType(
      (config.builtInTools ?? const <OpenAIBuiltInTool>[])
          .map((t) => t.toJson())
          .toList(growable: false),
      _openaiBuiltInToolJsonFromProviderTools(effectiveProviderTools),
    );
    final toolNameMapping = _createToolNameMapping(
      effectiveTools,
      builtInToolJson: builtInToolJson,
      providerTools: effectiveProviderTools,
    );
    final body = _buildRequestBody(
      messages,
      effectiveTools,
      stream,
      background,
      toolNameMapping,
      previousResponseId: previousResponseId,
      builtInToolJson: builtInToolJson,
    );

    return _OpenAIResponsesBuiltRequest(
      body: body,
      toolNameMapping: toolNameMapping,
      providerTools: effectiveProviderTools,
    );
  }

  _OpenAIResponsesBuiltRequest _buildPromptRequest(
    Prompt prompt,
    List<Tool>? tools,
    bool stream,
    bool background, {
    String? previousResponseId,
    List<ProviderTool>? providerTools,
  }) {
    final effectiveTools = tools ?? config.tools;
    final effectiveProviderTools = mergeProviderToolsById(
      config.originalConfig?.providerTools,
      providerTools,
    );
    final builtInToolJson = _mergeToolJsonByType(
      (config.builtInTools ?? const <OpenAIBuiltInTool>[])
          .map((t) => t.toJson())
          .toList(growable: false),
      _openaiBuiltInToolJsonFromProviderTools(effectiveProviderTools),
    );
    final toolNameMapping = _createToolNameMapping(
      effectiveTools,
      builtInToolJson: builtInToolJson,
      providerTools: effectiveProviderTools,
    );

    final store = config.getProviderOption<bool>('store') ?? true;
    final apiMessages =
        OpenAIResponsesMessageConverter.buildInputMessagesFromPrompt(
      prompt,
      store: store,
    );
    final body = _buildRequestBodyFromApiMessages(
      apiMessages,
      effectiveTools,
      stream,
      background,
      toolNameMapping,
      previousResponseId: previousResponseId,
      builtInToolJson: builtInToolJson,
    );

    return _OpenAIResponsesBuiltRequest(
      body: body,
      toolNameMapping: toolNameMapping,
      providerTools: effectiveProviderTools,
    );
  }

  ToolNameMapping _createToolNameMapping(
    List<Tool>? tools, {
    required List<Map<String, dynamic>> builtInToolJson,
    List<ProviderTool>? providerTools,
  }) {
    final functionToolNames = (tools ?? const <Tool>[]).map(
      (t) => t.function.name,
    );

    final providerToolRequestNamesById = <String, String>{};
    for (final tool in builtInToolJson) {
      final rawType = tool['type'];
      if (rawType is String && rawType.isNotEmpty) {
        providerToolRequestNamesById['openai.$rawType'] = rawType;
      }
    }

    final toolsForMapping = providerTools ?? const <ProviderTool>[];
    for (final t in toolsForMapping) {
      final id = t.id.trim();
      if (!id.startsWith('openai.')) continue;
      final requestName = _openaiRequestToolTypeForProviderToolId(id);
      if (requestName == null) continue;
      providerToolRequestNamesById[id] = requestName;
    }

    return createToolNameMapping(
      functionToolNames: functionToolNames,
      providerToolRequestNamesById: providerToolRequestNamesById,
    );
  }

  List<Map<String, dynamic>> _mergeToolJsonByType(
    List<Map<String, dynamic>> base,
    List<Map<String, dynamic>> override,
  ) {
    if (base.isEmpty && override.isEmpty) return const [];

    final byType = <String, Map<String, dynamic>>{};
    for (final item in base) {
      final type = item['type'];
      if (type is! String || type.trim().isEmpty) continue;
      byType[type] = Map<String, dynamic>.from(item);
    }
    for (final item in override) {
      final type = item['type'];
      if (type is! String || type.trim().isEmpty) continue;
      byType[type] = Map<String, dynamic>.from(item); // override wins
    }

    return byType.values.toList(growable: false);
  }

  String? _openaiRequestToolTypeForProviderToolId(String id) {
    if (!id.startsWith('openai.')) return null;
    final raw = id.substring('openai.'.length).trim();
    if (raw.isEmpty) return null;
    // Alias: OpenAI's built-in tool type for computer use is `computer_use_preview`.
    if (raw == 'computer_use') return 'computer_use_preview';
    return raw;
  }

  List<Map<String, dynamic>> _openaiBuiltInToolJsonFromProviderTools(
    List<ProviderTool>? providerTools,
  ) {
    final tools = providerTools;
    if (tools == null || tools.isEmpty) return const [];

    Map<String, dynamic> asStringDynamicMap(Object? raw) {
      if (raw is Map<String, dynamic>) return raw;
      if (raw is Map) return raw.cast<String, dynamic>();
      return const <String, dynamic>{};
    }

    List<String>? asStringList(Object? raw) {
      if (raw is! List) return null;
      final out = <String>[];
      for (final item in raw) {
        final s = item?.toString();
        if (s == null) continue;
        final trimmed = s.trim();
        if (trimmed.isEmpty) continue;
        out.add(trimmed);
      }
      return out.isEmpty ? null : out;
    }

    final out = <Map<String, dynamic>>[];

    for (final t in tools) {
      final id = t.id.trim();
      if (!id.startsWith('openai.')) continue;

      final type = _openaiRequestToolTypeForProviderToolId(id);
      if (type == null) continue;

      final options = Map<String, dynamic>.from(t.options);
      final json = <String, dynamic>{'type': type};

      switch (type) {
        case 'web_search_preview':
          final rawContext = options.remove('searchContextSize') ??
              options.remove('search_context_size');
          final ctx = rawContext?.toString();
          final parsed = OpenAIWebSearchContextSize.tryParse(ctx);
          if (parsed != null) {
            json['search_context_size'] = parsed.apiValue;
          } else if (ctx != null && ctx.trim().isNotEmpty) {
            json['search_context_size'] = ctx.trim();
          }
          break;

        case 'web_search':
          final allowedDomains =
              asStringList(options.remove('allowedDomains')) ??
                  asStringList(
                    asStringDynamicMap(options['filters'])['allowed_domains'],
                  ) ??
                  asStringList(options['allowed_domains']);
          if (allowedDomains != null) {
            json['filters'] = {'allowed_domains': allowedDomains};
          }

          final externalWebAccess = options.remove('externalWebAccess') ??
              options.remove('external_web_access');
          if (externalWebAccess is bool) {
            json['external_web_access'] = externalWebAccess;
          }

          final rawContext = options.remove('searchContextSize') ??
              options.remove('search_context_size');
          final ctx = rawContext?.toString();
          final parsed = OpenAIWebSearchContextSize.tryParse(ctx);
          if (parsed != null) {
            json['search_context_size'] = parsed.apiValue;
          } else if (ctx != null && ctx.trim().isNotEmpty) {
            json['search_context_size'] = ctx.trim();
          }

          final userLocation =
              options.remove('userLocation') ?? options.remove('user_location');
          final userLocationMap = asStringDynamicMap(userLocation);
          if (userLocationMap.isNotEmpty) {
            json['user_location'] = userLocationMap;
          }

          final parameters = asStringDynamicMap(options.remove('parameters'));
          if (parameters.isNotEmpty) {
            json.addAll(parameters);
          }
          break;

        case 'file_search':
          final vectorStoreIds =
              asStringList(options.remove('vectorStoreIds')) ??
                  asStringList(options.remove('vector_store_ids'));
          if (vectorStoreIds != null) {
            json['vector_store_ids'] = vectorStoreIds;
          }

          final parameters = asStringDynamicMap(options.remove('parameters'));
          if (parameters.isNotEmpty) {
            json.addAll(parameters);
          }
          break;

        case 'computer_use_preview':
          int? readInt(Object? v) {
            if (v is int) return v;
            if (v is num) return v.toInt();
            return int.tryParse(v?.toString() ?? '');
          }

          final displayWidth = readInt(options.remove('displayWidth') ??
              options.remove('display_width'));
          final displayHeight = readInt(options.remove('displayHeight') ??
              options.remove('display_height'));
          final environment = (options.remove('environment') ?? '').toString();

          if (displayWidth == null ||
              displayHeight == null ||
              environment.trim().isEmpty) {
            throw InvalidRequestError(
              'ProviderTool "$id" requires displayWidth/displayHeight/environment in options.',
            );
          }

          json['display_width'] = displayWidth;
          json['display_height'] = displayHeight;
          json['environment'] = environment.trim();

          final parameters = asStringDynamicMap(options.remove('parameters'));
          if (parameters.isNotEmpty) {
            json.addAll(parameters);
          }
          break;

        case 'code_interpreter':
          final container = options.remove('container');
          if (container != null) {
            json['container'] = container;
          }
          final parameters = asStringDynamicMap(options.remove('parameters'));
          if (parameters.isNotEmpty) {
            json.addAll(parameters);
          }
          break;

        case 'image_generation':
        case 'mcp':
          final parameters = asStringDynamicMap(options.remove('parameters'));
          if (parameters.isNotEmpty) {
            json.addAll(parameters);
          }
          break;

        case 'apply_patch':
        case 'shell':
        case 'local_shell':
          break;
      }

      // Best-effort: forward any remaining tool-specific options.
      if (options.isNotEmpty) {
        json.addAll(options);
      }

      out.add(json);
    }

    return out;
  }

  /// Build request body for Responses API
  Map<String, dynamic> _buildRequestBody(
    List<ChatMessage> messages,
    List<Tool>? tools,
    bool stream,
    bool background,
    ToolNameMapping toolNameMapping, {
    String? previousResponseId,
    required List<Map<String, dynamic>> builtInToolJson,
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
      builtInToolJson: builtInToolJson,
    );
  }

  Map<String, dynamic> _buildRequestBodyFromApiMessages(
    List<Map<String, dynamic>> apiMessages,
    List<Tool>? tools,
    bool stream,
    bool background,
    ToolNameMapping toolNameMapping, {
    String? previousResponseId,
    required List<Map<String, dynamic>> builtInToolJson,
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

    // OpenAI Responses API: store defaults to true when omitted.
    final store = config.getProviderOption<bool>('store');
    if (store != null) {
      body['store'] = store;
    }

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
    if (builtInToolJson.isNotEmpty) {
      final byType = <String, Map<String, dynamic>>{};
      for (final item in builtInToolJson) {
        final type = item['type'];
        if (type is! String || type.isEmpty) continue;
        byType[type] = item;
      }
      allTools.addAll(byType.values);
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

    final hasWebSearchTool = builtInToolJson.any((t) {
      final type = t['type'];
      return type == 'web_search_preview' || type == 'web_search';
    });
    if (hasWebSearchTool) {
      include.add('web_search_call.action.sources');
    }

    final hasFileSearchTool =
        builtInToolJson.any((t) => t['type'] == 'file_search');
    if (hasFileSearchTool) {
      include.add('file_search_call.results');
    }

    final hasComputerUseTool =
        builtInToolJson.any((t) => t['type'] == 'computer_use_preview');
    if (hasComputerUseTool) {
      include.add('computer_call_output.output.image_url');
    }

    final hasCodeInterpreterTool =
        builtInToolJson.any((t) => t['type'] == 'code_interpreter');
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
    Map<String, String>? responseHeaders,
    LLMRequestMetadataPart? requestMetadata,
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

    final createdAt = responseData['created_at'];
    DateTime? timestamp;
    if (createdAt is int) {
      timestamp =
          DateTime.fromMillisecondsSinceEpoch(createdAt * 1000, isUtc: true);
    }

    final idRaw = responseData['id'];
    final id = idRaw is String ? idRaw : idRaw?.toString();
    final modelRaw = responseData['model'];
    final model = modelRaw is String ? modelRaw : null;
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
              )
            : null;

    return OpenAIResponsesResponse(
      responseData,
      thinkingContent,
      toolNameMapping,
      config.providerId,
      responseMetadata,
      requestMetadata,
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
    _sourceParts.reset();
    _streamLogprobs.clear();
    _reasoningEncryptedByItemId.clear();
    _activeReasoningBlockId = null;
  }

  Map<String, dynamic>? _innerProviderMetadataPayload(
    Map<String, dynamic>? providerMetadata,
  ) {
    if (providerMetadata == null) return null;
    final raw = providerMetadata[config.providerId];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is! Map) return null;
    return raw.map<String, dynamic>((k, v) => MapEntry(k.toString(), v));
  }

  LLMSourceUrlPart? _newSourceUrlPart({
    required String url,
    String? title,
    Map<String, dynamic>? providerMetadata,
  }) {
    return _sourceParts.url(
      url,
      title: title,
      providerMetadataPayload: _innerProviderMetadataPayload(providerMetadata),
    );
  }

  LLMSourceDocumentPart? _newSourceDocumentPart({
    required String dedupeKey,
    required String mediaType,
    required String title,
    String? filename,
    Map<String, dynamic>? providerMetadata,
  }) {
    return _sourceParts.document(
      title,
      mediaType: mediaType,
      filename: filename,
      dedupeKey: 'doc:$dedupeKey',
      providerMetadataPayload: _innerProviderMetadataPayload(providerMetadata),
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
class OpenAIResponsesResponse
    implements
        ChatResponseWithFinishReason,
        ChatResponseWithResponseMetadata,
        ChatResponseWithRequestMetadata {
  final Map<String, dynamic> _rawResponse;
  final String? _thinkingContent;
  final ToolNameMapping? _toolNameMapping;
  final String _providerId;
  final LLMResponseMetadataPart? _responseMetadata;
  final LLMRequestMetadataPart? _requestMetadata;

  OpenAIResponsesResponse(
    this._rawResponse, [
    this._thinkingContent,
    this._toolNameMapping,
    String providerId = 'openai',
    LLMResponseMetadataPart? responseMetadata,
    LLMRequestMetadataPart? requestMetadata,
  ])  : _providerId = providerId,
        _responseMetadata = responseMetadata,
        _requestMetadata = requestMetadata;

  @override
  LLMResponseMetadataPart? get responseMetadata => _responseMetadata;

  @override
  LLMRequestMetadataPart? get requestMetadata => _requestMetadata;

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

    return UsageInfo.fromProviderUsage(usageData);
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
