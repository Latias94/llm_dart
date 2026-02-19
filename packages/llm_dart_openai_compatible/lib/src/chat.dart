import 'dart:async';
import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:llm_dart_provider_utils/utils/request_metadata_sanitizer.dart';
import 'client.dart';
import 'openai_request_config.dart';
import 'request_builder.dart';

/// OpenAI Chat capability implementation
///
/// This module handles all chat-related functionality for OpenAI providers,
/// including streaming, tool calling, and reasoning model support.
class OpenAIChat
    implements
        ChatCapability,
        ModelIdentityCapability,
        ChatStreamPartsCapability,
        ChatStreamPartsCallOptionsCapability,
        PromptChatCapability,
        PromptChatCallOptionsCapability,
        PromptChatStreamPartsCapability,
        PromptChatStreamPartsCallOptionsCapability,
        ChatCallOptionsCapability {
  final OpenAIClient client;
  final OpenAIRequestConfig config;
  final OpenAIRequestBuilder _requestBuilder;

  // State tracking for stream processing
  bool _hasReasoningContent = false;
  String _lastChunk = '';
  final ThinkTagSplitter _thinkSplitter = ThinkTagSplitter(tagName: 'think');
  final StringBuffer _thinkingBuffer = StringBuffer();
  final Map<int, String> _toolCallIds = {};

  OpenAIChat(this.client, this.config)
      : _requestBuilder = OpenAIRequestBuilder(config);

  @override
  String get providerId => config.providerId;

  @override
  String get modelId => config.model;

  String get chatEndpoint => 'chat/completions';

  bool _emitRequestMetadataEnabled() {
    return config.getProviderOption<bool>('emitRequestMetadata') ?? false;
  }

  bool _parseToolCallsFromTextEnabled() {
    return config.getProviderOption<bool>('parseToolCallsFromText') ??
        config.getProviderOption<bool>('parse_tool_calls_from_text') ??
        false;
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
    var requestBody = _requestBuilder.buildChatCompletionsRequestBody(
      client,
      messages: messages,
      tools: tools,
      providerTools: providerTools,
      stream: false,
    );
    requestBody = callOptions.mergeIntoRequestBody(requestBody);
    final requestMetadata = _emitRequestMetadataEnabled()
        ? LLMRequestMetadataPart(
            body: sanitizeRequestBodyForMetadata(requestBody),
          )
        : null;
    final responseWithHeaders = await client.postJsonWithHeaders(
      chatEndpoint,
      requestBody,
      headers: callOptions.headers,
      cancelToken: cancelToken,
    );
    return _parseResponse(
      responseWithHeaders.json,
      didRequestTools: tools != null && tools.isNotEmpty,
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
    var requestBody = _requestBuilder.buildChatCompletionsRequestBodyFromPrompt(
      client,
      prompt: prompt,
      tools: tools,
      providerTools: providerTools,
      stream: false,
    );
    requestBody = callOptions.mergeIntoRequestBody(requestBody);
    final requestMetadata = _emitRequestMetadataEnabled()
        ? LLMRequestMetadataPart(
            body: sanitizeRequestBodyForMetadata(requestBody),
          )
        : null;
    final responseWithHeaders = await client.postJsonWithHeaders(
      chatEndpoint,
      requestBody,
      headers: callOptions.headers,
      cancelToken: cancelToken,
    );
    return _parseResponse(
      responseWithHeaders.json,
      didRequestTools: tools != null && tools.isNotEmpty,
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
    final effectiveTools = tools ?? config.tools;
    var requestBody = _requestBuilder.buildChatCompletionsRequestBody(
      client,
      messages: messages,
      tools: effectiveTools,
      providerTools: providerTools,
      stream: true,
    );
    requestBody = callOptions.mergeIntoRequestBody(requestBody);

    yield* _chatStreamPartsFromRequestBody(
      requestBody,
      effectiveTools: effectiveTools,
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
    final effectiveTools = tools ?? config.tools;
    var requestBody = _requestBuilder.buildChatCompletionsRequestBodyFromPrompt(
      client,
      prompt: prompt,
      tools: effectiveTools,
      providerTools: providerTools,
      stream: true,
    );
    requestBody = callOptions.mergeIntoRequestBody(requestBody);

    yield* _chatStreamPartsFromRequestBody(
      requestBody,
      effectiveTools: effectiveTools,
      requestHeaders: callOptions.headers,
      cancelToken: cancelToken,
    );
  }

  Stream<LLMStreamPart> _chatStreamPartsFromRequestBody(
    Map<String, dynamic> requestBody, {
    required List<Tool>? effectiveTools,
    Map<String, String>? requestHeaders,
    CancelToken? cancelToken,
  }) async* {
    client.resetSSEBuffer();
    _resetStreamState();

    var inText = false;
    var inThinking = false;

    final fullText = StringBuffer();
    final fullThinking = StringBuffer();
    final currentText = StringBuffer();
    final currentThinking = StringBuffer();

    String? currentTextBlockId;
    String? currentThinkingBlockId;
    var blockCounter = 0;

    final toolAccums = <String, _ToolCallAccum>{};
    final startedToolCalls = <String>{};
    final endedToolCalls = <String>{};
    final pendingToolAccumsByIndex = <int, _ToolCallAccum>{};

    String? id;
    String? model;
    String? systemFingerprint;
    int? createdSeconds;
    Map<String, dynamic>? usage;
    final citations = <String>[];
    final providerMetadataNamespace = config.providerId.split('.').first;
    final sourceParts = SourcePartEmitter(
      providerMetadataNamespace: providerMetadataNamespace,
    );
    var didEmitResponseMetadata = false;

    var didEmitTerminalParts = false;
    String? finishReason;
    Map<String, dynamic>? lastStreamChunk;

    try {
      if (_emitRequestMetadataEnabled()) {
        yield LLMRequestMetadataPart(
          body: sanitizeRequestBodyForMetadata(requestBody),
        );
      }

      final streamed = await client.postStreamRawWithHeaders(
        chatEndpoint,
        requestBody,
        headers: requestHeaders,
        cancelToken: cancelToken,
      );
      final responseHeaders = streamed.headers;
      final stream = streamed.stream;

      await for (final chunk in stream) {
        final jsonList = client.parseSSEChunk(chunk);
        if (jsonList.isEmpty) continue;

        for (final json in jsonList) {
          lastStreamChunk = json;
          id ??= json['id'] as String?;
          model ??= json['model'] as String?;
          systemFingerprint ??= json['system_fingerprint'] as String?;
          createdSeconds ??=
              json['created'] is int ? json['created'] as int : null;

          if (!didEmitResponseMetadata &&
              (id != null || model != null || systemFingerprint != null)) {
            didEmitResponseMetadata = true;
            final raw = <String, dynamic>{
              if (id != null) 'id': id,
              if (createdSeconds != null) 'created': createdSeconds,
              if (model != null) 'model': model,
              if (systemFingerprint != null)
                'system_fingerprint': systemFingerprint,
            };
            yield LLMResponseMetadataPart(
              id: id,
              timestamp: createdSeconds == null
                  ? null
                  : DateTime.fromMillisecondsSinceEpoch(
                      createdSeconds * 1000,
                      isUtc: true,
                    ),
              modelId: model,
              headers: responseHeaders.isEmpty ? null : responseHeaders,
              systemFingerprint: systemFingerprint,
              raw: raw.isEmpty ? null : raw,
            );
          }

          // xAI citations (top-level `citations` array of URL strings).
          // Emit as source parts (deduped) to match AI SDK semantics.
          final providerId = config.providerId;
          final isXai = providerId == 'xai' || providerId == 'xai-openai';
          final rawCitations = json['citations'];
          if (isXai && rawCitations is List) {
            for (final c in rawCitations) {
              if (c is! String) continue;
              final url = c.trim();
              if (url.isEmpty) continue;
              final part = sourceParts.url(
                url,
                providerMetadataPayload: const {'type': 'citation'},
              );
              if (part == null) continue;
              citations.add(url);
              yield part;
            }
          }

          final rawUsage = json['usage'];
          if (rawUsage is Map<String, dynamic>) {
            usage = {...?usage, ...rawUsage};
          } else if (rawUsage is Map) {
            usage = {...?usage, ...Map<String, dynamic>.from(rawUsage)};
          }

          final choices = json['choices'] as List?;
          if (choices == null || choices.isEmpty) continue;

          final choice = choices.first as Map<String, dynamic>;
          final delta = choice['delta'] as Map<String, dynamic>?;

          // After a finish_reason has been observed, some providers (e.g. Azure)
          // may still stream trailing chunks containing `usage` with empty
          // `choices`. Ignore any post-finish deltas.
          if (finishReason != null) {
            continue;
          }

          // Reasoning/thinking content (provider-specific fields).
          final reasoningContent =
              ReasoningUtils.extractReasoningContent(delta);
          if (reasoningContent != null && reasoningContent.isNotEmpty) {
            if (inText) {
              inText = false;
              yield LLMTextEndPart(
                currentText.toString(),
                blockId: currentTextBlockId,
              );
              currentText.clear();
              currentTextBlockId = null;
            }
            if (!inThinking) {
              inThinking = true;
              currentThinkingBlockId ??= '${blockCounter++}';
              yield LLMReasoningStartPart(blockId: currentThinkingBlockId);
              currentThinking.clear();
            }
            fullThinking.write(reasoningContent);
            currentThinking.write(reasoningContent);
            yield LLMReasoningDeltaPart(
              reasoningContent,
              blockId: currentThinkingBlockId,
            );
          }

          // Text content (may include <think> tags).
          final content = delta?['content'] as String?;
          if (content != null && content.isNotEmpty) {
            _lastChunk = content;

            final pieces = _thinkSplitter.splitDelta(content);
            for (final piece in pieces) {
              switch (piece) {
                case ThinkTagTextPiece(:final text):
                  if (text.isEmpty) continue;
                  if (inThinking) {
                    inThinking = false;
                    yield LLMReasoningEndPart(
                      currentThinking.toString(),
                      blockId: currentThinkingBlockId,
                    );
                    currentThinking.clear();
                    currentThinkingBlockId = null;
                  }
                  final reasoningResult = ReasoningUtils.checkReasoningStatus(
                    delta: delta,
                    hasReasoningContent: _hasReasoningContent,
                    lastChunk: _lastChunk,
                  );
                  _hasReasoningContent = reasoningResult.hasReasoningContent;

                  if (!inText) {
                    inText = true;
                    currentTextBlockId ??= '${blockCounter++}';
                    yield LLMTextStartPart(blockId: currentTextBlockId);
                    currentText.clear();
                  }
                  fullText.write(text);
                  currentText.write(text);
                  yield LLMTextDeltaPart(text, blockId: currentTextBlockId);
                case ThinkTagThinkingStartPiece():
                  if (inText) {
                    inText = false;
                    yield LLMTextEndPart(
                      currentText.toString(),
                      blockId: currentTextBlockId,
                    );
                    currentText.clear();
                    currentTextBlockId = null;
                  }
                  if (!inThinking) {
                    inThinking = true;
                    currentThinkingBlockId ??= '${blockCounter++}';
                    yield LLMReasoningStartPart(
                      blockId: currentThinkingBlockId,
                    );
                    currentThinking.clear();
                  }
                case ThinkTagThinkingPiece(:final thinking):
                  if (thinking.isEmpty) continue;
                  if (inText) {
                    inText = false;
                    yield LLMTextEndPart(
                      currentText.toString(),
                      blockId: currentTextBlockId,
                    );
                    currentText.clear();
                    currentTextBlockId = null;
                  }
                  if (!inThinking) {
                    inThinking = true;
                    currentThinkingBlockId ??= '${blockCounter++}';
                    yield LLMReasoningStartPart(
                      blockId: currentThinkingBlockId,
                    );
                    currentThinking.clear();
                  }
                  fullThinking.write(thinking);
                  currentThinking.write(thinking);
                  yield LLMReasoningDeltaPart(
                    thinking,
                    blockId: currentThinkingBlockId,
                  );
                case ThinkTagThinkingEndPiece():
                  if (inThinking) {
                    inThinking = false;
                    yield LLMReasoningEndPart(
                      currentThinking.toString(),
                      blockId: currentThinkingBlockId,
                    );
                    currentThinking.clear();
                    currentThinkingBlockId = null;
                  }
              }
            }
          }

          // Tool calls (client-side function tools).
          final toolCalls = delta?['tool_calls'] as List?;
          if (toolCalls != null && toolCalls.isNotEmpty) {
            for (final rawCall in toolCalls) {
              if (rawCall is! Map<String, dynamic>) continue;

              final index = rawCall['index'] as int?;
              if (index != null) {
                final callId = rawCall['id'] as String?;
                final existingId = _toolCallIds[index];
                if ((existingId == null || existingId.isEmpty) &&
                    callId != null &&
                    callId.isNotEmpty) {
                  _toolCallIds[index] = callId;
                }

                final stableId = _toolCallIds[index];

                final functionMap =
                    rawCall['function'] as Map<String, dynamic>?;
                if (functionMap == null) continue;

                final name = functionMap['name'] as String? ?? '';
                final args = functionMap['arguments'] as String? ?? '';
                if (name.isEmpty && args.isEmpty) continue;

                // Some providers may omit `id` in early tool_call deltas.
                // Buffer those deltas by index until an id becomes available.
                if (stableId == null || stableId.isEmpty) {
                  final pending = pendingToolAccumsByIndex.putIfAbsent(
                    index,
                    _ToolCallAccum.new,
                  );
                  if (name.isNotEmpty) pending.name = name;
                  if (args.isNotEmpty) pending.arguments.write(args);
                  final thoughtSignature =
                      _extractThoughtSignatureFromExtraContent(rawCall);
                  if (thoughtSignature != null) {
                    pending.thoughtSignature ??= thoughtSignature;
                  }
                  continue;
                }

                V3ToolCall toolCallForDelta({
                  required String id,
                  required String name,
                  required String arguments,
                  required String? thoughtSignature,
                }) {
                  if (thoughtSignature == null ||
                      thoughtSignature.isEmpty ||
                      config.providerId.isEmpty) {
                    return V3ToolCall(
                      toolCallId: id,
                      toolName: name,
                      input: arguments,
                    );
                  }
                  return V3ToolCall(
                    toolCallId: id,
                    toolName: name,
                    input: arguments,
                    providerOptions: {
                      config.providerId: {
                        'thoughtSignature': thoughtSignature,
                      },
                    },
                  );
                }

                // Flush any buffered deltas for this index now that we have an id.
                final pending = pendingToolAccumsByIndex.remove(index);
                if (pending != null) {
                  final accum = toolAccums.putIfAbsent(
                    stableId,
                    _ToolCallAccum.new,
                  );

                  if ((accum.name == null || accum.name!.isEmpty) &&
                      pending.name != null &&
                      pending.name!.isNotEmpty) {
                    accum.name = pending.name;
                  }
                  if (pending.thoughtSignature != null) {
                    accum.thoughtSignature ??= pending.thoughtSignature;
                  }

                  final pendingArgs = pending.arguments.toString();
                  if (pendingArgs.isNotEmpty) {
                    accum.arguments.write(pendingArgs);
                  }

                  final resolvedName = (accum.name ?? name).trim().isEmpty
                      ? name
                      : (accum.name ?? name);

                  if (startedToolCalls.add(stableId)) {
                    yield LLMToolCallStartPart(
                      toolCallForDelta(
                        id: stableId,
                        name: resolvedName,
                        arguments: '',
                        thoughtSignature: accum.thoughtSignature,
                      ),
                    );
                  }

                  if (pendingArgs.isNotEmpty) {
                    yield LLMToolCallDeltaPart(
                      toolCallForDelta(
                        id: stableId,
                        name: resolvedName,
                        arguments: pendingArgs,
                        thoughtSignature: accum.thoughtSignature,
                      ),
                    );
                  }
                }

                final accum =
                    toolAccums.putIfAbsent(stableId, () => _ToolCallAccum());
                if (name.isNotEmpty) {
                  accum.name = name;
                }
                if (args.isNotEmpty) {
                  accum.arguments.write(args);
                }
                final thoughtSignature =
                    _extractThoughtSignatureFromExtraContent(rawCall);
                if (thoughtSignature != null) {
                  accum.thoughtSignature ??= thoughtSignature;
                }

                final resolvedName =
                    name.isNotEmpty ? name : (accum.name ?? '');
                final toolCall = toolCallForDelta(
                  id: stableId,
                  name: resolvedName,
                  arguments: args,
                  thoughtSignature: accum.thoughtSignature,
                );

                if (startedToolCalls.add(stableId)) {
                  yield LLMToolCallStartPart(toolCall);
                } else {
                  yield LLMToolCallDeltaPart(toolCall);
                }

                final fullArgs = accum.arguments.toString();
                if (fullArgs.isNotEmpty && isParsableJson(fullArgs)) {
                  if (endedToolCalls.add(stableId)) {
                    yield LLMToolCallEndPart(stableId);
                  }
                }
              } else if (rawCall.containsKey('id') &&
                  rawCall.containsKey('function')) {
                try {
                  final parsed = ToolCall.fromJson(rawCall);
                  final thoughtSignature =
                      _extractThoughtSignatureFromExtraContent(rawCall);
                  final toolCall = thoughtSignature == null ||
                          thoughtSignature.isEmpty ||
                          config.providerId.isEmpty
                      ? V3ToolCall.fromLegacyToolCall(parsed)
                      : V3ToolCall(
                          toolCallId: parsed.id,
                          toolName: parsed.function.name,
                          input: parsed.function.arguments,
                          providerOptions: {
                            ...parsed.providerOptions,
                            config.providerId: {
                              ...?parsed.providerOptions[config.providerId],
                              'thoughtSignature': thoughtSignature,
                            },
                          },
                        );
                  if (endedToolCalls.contains(toolCall.toolCallId)) continue;
                  final accum = toolAccums.putIfAbsent(
                    toolCall.toolCallId,
                    () => _ToolCallAccum(),
                  );
                  if (toolCall.toolName.isNotEmpty) {
                    accum.name = toolCall.toolName;
                  }
                  if (toolCall.input.isNotEmpty) {
                    accum.arguments.write(toolCall.input);
                  }
                  if (thoughtSignature != null) {
                    accum.thoughtSignature ??= thoughtSignature;
                  }

                  if (startedToolCalls.add(toolCall.toolCallId)) {
                    yield LLMToolCallStartPart(toolCall);
                  } else {
                    yield LLMToolCallDeltaPart(toolCall);
                  }

                  final fullArgs = accum.arguments.toString();
                  if (fullArgs.isNotEmpty && isParsableJson(fullArgs)) {
                    if (endedToolCalls.add(toolCall.toolCallId)) {
                      yield LLMToolCallEndPart(toolCall.toolCallId);
                    }
                  }
                } catch (_) {
                  // Ignore malformed tool calls.
                }
              }
            }
          }

          // URL citations/annotations (best-effort).
          //
          // Some providers emit `annotations` in the Chat Completions delta
          // stream. Mirror AI SDK behavior by emitting them as typed source parts.
          final annotations = delta?['annotations'] as List?;
          if (annotations != null && annotations.isNotEmpty) {
            for (final raw in annotations) {
              if (raw is! Map) continue;
              final urlCitation = raw['url_citation'];
              if (urlCitation is! Map) continue;
              final url = urlCitation['url'];
              if (url is! String) continue;
              final trimmed = url.trim();
              if (trimmed.isEmpty) continue;

              final title = urlCitation['title'];
              final part = sourceParts.url(
                trimmed,
                title: title is String && title.trim().isNotEmpty
                    ? title.trim()
                    : null,
                providerMetadataPayload: const {'type': 'url_citation'},
              );
              if (part != null) yield part;
            }
          }

          // Finish.
          final fr = choice['finish_reason'] as String?;
          if (fr != null) {
            final pending = _thinkSplitter.consumePendingTagFragment();
            if (pending.isNotEmpty) {
              if (_thinkSplitter.inTag) {
                if (inText) {
                  inText = false;
                  yield LLMTextEndPart(
                    currentText.toString(),
                    blockId: currentTextBlockId,
                  );
                  currentText.clear();
                  currentTextBlockId = null;
                }
                if (!inThinking) {
                  inThinking = true;
                  currentThinkingBlockId ??= '${blockCounter++}';
                  yield LLMReasoningStartPart(blockId: currentThinkingBlockId);
                  currentThinking.clear();
                }
                fullThinking.write(pending);
                currentThinking.write(pending);
                yield LLMReasoningDeltaPart(
                  pending,
                  blockId: currentThinkingBlockId,
                );
              } else {
                if (inThinking) {
                  inThinking = false;
                  yield LLMReasoningEndPart(
                    currentThinking.toString(),
                    blockId: currentThinkingBlockId,
                  );
                  currentThinking.clear();
                  currentThinkingBlockId = null;
                }
                if (!inText) {
                  inText = true;
                  currentTextBlockId ??= '${blockCounter++}';
                  yield LLMTextStartPart(blockId: currentTextBlockId);
                  currentText.clear();
                }
                fullText.write(pending);
                currentText.write(pending);
                yield LLMTextDeltaPart(pending, blockId: currentTextBlockId);
              }
            }

            finishReason = fr;

            if (!didEmitTerminalParts) {
              didEmitTerminalParts = true;

              if (inText) {
                inText = false;
                yield LLMTextEndPart(
                  currentText.toString(),
                  blockId: currentTextBlockId,
                );
                currentText.clear();
                currentTextBlockId = null;
              }
              if (inThinking) {
                inThinking = false;
                yield LLMReasoningEndPart(
                  currentThinking.toString(),
                  blockId: currentThinkingBlockId,
                );
                currentThinking.clear();
                currentThinkingBlockId = null;
              }
              for (final toolCallId in startedToolCalls) {
                if (endedToolCalls.contains(toolCallId)) continue;
                final fullArgs =
                    toolAccums[toolCallId]?.arguments.toString() ?? '';
                if (fullArgs.isNotEmpty && isParsableJson(fullArgs)) {
                  if (endedToolCalls.add(toolCallId)) {
                    yield LLMToolCallEndPart(toolCallId);
                  }
                }
              }
            }
          }
        }
      }

      final pending = _thinkSplitter.consumePendingTagFragment();
      if (pending.isNotEmpty) {
        if (_thinkSplitter.inTag) {
          if (inText) {
            inText = false;
            yield LLMTextEndPart(
              currentText.toString(),
              blockId: currentTextBlockId,
            );
            currentText.clear();
            currentTextBlockId = null;
          }
          if (!inThinking) {
            inThinking = true;
            currentThinkingBlockId ??= '${blockCounter++}';
            yield LLMReasoningStartPart(blockId: currentThinkingBlockId);
            currentThinking.clear();
          }
          fullThinking.write(pending);
          currentThinking.write(pending);
          yield LLMReasoningDeltaPart(pending, blockId: currentThinkingBlockId);
        } else {
          if (inThinking) {
            inThinking = false;
            yield LLMReasoningEndPart(
              currentThinking.toString(),
              blockId: currentThinkingBlockId,
            );
            currentThinking.clear();
            currentThinkingBlockId = null;
          }
          if (!inText) {
            inText = true;
            currentTextBlockId ??= '${blockCounter++}';
            yield LLMTextStartPart(blockId: currentTextBlockId);
            currentText.clear();
          }
          fullText.write(pending);
          currentText.write(pending);
          yield LLMTextDeltaPart(pending, blockId: currentTextBlockId);
        }
      }

      final completedToolCalls = toolAccums.entries
          .where((e) {
            final name = e.value.name?.trim() ?? '';
            if (name.isEmpty) return false;
            final args = e.value.arguments.toString();
            return args.isNotEmpty && isParsableJson(args);
          })
          .map((e) => e.value.toToolCall(e.key, providerId: config.providerId))
          .toList(growable: false);

      if (finishReason != null) {
        final response = OpenAIChatResponse(
          {
            if (id != null) 'id': id,
            if (model != null) 'model': model,
            if (systemFingerprint != null)
              'system_fingerprint': systemFingerprint,
            'choices': [
              {
                'finish_reason': finishReason,
                'message': {
                  'role': 'assistant',
                  'content': fullText.toString(),
                  if (completedToolCalls.isNotEmpty)
                    'tool_calls':
                        completedToolCalls.map((c) => c.toJson()).toList(),
                },
              },
            ],
            if (citations.isNotEmpty) 'citations': citations,
            if (usage != null) 'usage': usage,
          },
          thinkingContent:
              fullThinking.isNotEmpty ? fullThinking.toString() : null,
          providerId: config.providerId,
          parseToolCallsFromText: _parseToolCallsFromTextEnabled(),
          didRequestTools: effectiveTools != null && effectiveTools.isNotEmpty,
        );

        final metadata = response.providerMetadata;
        if (metadata != null && metadata.isNotEmpty) {
          yield LLMProviderMetadataPart(metadata);
        }

        yield LLMFinishPart(
          response,
          usage: response.usage,
          finishReason: response.finishReason,
        );
        return;
      }

      // Best-effort finish if stream ends without a finish_reason chunk.
      if (finishReason == null) {
        if (inText) {
          inText = false;
          yield LLMTextEndPart(
            currentText.toString(),
            blockId: currentTextBlockId,
          );
          currentText.clear();
          currentTextBlockId = null;
        }
        if (inThinking) {
          inThinking = false;
          yield LLMReasoningEndPart(
            currentThinking.toString(),
            blockId: currentThinkingBlockId,
          );
          currentThinking.clear();
          currentThinkingBlockId = null;
        }
        for (final toolCallId in startedToolCalls) {
          if (endedToolCalls.contains(toolCallId)) continue;
          final fullArgs = toolAccums[toolCallId]?.arguments.toString() ?? '';
          if (fullArgs.isNotEmpty && isParsableJson(fullArgs)) {
            if (endedToolCalls.add(toolCallId)) {
              yield LLMToolCallEndPart(toolCallId);
            }
          }
        }

        final response = OpenAIChatResponse(
          {
            if (id != null) 'id': id,
            if (model != null) 'model': model,
            if (systemFingerprint != null)
              'system_fingerprint': systemFingerprint,
            'choices': [
              {
                'message': {
                  'role': 'assistant',
                  'content': fullText.toString(),
                  if (completedToolCalls.isNotEmpty)
                    'tool_calls':
                        completedToolCalls.map((c) => c.toJson()).toList(),
                },
              },
            ],
            if (citations.isNotEmpty) 'citations': citations,
            if (usage != null) 'usage': usage,
          },
          thinkingContent:
              fullThinking.isNotEmpty ? fullThinking.toString() : null,
          providerId: config.providerId,
          parseToolCallsFromText: _parseToolCallsFromTextEnabled(),
          didRequestTools: effectiveTools != null && effectiveTools.isNotEmpty,
        );

        final metadata = response.providerMetadata;
        if (metadata != null && metadata.isNotEmpty) {
          yield LLMProviderMetadataPart(metadata);
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
      yield LLMErrorPart(
        InvalidStreamPartError(
          chunk: lastStreamChunk ?? const <String, dynamic>{},
          message: 'Stream part decode error: $e',
        ),
      );
      return;
    } finally {
      client.resetSSEBuffer();
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

  /// Parse non-streaming response
  ChatResponse _parseResponse(
    Map<String, dynamic> responseData, {
    required bool didRequestTools,
    Map<String, String>? responseHeaders,
    LLMRequestMetadataPart? requestMetadata,
  }) {
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

        // Some OpenRouter responses may include reasoning at the top-level.
        if (thinkingContent == null && config.model.contains('deepseek-r1')) {
          final reasoning = responseData['reasoning'] as String?;
          if (reasoning != null && reasoning.isNotEmpty) {
            thinkingContent = reasoning;
          }
        }
      }
    }

    final created = responseData['created'];
    DateTime? timestamp;
    if (created is int) {
      timestamp =
          DateTime.fromMillisecondsSinceEpoch(created * 1000, isUtc: true);
    }

    final idRaw = responseData['id'];
    final id = idRaw is String ? idRaw : idRaw?.toString();
    final modelRaw = responseData['model'];
    final model = modelRaw is String ? modelRaw : null;
    final systemFingerprint = responseData['system_fingerprint'];
    final headers = (responseHeaders != null && responseHeaders.isNotEmpty)
        ? responseHeaders
        : null;

    final responseMetadata = (id != null ||
            model != null ||
            timestamp != null ||
            systemFingerprint is String ||
            headers != null)
        ? LLMResponseMetadataPart(
            id: id,
            timestamp: timestamp,
            modelId: model,
            headers: headers,
            body: responseData,
            systemFingerprint:
                systemFingerprint is String ? systemFingerprint : null,
          )
        : null;

    return OpenAIChatResponse(
      responseData,
      thinkingContent: thinkingContent,
      providerId: config.providerId,
      parseToolCallsFromText: _parseToolCallsFromTextEnabled(),
      didRequestTools: didRequestTools,
      responseMetadata: responseMetadata,
      requestMetadata: requestMetadata,
    );
  }

  /// Reset stream state (call this when starting a new stream)
  void _resetStreamState() {
    _hasReasoningContent = false;
    _lastChunk = '';
    _thinkSplitter.reset();
    _thinkingBuffer.clear();
    _toolCallIds.clear();
  }
}

class _ToolCallAccum {
  String? name;
  final StringBuffer arguments = StringBuffer();
  String? thoughtSignature;

  ToolCall toToolCall(
    String id, {
    required String providerId,
  }) {
    final signature = thoughtSignature;
    return ToolCall(
      id: id,
      callType: 'function',
      function: FunctionCall(
        name: name ?? '',
        arguments: arguments.toString(),
      ),
      providerOptions: signature == null || signature.isEmpty
          ? const {}
          : {
              providerId: {
                'thoughtSignature': signature,
              },
            },
    );
  }
}

String? _extractThoughtSignatureFromExtraContent(Map<String, dynamic> rawCall) {
  final extra = rawCall['extra_content'];
  if (extra is! Map) return null;
  final google = extra['google'];
  if (google is! Map) return null;
  final ts = google['thought_signature'];
  if (ts is! String) return null;
  final trimmed = ts.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// OpenAI chat response implementation
class OpenAIChatResponse
    implements
        ChatResponseWithFinishReason,
        ChatResponseWithResponseMetadata,
        ChatResponseWithRequestMetadata,
        ChatResponseWithWarnings {
  final Map<String, dynamic> _rawResponse;
  final String? _thinkingContent;
  final String? _providerId;
  final bool _parseToolCallsFromText;
  final bool _didRequestTools;
  final LLMResponseMetadataPart? _responseMetadata;
  final LLMRequestMetadataPart? _requestMetadata;

  OpenAIChatResponse(
    this._rawResponse, {
    String? thinkingContent,
    String? providerId,
    bool parseToolCallsFromText = false,
    bool didRequestTools = false,
    LLMResponseMetadataPart? responseMetadata,
    LLMRequestMetadataPart? requestMetadata,
  })  : _thinkingContent = thinkingContent,
        _providerId = providerId,
        _parseToolCallsFromText = parseToolCallsFromText,
        _didRequestTools = didRequestTools,
        _responseMetadata = responseMetadata,
        _requestMetadata = requestMetadata;

  @override
  LLMResponseMetadataPart? get responseMetadata => _responseMetadata;

  @override
  LLMRequestMetadataPart? get requestMetadata => _requestMetadata;

  @override
  List<LLMWarning> get warnings {
    if (!_parseToolCallsFromText || !_didRequestTools) return const [];

    final choices = _rawResponse['choices'] as List?;
    if (choices == null || choices.isEmpty) return const [];

    final message = choices.first['message'] as Map<String, dynamic>?;
    final toolCalls = message?['tool_calls'] as List?;
    if (toolCalls != null && toolCalls.isNotEmpty) return const [];

    final content = message?['content'];
    if (content is! String || content.trim().isEmpty) return const [];

    final fallback = _tryParseToolCallFromText(content);
    if (fallback == null) return const [];

    return const [
      LLMCompatibilityWarning(
        feature: 'tool calls parsed from text',
        details:
            'The provider returned a tool call JSON payload in message content instead of `tool_calls`. '
            'Tool calls were parsed from text for compatibility.',
      ),
    ];
  }

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

    if (toolCalls != null) {
      final providerId = _providerId;
      final calls = toolCalls.whereType<Map>().map((tc) {
        final map = tc.cast<String, dynamic>();
        final parsed = ToolCall.fromJson(map);
        final thoughtSignature = _extractThoughtSignatureFromExtraContent(map);
        if (thoughtSignature == null ||
            thoughtSignature.isEmpty ||
            providerId == null ||
            providerId.isEmpty) {
          return parsed;
        }
        return ToolCall(
          id: parsed.id,
          callType: parsed.callType,
          function: parsed.function,
          providerOptions: {
            ...parsed.providerOptions,
            providerId: {
              ...?parsed.providerOptions[providerId],
              'thoughtSignature': thoughtSignature,
            },
          },
        );
      }).where((c) {
        if (c.callType.trim().toLowerCase() != 'function') return false;
        if (c.function.name.trim().isEmpty) return false;
        final args = c.function.arguments;
        return args.trim().isNotEmpty && isParsableJson(args);
      }).toList(growable: false);

      return calls.isEmpty ? null : calls;
    }

    if (!_parseToolCallsFromText || !_didRequestTools) return null;

    final content = message?['content'];
    if (content is! String || content.trim().isEmpty) return null;

    final fallback = _tryParseToolCallFromText(content);
    if (fallback == null) return null;

    return [fallback];
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

  LLMUnifiedFinishReason _mapOpenAIFinishReason(String? raw) {
    return switch (raw) {
      'stop' => LLMUnifiedFinishReason.stop,
      'length' => LLMUnifiedFinishReason.length,
      'content_filter' => LLMUnifiedFinishReason.contentFilter,
      'function_call' || 'tool_calls' => LLMUnifiedFinishReason.toolCalls,
      _ => LLMUnifiedFinishReason.other,
    };
  }

  @override
  LLMFinishReason? get finishReason {
    final choices = _rawResponse['choices'] as List?;
    if (choices == null || choices.isEmpty) return null;
    final first = choices.first;
    if (first is! Map) return null;
    final raw = first['finish_reason'] as String?;
    if (raw == null || raw.isEmpty) return null;
    return LLMFinishReason(unified: _mapOpenAIFinishReason(raw), raw: raw);
  }

  @override
  Map<String, dynamic>? get providerMetadata {
    final id = _rawResponse['id'];
    final model = _rawResponse['model'];
    final systemFingerprint = _rawResponse['system_fingerprint'];
    final choices = _rawResponse['choices'] as List?;
    final finishReason = (choices != null &&
            choices.isNotEmpty &&
            choices.first is Map &&
            (choices.first as Map).containsKey('finish_reason'))
        ? (choices.first as Map)['finish_reason'] as String?
        : null;

    if (id == null &&
        model == null &&
        systemFingerprint == null &&
        finishReason == null) {
      return null;
    }

    final rawProviderId = _providerId?.trim();
    final providerId = rawProviderId != null && rawProviderId.isNotEmpty
        ? rawProviderId
        : 'openai';

    final rawCitations = _rawResponse['citations'];
    final List<String>? citations;
    if (rawCitations is List) {
      citations = rawCitations.whereType<String>().toList(growable: false);
    } else {
      citations = null;
    }
    final isXai = providerId == 'xai' || providerId == 'xai-openai';
    final payload = <String, dynamic>{
      if (id != null) 'id': id,
      if (model != null) 'model': model,
      if (systemFingerprint != null) 'systemFingerprint': systemFingerprint,
      if (finishReason != null) 'finishReason': finishReason,
      if (isXai && citations != null) 'citations': citations,
    };

    final baseKey = providerId.split('.').first;
    return {
      baseKey: payload,
    };
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

ToolCall? _tryParseToolCallFromText(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;

  Map<String, dynamic>? json;

  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is Map) {
      json = Map<String, dynamic>.from(decoded);
    }
  } catch (_) {
    // ignore, fallback to extracting the first JSON object from text.
  }

  json ??= _extractFirstJsonObject(trimmed);
  if (json == null) return null;

  // Some providers might nest the tool call list.
  final toolCalls = json['tool_calls'];
  if (toolCalls is List && toolCalls.isNotEmpty && toolCalls.first is Map) {
    json = Map<String, dynamic>.from(toolCalls.first as Map);
  }

  final id = (json['id'] as String?)?.trim();

  String? name;
  dynamic arguments;

  final function = json['function'];
  if (function is Map) {
    final fn = Map<String, dynamic>.from(function);
    name = fn['name']?.toString();
    arguments = fn['arguments'];
  } else {
    name = json['name']?.toString();
    arguments = json['arguments'];
  }

  if (name == null || name.trim().isEmpty) return null;

  final String argumentsJson;
  if (arguments == null) {
    argumentsJson = '{}';
  } else if (arguments is String) {
    argumentsJson = arguments;
  } else {
    argumentsJson = jsonEncode(arguments);
  }

  return ToolCall(
    id: id != null && id.isNotEmpty ? id : 'toolcall_0',
    callType: 'function',
    function: FunctionCall(
      name: name.trim(),
      arguments: argumentsJson,
    ),
  );
}

Map<String, dynamic>? _extractFirstJsonObject(String text) {
  final start = text.indexOf('{');
  if (start == -1) return null;

  var depth = 0;
  for (var i = start; i < text.length; i++) {
    final ch = text.codeUnitAt(i);
    if (ch == 0x7B) depth++; // {
    if (ch == 0x7D) depth--; // }
    if (depth == 0) {
      final candidate = text.substring(start, i + 1);
      try {
        final decoded = jsonDecode(candidate);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
        return null;
      } catch (_) {
        return null;
      }
    }
  }
  return null;
}
