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
  CancelToken? cancelToken,
}) async* {
  final requestBody = built.body;
  final toolNameMapping = built.toolNameMapping;

  final sseParser = SseChunkParser();
  final activeToolCalls = <int, _ToolCallState>{};
  final blockTypes = <int, String>{};
  final redactedThinkingBlocks = <int, Map<String, dynamic>>{};
  final pendingBlocks = <int, Map<String, dynamic>>{};
  final textBlockCitations = <int, List<Map<String, dynamic>>>{};

  final contentBlocks = <Map<String, dynamic>>[];

  String? messageId;
  String? model;
  String? stopReason;
  Map<String, dynamic>? usage;
  dynamic container;

  String? lastProviderMetadataJson;

  var inText = false;
  var inThinking = false;
  final textBuffer = StringBuffer();
  final thinkingBuffer = StringBuffer();

  int? currentTextIndex;
  int? currentThinkingIndex;

  final startedToolCalls = <String>{};
  final endedToolCalls = <String>{};

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
    final encoded = jsonEncode(metadata);
    if (encoded == lastProviderMetadataJson) return null;
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
      contentBlocks.add({'type': 'thinking', 'thinking': thinking});
    }
    thinkingBuffer.clear();
    currentThinkingIndex = null;
  }

  try {
    final stream = client.postStreamRaw(
      chatEndpoint,
      requestBody,
      cancelToken: cancelToken,
    );

    await for (final chunk in stream) {
      final dataLines = sseParser.parse(chunk);
      if (dataLines.isEmpty) {
        continue;
      }

      for (final line in dataLines) {
        final data = line.data;

        if (data.isEmpty) continue;
        if (data == '[DONE]') {
          // Best-effort finish if the stream ends without message_stop.
          if (inText) {
            yield LLMTextEndPart(textBuffer.toString());
            closeOpenTextBlock();
          }
          if (inThinking) {
            yield LLMReasoningEndPart(thinkingBuffer.toString());
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

          yield LLMFinishPart(response);
          return;
        }

        Map<String, dynamic> json;
        try {
          json = jsonDecode(data) as Map<String, dynamic>;
        } catch (_) {
          continue;
        }

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
                yield LLMTextEndPart(textBuffer.toString());
                closeOpenTextBlock();
              }
              inText = true;
              currentTextIndex = index;
              final citationsRaw = contentBlock['citations'];
              if (citationsRaw is List) {
                textBlockCitations[index] = citationsRaw
                    .whereType<Map>()
                    .map((m) => Map<String, dynamic>.from(m))
                    .toList(growable: true);
              }
              yield const LLMTextStartPart();
            } else if (blockType == 'thinking') {
              if (inThinking) {
                yield LLMReasoningEndPart(thinkingBuffer.toString());
                closeOpenThinkingBlock();
              }
              inThinking = true;
              currentThinkingIndex = index;
              yield const LLMReasoningStartPart();
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

              final isProviderNativeTool = toolName != null &&
                  (toolNameMapping.providerToolIdForRequestName(toolName) !=
                          null ||
                      toolName == 'web_search' ||
                      toolName == 'web_fetch');

              // Provider-native tools are executed server-side; do not surface
              // them as local tool call stream parts, otherwise local tool
              // loops might try to execute them.
              if (toolId != null &&
                  toolId.isNotEmpty &&
                  !isProviderNativeTool) {
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
                yield const LLMTextStartPart();
              }
              textBuffer.write(text);
              yield LLMTextDeltaPart(text);
              break;
            }

            final deltaType = delta['type'] as String?;
            if (deltaType == 'thinking_delta') {
              final thinkingText = delta['thinking'] as String?;
              if (thinkingText != null) {
                if (!inThinking) {
                  inThinking = true;
                  currentThinkingIndex = index;
                  yield const LLMReasoningStartPart();
                }
                thinkingBuffer.write(thinkingText);
                yield LLMReasoningDeltaPart(thinkingText);
              }
              break;
            }

            if (deltaType == 'citations_delta') {
              final citation = delta['citation'];
              if (citation is Map && index == currentTextIndex) {
                final list = textBlockCitations.putIfAbsent(
                    index, () => <Map<String, dynamic>>[]);
                list.add(Map<String, dynamic>.from(citation));
              }
              break;
            }

            final partialJson = delta['partial_json'] as String?;
            if (partialJson != null) {
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
              yield LLMTextEndPart(textBuffer.toString());
              closeOpenTextBlock();
              break;
            }
            if (blockType == 'thinking' && index == currentThinkingIndex) {
              yield LLMReasoningEndPart(thinkingBuffer.toString());
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
              final isProviderNativeTool = requestName != null &&
                  (toolNameMapping.providerToolIdForRequestName(requestName) !=
                          null ||
                      requestName == 'web_search' ||
                      requestName == 'web_fetch');

              if (state.id != null &&
                  state.id!.isNotEmpty &&
                  !isProviderNativeTool) {
                endedToolCalls.add(state.id!);
                yield LLMToolCallEndPart(state.id!);
              }
              break;
            }
            if (blockType == 'server_tool_use' ||
                blockType == 'mcp_tool_use' ||
                blockType == 'mcp_tool_result' ||
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
              yield LLMTextEndPart(textBuffer.toString());
              closeOpenTextBlock();
            }
            if (inThinking) {
              yield LLMReasoningEndPart(thinkingBuffer.toString());
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

            yield LLMFinishPart(response);
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
      yield LLMTextEndPart(textBuffer.toString());
      closeOpenTextBlock();
    }
    if (inThinking) {
      yield LLMReasoningEndPart(thinkingBuffer.toString());
      closeOpenThinkingBlock();
    }
    for (final id in startedToolCalls.difference(endedToolCalls)) {
      yield LLMToolCallEndPart(id);
    }

    final metadataPart = computeProviderMetadataPart();
    if (metadataPart != null) {
      yield metadataPart;
    }
    yield LLMFinishPart(response);
  } catch (e) {
    if (e is LLMError) {
      yield LLMErrorPart(e);
      return;
    }
    yield LLMErrorPart(GenericError('Stream error: $e'));
    return;
  }
}
