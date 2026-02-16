part of 'package:llm_dart_anthropic_compatible/chat.dart';

Stream<LLMStreamPart> _anthropicChatStreamParts(
  AnthropicClient client,
  AnthropicConfig config,
  AnthropicRequestBuilder requestBuilder,
  String chatEndpoint,
  List<ChatMessage> messages, {
  List<Tool>? tools,
  CancelToken? cancelToken,
}) async* {
  final effectiveTools = tools ?? config.tools;
  final built = requestBuilder.buildRequest(messages, effectiveTools, true);
  yield* _anthropicChatStreamPartsFromBuiltRequest(
    client,
    config,
    chatEndpoint,
    built,
    cancelToken: cancelToken,
  );
}

Stream<LLMStreamPart> _anthropicChatStreamPartsFromBuiltRequest(
  AnthropicClient client,
  AnthropicConfig config,
  String chatEndpoint,
  AnthropicBuiltRequest built, {
  Map<String, String>? requestHeaders,
  CancelToken? cancelToken,
}) async* {
  final requestBody = built.body;
  final toolNameMapping = built.toolNameMapping;
  final requestProviderTools = built.providerTools;

  final originalConfig = config.originalConfig;
  if (originalConfig != null) {
    final fallbackProviderId =
        config.providerId == 'anthropic' ? null : 'anthropic';

    final emitRequestMetadata = emitRequestMetadataEnabled(
      originalConfig.providerOptions,
      config.providerId,
      fallbackProviderId: fallbackProviderId,
    );

    if (emitRequestMetadata) {
      yield LLMRequestMetadataPart(
        body: sanitizeRequestBodyForMetadata(requestBody),
      );
    }
  }

  final sseParser = SseChunkParser();
  final activeToolCalls = <int, _ToolCallState>{};
  final activeProviderToolCalls = <int, _ProviderToolCallState>{};
  final blockTypes = <int, String>{};
  final redactedThinkingBlocks = <int, Map<String, dynamic>>{};
  final pendingBlocks = <int, Map<String, dynamic>>{};
  final textBlockCitations = <int, List<Map<String, dynamic>>>{};
  final thinkingSignatures = <int, StringBuffer>{};

  final contentBlocks = <Map<String, dynamic>>[];

  final sources = SourcePartEmitter(
    providerMetadataNamespace: config.providerId,
  );

  final providerToolNameById = <String, String>{};
  final providerToolParts = ProviderToolPartEmitter(
    providerMetadataNamespace: config.providerId,
  );

  String? messageId;
  String? model;
  String? stopReason;
  Map<String, dynamic>? usage;
  dynamic container;

  String? lastProviderMetadataJson;
  var didEmitResponseMetadata = false;

  var inText = false;
  var inThinking = false;
  final textBuffer = StringBuffer();
  final thinkingBuffer = StringBuffer();

  int? currentTextIndex;
  int? currentThinkingIndex;

  final startedToolCalls = <String>{};
  final endedToolCalls = <String>{};

  LLMSourceUrlPart? newSourceUrlPartFromCitation(Map citation) {
    final url = citation['url'];
    if (url is! String || url.isEmpty) return null;

    final title = citation['title'];
    final citationType = citation['type'];
    final encryptedIndex = citation['encrypted_index'];

    return sources.url(
      url,
      title: title is String ? title : null,
      providerMetadataPayload: {
        'type': 'citation',
        if (citationType is String) 'citationType': citationType,
        if (encryptedIndex is String) 'encryptedIndex': encryptedIndex,
      },
    );
  }

  LLMSourceUrlPart? newSourceUrlPartFromWebSearchResult(Map result) {
    final url = result['url'];
    if (url is! String || url.isEmpty) return null;

    final title = result['title'];
    final pageAge = result['page_age'];

    return sources.url(
      url,
      title: title is String ? title : null,
      providerMetadataPayload: {
        'type': 'web_search_result',
        if (pageAge is String) 'pageAge': pageAge,
      },
    );
  }

  String? inferProviderToolNameFromResultBlockType(String blockType) {
    if (!blockType.endsWith('_tool_result')) return null;
    return blockType.substring(0, blockType.length - '_tool_result'.length);
  }

  bool isLikelyToolResultError(Object? content) {
    if (content is! Map) return false;
    final t = content['type'];
    return t is String && t.contains('_error');
  }

  String normalizeServerToolName(String raw) {
    return switch (raw) {
      'text_editor_code_execution' => 'code_execution',
      'bash_code_execution' => 'code_execution',
      _ => raw,
    };
  }

  ProviderTool? findProviderToolForRequestName(String requestName) {
    final id = toolNameMapping.providerToolIdForRequestName(requestName);
    final tools = requestProviderTools;
    if (id != null && tools != null && tools.isNotEmpty) {
      for (final t in tools) {
        if (t.id == id) return t;
      }
    }

    return findProviderToolByRawName(
      providerId: config.providerId,
      rawToolName: requestName,
      providerTools: requestProviderTools,
    );
  }

  String resolveStableProviderToolName(String requestName) {
    final tool = findProviderToolForRequestName(requestName);
    final name = tool?.name;
    if (name != null && name.trim().isNotEmpty) return name.trim();
    return requestName;
  }

  String? inferToolSearchRequestNameForDeferredResult() {
    final tools = requestProviderTools;
    if (tools == null || tools.isEmpty) return null;

    bool isToolSearch(ProviderTool t) {
      final suffix = t.id.split('.').last.trim();
      return suffix == 'tool_search_regex_20251119' ||
          suffix == 'tool_search_bm25_20251119' ||
          suffix == 'tool_search_tool_regex_20251119' ||
          suffix == 'tool_search_tool_bm25_20251119';
    }

    final candidates = tools.where(isToolSearch).toList(growable: false);
    if (candidates.isEmpty) return null;

    final picked = candidates.first;
    final requestName = toolNameMapping.requestNameForProviderToolId(picked.id);
    if (requestName != null && requestName.trim().isNotEmpty) {
      return requestName.trim();
    }

    final explicit = picked.name;
    if (explicit != null && explicit.trim().isNotEmpty) return explicit.trim();

    final suffix = picked.id.split('.').last.trim();
    if (suffix.contains('bm25')) return 'tool_search_tool_bm25';
    if (suffix.contains('regex')) return 'tool_search_tool_regex';

    return null;
  }

  Object? normalizeToolSearchToolResultContent(Object? content) {
    if (content is! Map) return content;
    final map = Map<String, dynamic>.from(content);

    final type = map['type'];
    if (type == 'tool_search_tool_search_result') {
      final refs = map['tool_references'];
      if (refs is! List) return const <Map<String, dynamic>>[];

      final out = <Map<String, dynamic>>[];
      for (final item in refs) {
        if (item is! Map) continue;
        final m = Map<String, dynamic>.from(item);
        final toolName = m['tool_name'];
        final t = m['type'];
        if (toolName is! String || toolName.trim().isEmpty) continue;
        out.add({
          'type':
              t is String && t.trim().isNotEmpty ? t.trim() : 'tool_reference',
          'toolName': toolName,
        });
      }
      return out;
    }

    if (type == 'tool_search_tool_result_error') {
      final errorCode = map['error_code'];
      return {
        'type': 'tool_search_tool_result_error',
        if (errorCode is String && errorCode.trim().isNotEmpty)
          'errorCode': errorCode.trim(),
      };
    }

    return content;
  }

  LLMProviderMetadataPart? computeProviderMetadataPart() {
    final raw = <String, dynamic>{
      'content': contentBlocks,
      if (messageId != null) 'id': messageId,
      if (model != null) 'model': model,
      if (stopReason != null) 'stop_reason': stopReason,
      if (usage != null) 'usage': usage,
      if (container != null) 'container': container,
    };
    final response =
        AnthropicChatResponse(raw, config.providerId, toolNameMapping);
    final metadata = response.providerMetadata;
    if (metadata == null || metadata.isEmpty) return null;
    final encoded = tryStableJsonEncode(metadata);
    if (encoded != null && encoded == lastProviderMetadataJson) return null;
    lastProviderMetadataJson = encoded;
    return LLMProviderMetadataPart(metadata);
  }

  void closeOpenTextBlock() {
    if (!inText) return;
    inText = false;
    final text = textBuffer.toString();
    if (text.isNotEmpty) {
      final citations = currentTextIndex == null
          ? null
          : textBlockCitations[currentTextIndex];
      contentBlocks.add({
        'type': 'text',
        'text': text,
        if (citations != null && citations.isNotEmpty) 'citations': citations,
      });
    }
    textBuffer.clear();
    if (currentTextIndex != null) {
      textBlockCitations.remove(currentTextIndex);
    }
    currentTextIndex = null;
  }

  void closeOpenThinkingBlock() {
    if (!inThinking) return;
    inThinking = false;
    final thinking = thinkingBuffer.toString();
    if (thinking.isNotEmpty) {
      final signature = currentThinkingIndex == null
          ? null
          : thinkingSignatures[currentThinkingIndex!]?.toString();
      contentBlocks.add({
        'type': 'thinking',
        'thinking': thinking,
        if (signature != null && signature.isNotEmpty) 'signature': signature,
      });
    }
    thinkingBuffer.clear();
    if (currentThinkingIndex != null) {
      thinkingSignatures.remove(currentThinkingIndex);
    }
    currentThinkingIndex = null;
  }

  Object? lastStreamChunk;

  try {
    final streamed = await client.postStreamRawWithHeaders(
      chatEndpoint,
      requestBody,
      headers: requestHeaders,
      cancelToken: cancelToken,
    );
    final responseHeaders = streamed.headers;
    final stream = streamed.stream;
    await for (final chunk in stream) {
      final dataLines = sseParser.parse(chunk);
      if (dataLines.isEmpty) {
        continue;
      }

      for (final line in dataLines) {
        final data = line.data;

        if (data.isEmpty) continue;
        lastStreamChunk = data;
        if (data == '[DONE]') {
          // Best-effort finish if the stream ends without message_stop.
          if (inText) {
            yield LLMTextEndPart(
              textBuffer.toString(),
              blockId: currentTextIndex?.toString(),
            );
            closeOpenTextBlock();
          }
          if (inThinking) {
            yield LLMReasoningEndPart(
              thinkingBuffer.toString(),
              blockId: currentThinkingIndex?.toString(),
            );
            closeOpenThinkingBlock();
          }
          for (final id in startedToolCalls.difference(endedToolCalls)) {
            yield LLMToolCallEndPart(id);
          }

          final response = AnthropicChatResponse(
            {
              'content': contentBlocks,
              if (messageId != null) 'id': messageId,
              if (model != null) 'model': model,
              if (stopReason != null) 'stop_reason': stopReason,
              if (usage != null) 'usage': usage,
              if (container != null) 'container': container,
            },
            config.providerId,
            toolNameMapping,
          );

          final metadataPart = computeProviderMetadataPart();
          if (metadataPart != null) {
            yield metadataPart;
          }

          yield LLMFinishPart(
            response,
            usage: response.usage,
            finishReason: response.finishReason,
          );
          return;
        }

        Map<String, dynamic> json;
        try {
          json = jsonDecode(data) as Map<String, dynamic>;
        } catch (_) {
          continue;
        }
        lastStreamChunk = json;

        final type = json['type'] as String?;

        switch (type) {
          case 'message_start':
            final message = json['message'] as Map<String, dynamic>?;
            if (message != null) {
              messageId = message['id'] as String?;
              model = message['model'] as String?;
              container = message['container'];

              final rawUsage = message['usage'];
              if (rawUsage is Map<String, dynamic>) {
                usage = rawUsage;
              } else if (rawUsage is Map) {
                usage = Map<String, dynamic>.from(rawUsage);
              }

              // Programmatic tool calling: content may be pre-populated.
              final rawContent = message['content'];
              if (rawContent is List) {
                for (final block in rawContent) {
                  if (block is! Map) continue;
                  final blockMap = Map<String, dynamic>.from(block);
                  if (blockMap['type'] != 'tool_use') continue;

                  final toolId = blockMap['id'] as String?;
                  final toolName = blockMap['name'] as String?;
                  final input = blockMap['input'];

                  contentBlocks.add(blockMap);

                  final isProviderNativeTool = toolName != null &&
                      (toolNameMapping.providerToolIdForRequestName(toolName) !=
                              null ||
                          toolName == 'web_search' ||
                          toolName == 'web_fetch');

                  if (toolId != null &&
                      toolId.isNotEmpty &&
                      !isProviderNativeTool) {
                    final originalToolName =
                        toolNameMapping.originalFunctionNameForRequestName(
                                toolName ?? '') ??
                            (toolName ?? '');
                    final args = input == null ? '' : jsonEncode(input);
                    final toolCall = ToolCall(
                      id: toolId,
                      callType: 'function',
                      function: FunctionCall(
                        name: originalToolName,
                        arguments: args,
                      ),
                    );
                    startedToolCalls.add(toolCall.id);
                    endedToolCalls.add(toolCall.id);
                    yield LLMToolCallStartPart(toolCall);
                    yield LLMToolCallEndPart(toolCall.id);
                  }
                }
              }
            }

            if (!didEmitResponseMetadata &&
                (messageId != null || model != null)) {
              didEmitResponseMetadata = true;
              final raw = <String, dynamic>{
                if (messageId != null) 'id': messageId,
                if (model != null) 'model': model,
              };
              yield LLMResponseMetadataPart(
                id: messageId,
                model: model,
                headers: responseHeaders.isEmpty ? null : responseHeaders,
                raw: raw.isEmpty ? null : raw,
              );
            }

            final metadataPart = computeProviderMetadataPart();
            if (metadataPart != null) {
              yield metadataPart;
            }
            break;

          case 'content_block_start':
            final index = json['index'] as int?;
            final contentBlock = json['content_block'] as Map<String, dynamic>?;
            if (index == null || contentBlock == null) {
              break;
            }

            final blockType = contentBlock['type'] as String?;
            if (blockType == null) break;
            blockTypes[index] = blockType;

            if (blockType == 'text') {
              if (inText) {
                yield LLMTextEndPart(
                  textBuffer.toString(),
                  blockId: currentTextIndex?.toString(),
                );
                closeOpenTextBlock();
              }
              inText = true;
              currentTextIndex = index;
              final citationsRaw = contentBlock['citations'];
              if (citationsRaw is List) {
                final citations = citationsRaw
                    .whereType<Map>()
                    .map((m) => Map<String, dynamic>.from(m))
                    .toList(growable: true);
                textBlockCitations[index] = citations;

                for (final c in citations) {
                  final part = newSourceUrlPartFromCitation(c);
                  if (part != null) yield part;
                }
              }
              yield LLMTextStartPart(blockId: index.toString());
            } else if (blockType == 'thinking') {
              if (inThinking) {
                yield LLMReasoningEndPart(
                  thinkingBuffer.toString(),
                  blockId: currentThinkingIndex?.toString(),
                );
                closeOpenThinkingBlock();
              }
              inThinking = true;
              currentThinkingIndex = index;
              yield LLMReasoningStartPart(blockId: index.toString());
            } else if (blockType == 'redacted_thinking') {
              // Keep for response.thinking getter (redacted placeholder).
              redactedThinkingBlocks[index] = contentBlock;
            } else if (blockType == 'tool_use') {
              final toolName = contentBlock['name'] as String?;
              final toolId = contentBlock['id'] as String?;
              final state = _ToolCallState()
                ..id = toolId
                ..name = toolName;

              final rawInput = contentBlock['input'];
              if (rawInput is Map && rawInput.isNotEmpty) {
                try {
                  state.inputBuffer.write(jsonEncode(rawInput));
                  state.prefilledInput = true;
                } catch (_) {
                  // Ignore invalid inputs; they may still stream via deltas.
                }
              }
              activeToolCalls[index] = state;

              final isProviderTool = toolName != null &&
                  toolNameMapping.providerToolIdForRequestName(toolName) !=
                      null;

              // `web_search` / `web_fetch` are server tools and should appear
              // as `server_tool_use` (provider-executed). If they ever appear
              // as `tool_use`, treat them as provider-executed and avoid local
              // execution.
              final isKnownServerTool =
                  toolName == 'web_search' || toolName == 'web_fetch';

              // Provider-defined tools (e.g. computer use) are represented as
              // provider tools in the SDK surface but are *client-executed*.
              // Surface them via `LLMProviderToolCallPart` (providerExecuted=false).
              if (toolId != null &&
                  toolId.isNotEmpty &&
                  isProviderTool &&
                  !isKnownServerTool) {
                final stableName = resolveStableProviderToolName(toolName!);
                final configured = findProviderToolForRequestName(toolName);

                providerToolNameById[toolId] = stableName;

                final providerState = _ProviderToolCallState()
                  ..id = toolId
                  ..toolName = stableName
                  ..providerToolName = toolName
                  ..providerExecuted = false
                  ..supportsDeferredResults =
                      configured?.supportsDeferredResults == true;

                // Prefill with embedded `input` when present.
                if (state.prefilledInput == true &&
                    state.inputBuffer.isNotEmpty) {
                  providerState.inputBuffer.write(state.inputBuffer.toString());
                  providerState.firstDelta = false;
                }

                activeProviderToolCalls[index] = providerState;

                yield LLMToolInputStartPart(
                  id: toolId,
                  toolName: stableName,
                  providerExecuted: false,
                );
              } else if (toolId != null &&
                  toolId.isNotEmpty &&
                  !isProviderTool &&
                  !isKnownServerTool) {
                final originalToolName = toolNameMapping
                        .originalFunctionNameForRequestName(toolName ?? '') ??
                    (toolName ?? '');
                final toolCall = ToolCall(
                  id: toolId,
                  callType: 'function',
                  function: FunctionCall(
                    name: originalToolName,
                    arguments: state.inputBuffer.isNotEmpty
                        ? state.inputBuffer.toString()
                        : '',
                  ),
                );
                startedToolCalls.add(toolCall.id);
                yield LLMToolCallStartPart(toolCall);
              }
            } else if (blockType == 'server_tool_use' ||
                blockType == 'mcp_tool_use' ||
                blockType == 'mcp_tool_result' ||
                blockType == 'web_fetch_tool_result' ||
                blockType == 'web_search_tool_result' ||
                blockType.endsWith('_tool_result')) {
              pendingBlocks[index] = Map<String, dynamic>.from(contentBlock);

              if (blockType == 'server_tool_use' ||
                  blockType == 'mcp_tool_use') {
                final id = contentBlock['id'];
                final name = contentBlock['name'];
                final input = contentBlock['input'];

                if (id is String &&
                    id.isNotEmpty &&
                    name is String &&
                    name.isNotEmpty) {
                  final rawToolName = blockType == 'server_tool_use'
                      ? normalizeServerToolName(name)
                      : name;

                  final providerTool = findProviderToolForRequestName(
                    rawToolName,
                  );
                  final toolName = resolveStableProviderToolName(rawToolName);

                  providerToolNameById[id] = toolName;

                  final state = _ProviderToolCallState()
                    ..id = id
                    ..toolName = toolName
                    ..providerToolName = name
                    ..providerExecuted = true
                    ..isDynamic = blockType == 'mcp_tool_use'
                    ..supportsDeferredResults =
                        providerTool?.supportsDeferredResults == true;

                  final hasNonEmptyInput = input is Map && input.isNotEmpty;
                  if (hasNonEmptyInput) {
                    final encoded =
                        tryStableJsonEncode(input) ?? jsonEncode(input);
                    state.inputBuffer.write(encoded);
                    state.firstDelta = false;
                  }

                  activeProviderToolCalls[index] = state;

                  yield LLMToolInputStartPart(
                    id: id,
                    toolName: toolName,
                    providerExecuted: true,
                    isDynamic: blockType == 'mcp_tool_use' ? true : null,
                  );
                }
                break;
              }

              final toolUseId = contentBlock['tool_use_id'];
              if (toolUseId is String && toolUseId.isNotEmpty) {
                var toolName = providerToolNameById[toolUseId] ??
                    inferProviderToolNameFromResultBlockType(blockType) ??
                    'tool';

                // Tool search tool results may arrive without a matching
                // `server_tool_use` in the same response (deferred result).
                // In that case, infer the configured request name from the
                // enabled provider tools.
                if (blockType == 'tool_search_tool_result' &&
                    (toolName == 'tool_search_tool' || toolName == 'tool')) {
                  final inferred =
                      inferToolSearchRequestNameForDeferredResult();
                  if (inferred != null && inferred.isNotEmpty) {
                    toolName = inferred;
                  }
                }

                toolName = resolveStableProviderToolName(toolName);

                final content = contentBlock['content'];
                final isError = isLikelyToolResultError(content);
                Object? resultPayload = content;

                if (content is List) {
                  resultPayload = content
                      .whereType<Map>()
                      .map((m) => Map<String, dynamic>.from(m))
                      .toList(growable: false);

                  if (blockType == 'web_search_tool_result') {
                    for (final item in resultPayload as List) {
                      if (item is! Map) continue;
                      if (item['type'] != 'web_search_result') continue;
                      final p = newSourceUrlPartFromWebSearchResult(item);
                      if (p != null) yield p;
                    }
                  }
                } else if (content is Map) {
                  if (blockType == 'tool_search_tool_result') {
                    resultPayload =
                        normalizeToolSearchToolResultContent(content);
                  } else {
                    resultPayload = Map<String, dynamic>.from(content);
                  }
                }

                final part = providerToolParts.result(
                  toolCallId: toolUseId,
                  toolName: toolName,
                  result: resultPayload,
                  isError: isError ? true : null,
                  isDynamic: blockType == 'mcp_tool_result' ? true : null,
                  providerMetadataPayload: {'type': blockType},
                );
                if (part != null) yield part;
              }
            }
            break;

          case 'content_block_delta':
            final index = json['index'] as int?;
            final delta = json['delta'] as Map<String, dynamic>?;
            if (index == null || delta == null) break;

            final text = delta['text'] as String?;
            if (text != null) {
              if (!inText) {
                inText = true;
                currentTextIndex = index;
                yield LLMTextStartPart(blockId: index.toString());
              }
              textBuffer.write(text);
              yield LLMTextDeltaPart(text, blockId: index.toString());
              break;
            }

            final deltaType = delta['type'] as String?;
            if (deltaType == 'thinking_delta') {
              final thinkingText = delta['thinking'] as String?;
              if (thinkingText != null) {
                if (!inThinking) {
                  inThinking = true;
                  currentThinkingIndex = index;
                  yield LLMReasoningStartPart(blockId: index.toString());
                }
                thinkingBuffer.write(thinkingText);
                yield LLMReasoningDeltaPart(
                  thinkingText,
                  blockId: index.toString(),
                );
              }
              break;
            }

            if (deltaType == 'citations_delta') {
              final citation = delta['citation'];
              if (citation is Map && index == currentTextIndex) {
                final list = textBlockCitations.putIfAbsent(
                    index, () => <Map<String, dynamic>>[]);
                final mapped = Map<String, dynamic>.from(citation);
                list.add(mapped);

                final part = newSourceUrlPartFromCitation(mapped);
                if (part != null) yield part;
              }
              break;
            }

            if (deltaType == 'signature_delta') {
              final signature = delta['signature'] as String?;
              if (signature != null &&
                  signature.isNotEmpty &&
                  blockTypes[index] == 'thinking') {
                final buf =
                    thinkingSignatures.putIfAbsent(index, StringBuffer.new);
                buf
                  ..clear()
                  ..write(signature);
              }
              break;
            }

            final partialJson = deltaType == 'input_json_delta'
                ? delta['partial_json'] as String?
                : null;
            if (partialJson != null && partialJson.isNotEmpty) {
              final providerState = activeProviderToolCalls[index];
              if (providerState != null && providerState.isComplete) {
                var fragment = partialJson;

                if (providerState.firstDelta == true) {
                  final providerToolName = providerState.providerToolName;
                  if (providerToolName == 'bash_code_execution' ||
                      providerToolName == 'text_editor_code_execution') {
                    if (fragment.startsWith('{')) {
                      fragment =
                          '{"type": "$providerToolName",${fragment.substring(1)}';
                    }
                  }
                }

                providerState.inputBuffer.write(fragment);
                providerState.firstDelta = false;

                final mirroredState = activeToolCalls[index];
                if (mirroredState != null && !mirroredState.prefilledInput) {
                  mirroredState.inputBuffer.write(fragment);
                }

                yield LLMToolInputDeltaPart(
                  id: providerState.id!,
                  delta: fragment,
                );
                break;
              }

              final state = activeToolCalls[index];
              if (state != null) {
                if (!state.prefilledInput) {
                  state.inputBuffer.write(partialJson);
                }

                final requestName = state.name;
                final isProviderNativeTool = requestName != null &&
                    (toolNameMapping
                                .providerToolIdForRequestName(requestName) !=
                            null ||
                        requestName == 'web_search' ||
                        requestName == 'web_fetch');

                if (state.id != null &&
                    state.id!.isNotEmpty &&
                    !isProviderNativeTool) {
                  final originalToolName =
                      toolNameMapping.originalFunctionNameForRequestName(
                            state.name ?? '',
                          ) ??
                          (state.name ?? '');
                  yield LLMToolCallDeltaPart(
                    ToolCall(
                      id: state.id!,
                      callType: 'function',
                      function: FunctionCall(
                        name: originalToolName,
                        arguments: partialJson,
                      ),
                    ),
                  );
                }
              }
            }
            break;

          case 'content_block_stop':
            final index = json['index'] as int?;
            if (index == null) break;

            final blockType = blockTypes[index];
            if (blockType == 'text' && index == currentTextIndex) {
              yield LLMTextEndPart(textBuffer.toString(),
                  blockId: index.toString());
              closeOpenTextBlock();
              break;
            }
            if (blockType == 'thinking' && index == currentThinkingIndex) {
              yield LLMReasoningEndPart(
                thinkingBuffer.toString(),
                blockId: index.toString(),
              );
              closeOpenThinkingBlock();
              break;
            }
            if (blockType == 'redacted_thinking') {
              final block = redactedThinkingBlocks.remove(index);
              if (block != null) {
                contentBlocks.add(block);
              } else {
                contentBlocks.add({'type': 'redacted_thinking'});
              }
              break;
            }
            if (blockType == 'tool_use') {
              final state = activeToolCalls.remove(index);
              if (state == null || !state.isComplete) break;

              final accumulatedInput = state.inputBuffer.toString();
              dynamic input;
              try {
                input = accumulatedInput.isEmpty
                    ? <String, dynamic>{}
                    : jsonDecode(accumulatedInput);
              } catch (_) {
                input = <String, dynamic>{};
              }

              contentBlocks.add({
                'type': 'tool_use',
                'id': state.id,
                'name': state.name,
                'input': input,
              });

              final requestName = state.name;
              final isProviderTool = requestName != null &&
                  toolNameMapping.providerToolIdForRequestName(requestName) !=
                      null;
              final isKnownServerTool =
                  requestName == 'web_search' || requestName == 'web_fetch';

              if (state.id != null &&
                  state.id!.isNotEmpty &&
                  isProviderTool &&
                  !isKnownServerTool) {
                final providerState = activeProviderToolCalls.remove(index);
                yield LLMToolInputEndPart(id: state.id!);

                final stableName = resolveStableProviderToolName(requestName!);
                var inputString = (providerState?.inputBuffer.toString() ??
                        state.inputBuffer.toString())
                    .trim();
                if (inputString.isEmpty) inputString = '{}';

                final part = providerToolParts.call(
                  toolCallId: state.id!,
                  toolName: stableName,
                  input: inputString,
                  providerExecuted: false,
                  supportsDeferredResults:
                      (providerState?.supportsDeferredResults == true)
                          ? true
                          : null,
                  providerMetadataPayload: const {'type': 'tool_use'},
                );
                if (part != null) yield part;
              } else if (state.id != null &&
                  state.id!.isNotEmpty &&
                  !isProviderTool &&
                  !isKnownServerTool) {
                endedToolCalls.add(state.id!);
                yield LLMToolCallEndPart(state.id!);
              }
              break;
            }
            if (blockType == 'server_tool_use' || blockType == 'mcp_tool_use') {
              final state = activeProviderToolCalls.remove(index);
              if (state != null && state.isComplete) {
                yield LLMToolInputEndPart(id: state.id!);

                var inputString = state.inputBuffer.toString();
                if (inputString.isEmpty) inputString = '{}';

                if (state.providerToolName == 'code_execution') {
                  try {
                    final parsed = jsonDecode(inputString);
                    if (parsed is Map &&
                        parsed.containsKey('code') &&
                        !parsed.containsKey('type')) {
                      inputString = jsonEncode({
                        'type': 'programmatic-tool-call',
                        ...Map<String, dynamic>.from(parsed),
                      });
                    }
                  } catch (_) {
                    // Keep original inputString on parse errors.
                  }
                }

                final part = providerToolParts.call(
                  toolCallId: state.id!,
                  toolName: state.toolName!,
                  input: inputString,
                  providerExecuted: state.providerExecuted ? true : null,
                  supportsDeferredResults:
                      state.supportsDeferredResults ? true : null,
                  isDynamic: state.isDynamic ? true : null,
                  providerMetadataPayload: {'type': blockType},
                );
                if (part != null) yield part;
              }

              final block = pendingBlocks.remove(index);
              if (block != null) {
                contentBlocks.add(block);
              }
              break;
            }

            if (blockType == 'mcp_tool_result' ||
                blockType == 'web_fetch_tool_result' ||
                blockType == 'web_search_tool_result' ||
                (blockType != null && blockType.endsWith('_tool_result'))) {
              final block = pendingBlocks.remove(index);
              if (block != null) {
                contentBlocks.add(block);
              }
              break;
            }
            break;

          case 'message_delta':
            final delta = json['delta'] as Map<String, dynamic>?;
            final updatedStopReason = delta?['stop_reason'] as String?;
            if (updatedStopReason != null) {
              stopReason = updatedStopReason;
            }

            final rawUsage = json['usage'];
            if (rawUsage is Map<String, dynamic>) {
              usage = {...?usage, ...rawUsage};
            } else if (rawUsage is Map) {
              usage = {...?usage, ...Map<String, dynamic>.from(rawUsage)};
            }

            final metadataPart = computeProviderMetadataPart();
            if (metadataPart != null) {
              yield metadataPart;
            }
            break;

          case 'message_stop':
            if (inText) {
              yield LLMTextEndPart(
                textBuffer.toString(),
                blockId: currentTextIndex?.toString(),
              );
              closeOpenTextBlock();
            }
            if (inThinking) {
              yield LLMReasoningEndPart(
                thinkingBuffer.toString(),
                blockId: currentThinkingIndex?.toString(),
              );
              closeOpenThinkingBlock();
            }
            for (final id in startedToolCalls.difference(endedToolCalls)) {
              yield LLMToolCallEndPart(id);
            }

            final response = AnthropicChatResponse(
              {
                'content': contentBlocks,
                if (messageId != null) 'id': messageId,
                if (model != null) 'model': model,
                if (stopReason != null) 'stop_reason': stopReason,
                if (usage != null) 'usage': usage,
                if (container != null) 'container': container,
              },
              config.providerId,
              toolNameMapping,
            );

            final metadataPart = computeProviderMetadataPart();
            if (metadataPart != null) {
              yield metadataPart;
            }

            yield LLMFinishPart(
              response,
              usage: response.usage,
              finishReason: response.finishReason,
            );
            return;

          case 'error':
            final error = json['error'] as Map<String, dynamic>?;
            if (error != null) {
              yield LLMErrorPart(AnthropicChat._mapAnthropicError(error));
              return;
            }
            break;

          default:
            break;
        }
      }
    }

    // If we exit the stream without [DONE] or message_stop, emit a best-effort finish.
    final response = AnthropicChatResponse(
      {
        'content': contentBlocks,
        if (messageId != null) 'id': messageId,
        if (model != null) 'model': model,
        if (stopReason != null) 'stop_reason': stopReason,
        if (usage != null) 'usage': usage,
        if (container != null) 'container': container,
      },
      config.providerId,
      toolNameMapping,
    );

    if (inText) {
      yield LLMTextEndPart(
        textBuffer.toString(),
        blockId: currentTextIndex?.toString(),
      );
      closeOpenTextBlock();
    }
    if (inThinking) {
      yield LLMReasoningEndPart(
        thinkingBuffer.toString(),
        blockId: currentThinkingIndex?.toString(),
      );
      closeOpenThinkingBlock();
    }
    for (final id in startedToolCalls.difference(endedToolCalls)) {
      yield LLMToolCallEndPart(id);
    }

    final metadataPart = computeProviderMetadataPart();
    if (metadataPart != null) {
      yield metadataPart;
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
  }
}
