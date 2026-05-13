import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

final class AnthropicMessagesStreamState {
  final Map<int, _AnthropicContentBlockState> _contentBlocksByIndex = {};
  final Map<String, _AnthropicToolDescriptor> _toolDescriptorsById = {};

  String? responseId;
  String? responseModelId;
  String? rawFinishReason;
  String? stopSequence;
  Map<String, Object?>? rawUsage;
  Map<String, Object?>? container;
  Map<String, Object?>? contextManagement;
  bool emittedResponseMetadata = false;
}

final class AnthropicStreamCodec {
  const AnthropicStreamCodec();

  Iterable<LanguageModelStreamEvent> decodeChunk(
    Map<String, Object?> chunk,
    AnthropicMessagesStreamState state,
  ) sync* {
    final chunkType = _asString(chunk['type']);
    if (chunkType == null || chunkType == 'ping') {
      return;
    }

    if (chunkType == 'message_start') {
      final message = _asMap(chunk['message']);
      if (message == null) {
        return;
      }

      state.responseId = _asString(message['id']);
      state.responseModelId = _asString(message['model']);
      state.rawFinishReason = _asString(message['stop_reason']);
      state.rawUsage = _asMap(message['usage']);
      state.container = _decodeContainer(_asMap(message['container']));

      if (!state.emittedResponseMetadata) {
        state.emittedResponseMetadata = true;
        yield ResponseMetadataEvent(
          responseId: state.responseId,
          modelId: state.responseModelId,
        );
      }

      for (final rawPart in _asList(message['content'])) {
        final part = _asMap(rawPart);
        if (part != null && _asString(part['type']) == 'tool_use') {
          yield* _emitPrepopulatedToolCall(part, state);
        }
      }
      return;
    }

    if (chunkType == 'content_block_start') {
      final index = _asInt(chunk['index']);
      final contentBlock = _asMap(chunk['content_block']);
      if (index == null || contentBlock == null) {
        return;
      }

      final blockType = _asString(contentBlock['type']);
      final blockMetadata = _providerMetadata({
        'blockIndex': index,
        'blockType': blockType,
      });

      if (blockType == 'text' || blockType == 'compaction') {
        final metadata = blockType == 'compaction'
            ? _providerMetadata({
                'blockIndex': index,
                'blockType': blockType,
                'type': 'compaction',
              })
            : blockMetadata;
        state._contentBlocksByIndex[index] = _AnthropicTextBlockState(
          id: '$index',
          providerMetadata: metadata,
        );
        yield TextStartEvent(id: '$index', providerMetadata: metadata);
        return;
      }

      if (blockType == 'thinking' || blockType == 'redacted_thinking') {
        final metadata = blockType == 'redacted_thinking'
            ? _providerMetadata({
                'blockIndex': index,
                'blockType': blockType,
                'redactedData': contentBlock['data'],
              })
            : blockMetadata;
        state._contentBlocksByIndex[index] = _AnthropicReasoningBlockState(
          id: '$index',
          providerMetadata: metadata,
        );
        yield ReasoningStartEvent(id: '$index', providerMetadata: metadata);
        return;
      }

      if (blockType == 'tool_use') {
        yield* _startToolBlock(
          index: index,
          toolCallId: _asString(contentBlock['id']) ?? 'tool-$index',
          toolName: _asString(contentBlock['name']) ?? 'tool',
          initialInput: contentBlock['input'],
          providerExecuted: false,
          isDynamic: false,
          title: null,
          metadataValues: {
            'blockIndex': index,
            'blockType': blockType,
            'caller': contentBlock['caller'],
          },
          state: state,
        );
        return;
      }

      if (blockType == 'server_tool_use') {
        final toolName = _asString(contentBlock['name']) ?? 'tool';
        yield* _startToolBlock(
          index: index,
          toolCallId: _asString(contentBlock['id']) ?? 'tool-$index',
          toolName: toolName,
          initialInput: contentBlock['input'],
          providerExecuted: true,
          isDynamic: true,
          title: null,
          metadataValues: {
            'blockIndex': index,
            'blockType': blockType,
            'providerToolName': toolName,
            'caller': contentBlock['caller'],
          },
          state: state,
        );
        return;
      }

      if (blockType == 'mcp_tool_use') {
        final rawToolName = _asString(contentBlock['name']) ?? 'tool';
        yield* _startToolBlock(
          index: index,
          toolCallId: _asString(contentBlock['id']) ?? 'tool-$index',
          toolName: 'mcp.$rawToolName',
          initialInput: contentBlock['input'],
          providerExecuted: true,
          isDynamic: true,
          title: _asString(contentBlock['server_name']),
          metadataValues: {
            'blockIndex': index,
            'blockType': blockType,
            'serverName': _asString(contentBlock['server_name']),
          },
          state: state,
        );
        return;
      }

      if (_isImmediateToolResultBlock(blockType)) {
        yield* _emitImmediateToolResult(
          blockType: blockType!,
          contentBlock: contentBlock,
          state: state,
        );
        return;
      }

      yield CustomEvent(
        kind: 'anthropic.$blockType',
        data: contentBlock,
        providerMetadata: blockMetadata,
      );
      return;
    }

    if (chunkType == 'content_block_delta') {
      yield* _decodeContentBlockDelta(chunk, state);
      return;
    }

    if (chunkType == 'content_block_stop') {
      final index = _asInt(chunk['index']);
      if (index == null) {
        return;
      }

      final contentBlock = state._contentBlocksByIndex.remove(index);
      if (contentBlock is _AnthropicTextBlockState) {
        yield TextEndEvent(
          id: contentBlock.id,
          providerMetadata: contentBlock.providerMetadata,
        );
        return;
      }

      if (contentBlock is _AnthropicReasoningBlockState) {
        yield ReasoningEndEvent(
          id: contentBlock.id,
          providerMetadata: contentBlock.providerMetadata,
        );
        return;
      }

      if (contentBlock is _AnthropicToolBlockState) {
        yield* _finishToolBlock(contentBlock, state);
      }
      return;
    }

    if (chunkType == 'message_delta') {
      final delta = _asMap(chunk['delta']);
      final usage = _asMap(chunk['usage']);
      state.rawFinishReason =
          _asString(delta?['stop_reason']) ?? state.rawFinishReason;
      state.stopSequence =
          _asString(delta?['stop_sequence']) ?? state.stopSequence;
      state.container =
          _decodeContainer(_asMap(delta?['container'])) ?? state.container;
      state.contextManagement =
          _asMap(chunk['context_management']) ?? state.contextManagement;
      state.rawUsage = _mergeObjects(state.rawUsage, usage) ?? state.rawUsage;
      return;
    }

    if (chunkType == 'message_stop') {
      yield FinishEvent(
        finishReason: _mapFinishReason(state.rawFinishReason),
        rawFinishReason: state.rawFinishReason,
        usage: _decodeUsage(state.rawUsage),
        providerMetadata: _providerMetadata({
          'usage': state.rawUsage,
          'stopSequence': state.stopSequence,
          'container': state.container,
          'contextManagement': state.contextManagement,
        }),
      );
      return;
    }

    if (chunkType == 'error') {
      yield ErrorEvent(
        ModelError.fromUnknown(
          chunk['error'] ?? chunk,
          kind: ModelErrorKind.provider,
        ),
      );
    }
  }

  Iterable<LanguageModelStreamEvent> _decodeContentBlockDelta(
    Map<String, Object?> chunk,
    AnthropicMessagesStreamState state,
  ) sync* {
    final index = _asInt(chunk['index']);
    final delta = _asMap(chunk['delta']);
    if (index == null || delta == null) {
      return;
    }

    final deltaType = _asString(delta['type']);
    final contentBlock = state._contentBlocksByIndex[index];
    if (deltaType == 'text_delta' || deltaType == 'compaction_delta') {
      if (contentBlock is! _AnthropicTextBlockState) {
        return;
      }

      final value = deltaType == 'text_delta'
          ? _asString(delta['text'])
          : _asString(delta['content']);
      if (value == null || value.isEmpty) {
        return;
      }

      yield TextDeltaEvent(
        id: contentBlock.id,
        delta: value,
        providerMetadata: contentBlock.providerMetadata,
      );
      return;
    }

    if (deltaType == 'thinking_delta') {
      if (contentBlock is! _AnthropicReasoningBlockState) {
        return;
      }

      final value = _asString(delta['thinking']);
      if (value == null || value.isEmpty) {
        return;
      }

      yield ReasoningDeltaEvent(
        id: contentBlock.id,
        delta: value,
        providerMetadata: contentBlock.providerMetadata,
      );
      return;
    }

    if (deltaType == 'signature_delta') {
      if (contentBlock is! _AnthropicReasoningBlockState) {
        return;
      }

      yield ReasoningDeltaEvent(
        id: contentBlock.id,
        delta: '',
        providerMetadata: _providerMetadata({
          'blockIndex': index,
          'blockType': 'thinking',
          'signature': _asString(delta['signature']),
        }),
      );
      return;
    }

    if (deltaType == 'input_json_delta') {
      if (contentBlock is! _AnthropicToolBlockState) {
        return;
      }

      final partialJson = _asString(delta['partial_json']);
      if (partialJson == null || partialJson.isEmpty) {
        return;
      }

      contentBlock.inputBuffer.write(partialJson);
      yield ToolInputDeltaEvent(
        toolCallId: contentBlock.toolCallId,
        delta: partialJson,
        providerMetadata: contentBlock.providerMetadata,
      );
      return;
    }

    if (deltaType == 'citations_delta') {
      final citation = _asMap(delta['citation']);
      final source = _decodeCitationSource(citation);
      if (source != null) {
        yield SourceEvent(source);
      }
    }
  }

  Iterable<LanguageModelStreamEvent> _emitPrepopulatedToolCall(
    Map<String, Object?> part,
    AnthropicMessagesStreamState state,
  ) sync* {
    final toolCallId = _asString(part['id']);
    final toolName = _asString(part['name']);
    if (toolCallId == null || toolName == null) {
      return;
    }

    final input =
        normalizeJsonValue(part['input']) ?? const <String, Object?>{};
    final encodedInput = jsonEncode(input);
    final providerMetadata = _providerMetadata({
      'caller': part['caller'],
    });

    state._toolDescriptorsById[toolCallId] = _AnthropicToolDescriptor(
      toolName: toolName,
      providerMetadata: providerMetadata,
      providerExecuted: false,
      isDynamic: false,
      title: null,
    );

    yield ToolInputStartEvent(
      toolCallId: toolCallId,
      toolName: toolName,
      providerMetadata: providerMetadata,
    );
    yield ToolInputDeltaEvent(
      toolCallId: toolCallId,
      delta: encodedInput,
      providerMetadata: providerMetadata,
    );
    yield ToolInputEndEvent(
      toolCallId: toolCallId,
      providerMetadata: providerMetadata,
    );
    yield ToolCallEvent(
      toolCall: ToolCallContent(
        toolCallId: toolCallId,
        toolName: toolName,
        input: input,
      ),
      providerMetadata: providerMetadata,
    );
  }

  Iterable<LanguageModelStreamEvent> _startToolBlock({
    required int index,
    required String toolCallId,
    required String toolName,
    required Object? initialInput,
    required bool providerExecuted,
    required bool isDynamic,
    required String? title,
    required Map<String, Object?> metadataValues,
    required AnthropicMessagesStreamState state,
  }) sync* {
    final providerMetadata = _providerMetadata(metadataValues);
    final initialInputValue =
        normalizeJsonValue(initialInput) ?? const <String, Object?>{};
    final encodedInitialInput =
        initialInput == null ? '' : jsonEncode(initialInputValue);

    final toolState = _AnthropicToolBlockState(
      toolCallId: toolCallId,
      toolName: toolName,
      providerExecuted: providerExecuted,
      isDynamic: isDynamic,
      title: title,
      providerMetadata: providerMetadata,
    );

    if (encodedInitialInput.isNotEmpty) {
      toolState.inputBuffer.write(encodedInitialInput);
    }

    state._contentBlocksByIndex[index] = toolState;
    state._toolDescriptorsById[toolCallId] = _AnthropicToolDescriptor(
      toolName: toolName,
      providerMetadata: providerMetadata,
      providerExecuted: providerExecuted,
      isDynamic: isDynamic,
      title: title,
    );

    yield ToolInputStartEvent(
      toolCallId: toolCallId,
      toolName: toolName,
      providerExecuted: providerExecuted,
      isDynamic: isDynamic,
      title: title,
      providerMetadata: providerMetadata,
    );

    if (encodedInitialInput.isNotEmpty) {
      yield ToolInputDeltaEvent(
        toolCallId: toolCallId,
        delta: encodedInitialInput,
        providerMetadata: providerMetadata,
      );
    }
  }

  Iterable<LanguageModelStreamEvent> _finishToolBlock(
    _AnthropicToolBlockState contentBlock,
    AnthropicMessagesStreamState state,
  ) sync* {
    final encodedInput = contentBlock.inputBuffer.isEmpty
        ? '{}'
        : contentBlock.inputBuffer.toString();
    final decodedInput = _tryDecodeJsonValue(encodedInput);

    if (decodedInput.error != null) {
      yield ToolInputErrorEvent(
        toolCallId: contentBlock.toolCallId,
        toolName: contentBlock.toolName,
        input: encodedInput,
        errorText: _formatInvalidToolInputError(
          contentBlock.toolName,
          decodedInput.error!,
        ),
        providerExecuted: contentBlock.providerExecuted,
        isDynamic: contentBlock.isDynamic,
        title: contentBlock.title,
        providerMetadata: contentBlock.providerMetadata,
      );
      return;
    }

    yield ToolInputEndEvent(
      toolCallId: contentBlock.toolCallId,
      providerMetadata: contentBlock.providerMetadata,
    );
    yield ToolCallEvent(
      toolCall: ToolCallContent(
        toolCallId: contentBlock.toolCallId,
        toolName: contentBlock.toolName,
        input: decodedInput.value,
        providerExecuted: contentBlock.providerExecuted,
        isDynamic: contentBlock.isDynamic,
        title: contentBlock.title,
      ),
      providerMetadata: contentBlock.providerMetadata,
    );

    state._toolDescriptorsById[contentBlock.toolCallId] =
        _AnthropicToolDescriptor(
      toolName: contentBlock.toolName,
      providerMetadata: contentBlock.providerMetadata,
      providerExecuted: contentBlock.providerExecuted,
      isDynamic: contentBlock.isDynamic,
      title: contentBlock.title,
    );
  }

  Iterable<LanguageModelStreamEvent> _emitImmediateToolResult({
    required String blockType,
    required Map<String, Object?> contentBlock,
    required AnthropicMessagesStreamState state,
  }) sync* {
    final toolUseId = _asString(contentBlock['tool_use_id']);
    if (toolUseId == null) {
      yield CustomEvent(
        kind: 'anthropic.$blockType',
        data: contentBlock,
      );
      return;
    }

    final descriptor = state._toolDescriptorsById[toolUseId];
    final providerMetadata = _providerMetadata({
      ..._providerMetadataValues(descriptor?.providerMetadata),
      'blockType': blockType,
    });
    final toolName = descriptor?.toolName ?? _fallbackToolName(blockType);

    yield ToolResultEvent(
      toolResult: ToolResultContent(
        toolCallId: toolUseId,
        toolName: toolName,
        toolOutput: _toolResultOutput(blockType, contentBlock),
        isDynamic: descriptor?.isDynamic ?? _isDynamicToolResult(blockType),
      ),
      providerMetadata: providerMetadata,
    );

    final customKind = _toolResultCustomKind(blockType);
    if (customKind != null) {
      yield CustomEvent(
        kind: customKind,
        data: _toolResultReplayPayload(
          blockType: blockType,
          block: contentBlock,
          toolCallId: toolUseId,
          toolName: toolName,
        ),
        providerMetadata: providerMetadata,
      );
    }

    if (blockType == 'web_search_tool_result') {
      final resultList = contentBlock['content'];
      if (resultList is List) {
        for (final item in resultList) {
          final result = _asMap(item);
          final url = _asString(result?['url']);
          if (url == null) {
            continue;
          }

          yield SourceEvent(
            SourceReference(
              kind: SourceReferenceKind.url,
              sourceId: url,
              uri: Uri.tryParse(url),
              title: _asString(result?['title']),
              providerMetadata: _providerMetadata({
                'pageAge': _asString(result?['page_age']),
                'resultType': _asString(result?['type']),
              }),
            ),
          );
        }
      }
    }
  }

  bool _isImmediateToolResultBlock(String? blockType) {
    return blockType == 'web_fetch_tool_result' ||
        blockType == 'web_search_tool_result' ||
        blockType == 'code_execution_tool_result' ||
        blockType == 'bash_code_execution_tool_result' ||
        blockType == 'text_editor_code_execution_tool_result' ||
        blockType == 'tool_search_tool_result' ||
        blockType == 'mcp_tool_result';
  }

  FinishReason _mapFinishReason(String? rawReason) {
    switch (rawReason) {
      case 'pause_turn':
      case 'end_turn':
      case 'stop_sequence':
        return FinishReason.stop;
      case 'tool_use':
        return FinishReason.toolCalls;
      case 'max_tokens':
      case 'model_context_window_exceeded':
        return FinishReason.maxTokens;
      case 'refusal':
        return FinishReason.contentFilter;
      default:
        return FinishReason.other;
    }
  }

  UsageStats? _decodeUsage(Map<String, Object?>? usage) {
    if (usage == null) {
      return null;
    }

    final inputTokens = _asInt(usage['input_tokens']);
    final outputTokens = _asInt(usage['output_tokens']);
    return UsageStats(
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      totalTokens: (inputTokens ?? 0) + (outputTokens ?? 0),
    );
  }

  Map<String, Object?>? _decodeContainer(Map<String, Object?>? container) {
    if (container == null) {
      return null;
    }

    return {
      if (_asString(container['id']) != null) 'id': _asString(container['id']),
      if (_asString(container['expires_at']) != null)
        'expiresAt': _asString(container['expires_at']),
      if (container['skills'] != null)
        'skills': normalizeJsonValue(container['skills']),
    };
  }

  ProviderMetadata? _providerMetadata(Map<String, Object?> values) {
    final anthropicValues = <String, Object?>{};
    for (final entry in values.entries) {
      if (entry.value != null) {
        anthropicValues[entry.key] = entry.value;
      }
    }

    if (anthropicValues.isEmpty) {
      return null;
    }

    return ProviderMetadata({
      'anthropic': anthropicValues,
    });
  }

  SourceReference? _decodeCitationSource(Map<String, Object?>? citation) {
    if (citation == null) {
      return null;
    }

    final type = _asString(citation['type']);
    if (type == 'web_search_result_location') {
      final url = _asString(citation['url']);
      if (url == null) {
        return null;
      }

      return SourceReference(
        kind: SourceReferenceKind.url,
        sourceId: url,
        uri: Uri.tryParse(url),
        title: _asString(citation['title']),
        providerMetadata: _providerMetadata({
          'citationType': type,
          'citedText': _asString(citation['cited_text']),
          'encryptedIndex': _asString(citation['encrypted_index']),
        }),
      );
    }

    if (type == 'page_location' || type == 'char_location') {
      final documentIndex = _asInt(citation['document_index']);
      return SourceReference(
        kind: SourceReferenceKind.document,
        sourceId: 'document-${documentIndex ?? 0}',
        title: _asString(citation['document_title']),
        providerMetadata: _providerMetadata({
          'citationType': type,
          'citedText': _asString(citation['cited_text']),
          'documentIndex': documentIndex,
          'startPageNumber': _asInt(citation['start_page_number']),
          'endPageNumber': _asInt(citation['end_page_number']),
          'startCharIndex': _asInt(citation['start_char_index']),
          'endCharIndex': _asInt(citation['end_char_index']),
        }),
      );
    }

    return null;
  }

  _DecodedJsonValue _tryDecodeJsonValue(String value) {
    try {
      return _DecodedJsonValue(
        value: jsonDecode(value),
      );
    } on FormatException catch (error) {
      return _DecodedJsonValue(
        value: value,
        error: error,
      );
    } catch (error) {
      return _DecodedJsonValue(
        value: value,
        error: FormatException(error.toString()),
      );
    }
  }

  String _formatInvalidToolInputError(
    String toolName,
    FormatException error,
  ) {
    final message = error.message.trim();
    if (message.isEmpty) {
      return 'Invalid JSON tool arguments for "$toolName".';
    }

    return 'Invalid JSON tool arguments for "$toolName": $message';
  }

  Map<String, Object?>? _mergeObjects(
    Map<String, Object?>? left,
    Map<String, Object?>? right,
  ) {
    if (left == null && right == null) {
      return null;
    }

    return {
      ...?left,
      ...?right,
    };
  }

  Map<String, Object?>? _asMap(Object? value) {
    if (value is Map<String, Object?>) {
      return value;
    }

    if (value is Map) {
      return Map<String, Object?>.from(value);
    }

    return null;
  }

  List<Object?> _asList(Object? value) {
    if (value is List<Object?>) {
      return value;
    }

    if (value is List) {
      return List<Object?>.from(value);
    }

    return const [];
  }

  String? _asString(Object? value) {
    return value is String ? value : null;
  }

  int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return null;
  }

  Map<String, Object?> _providerMetadataValues(ProviderMetadata? metadata) {
    final values = metadata?.values['anthropic'];
    if (values is Map<String, Object?>) {
      return values;
    }

    if (values is Map) {
      return Map<String, Object?>.from(values);
    }

    return const {};
  }

  String _fallbackToolName(String blockType) {
    switch (blockType) {
      case 'web_fetch_tool_result':
        return 'web_fetch';
      case 'web_search_tool_result':
        return 'web_search';
      case 'code_execution_tool_result':
      case 'bash_code_execution_tool_result':
      case 'text_editor_code_execution_tool_result':
        return 'code_execution';
      case 'tool_search_tool_result':
        return 'tool_search';
      case 'mcp_tool_result':
        return 'mcp.unknown';
      default:
        return 'tool';
    }
  }

  bool _isDynamicToolResult(String blockType) {
    return blockType == 'web_fetch_tool_result' ||
        blockType == 'web_search_tool_result' ||
        blockType == 'code_execution_tool_result' ||
        blockType == 'bash_code_execution_tool_result' ||
        blockType == 'text_editor_code_execution_tool_result' ||
        blockType == 'tool_search_tool_result' ||
        blockType == 'mcp_tool_result';
  }

  bool _isErrorToolResult(
    String blockType,
    Map<String, Object?> contentBlock,
  ) {
    if (blockType == 'mcp_tool_result') {
      return contentBlock['is_error'] == true;
    }

    final content = _asMap(contentBlock['content']);
    final contentType = _asString(content?['type']);
    return contentType != null && contentType.endsWith('_error');
  }

  ToolOutput _toolResultOutput(
    String blockType,
    Map<String, Object?> contentBlock,
  ) {
    return ToolOutput.fromValue(
      normalizeJsonValue(contentBlock['content']),
      isError: _isErrorToolResult(blockType, contentBlock),
    );
  }

  String? _toolResultCustomKind(String blockType) {
    switch (blockType) {
      case 'web_fetch_tool_result':
        return 'anthropic.result.web_fetch';
      case 'web_search_tool_result':
        return 'anthropic.result.web_search';
      case 'tool_search_tool_result':
        return 'anthropic.result.tool_search';
      case 'code_execution_tool_result':
      case 'bash_code_execution_tool_result':
      case 'text_editor_code_execution_tool_result':
        return 'anthropic.result.code_execution';
      default:
        return null;
    }
  }

  Map<String, Object?> _toolResultReplayPayload({
    required String blockType,
    required Map<String, Object?> block,
    required String toolCallId,
    required String toolName,
  }) {
    final replayToolName =
        _isExecutionToolResultBlock(blockType) ? 'code_execution' : toolName;

    return {
      if (_isExecutionToolResultBlock(blockType))
        'schema': 'anthropic.execution.result.v1',
      'replayRole': 'tool',
      'toolCallId': toolCallId,
      'toolName': replayToolName,
      if (_isExecutionToolResultBlock(blockType)) 'blockType': blockType,
      'block': normalizeJsonValue(block),
    };
  }

  bool _isExecutionToolResultBlock(String blockType) {
    return blockType == 'code_execution_tool_result' ||
        blockType == 'bash_code_execution_tool_result' ||
        blockType == 'text_editor_code_execution_tool_result';
  }
}

sealed class _AnthropicContentBlockState {
  ProviderMetadata? get providerMetadata;
}

final class _AnthropicTextBlockState extends _AnthropicContentBlockState {
  final String id;

  @override
  final ProviderMetadata? providerMetadata;

  _AnthropicTextBlockState({
    required this.id,
    this.providerMetadata,
  });
}

final class _AnthropicReasoningBlockState extends _AnthropicContentBlockState {
  final String id;

  @override
  final ProviderMetadata? providerMetadata;

  _AnthropicReasoningBlockState({
    required this.id,
    this.providerMetadata,
  });
}

final class _AnthropicToolBlockState extends _AnthropicContentBlockState {
  final String toolCallId;
  final String toolName;
  final bool providerExecuted;
  final bool isDynamic;
  final String? title;

  @override
  final ProviderMetadata? providerMetadata;

  final StringBuffer inputBuffer = StringBuffer();

  _AnthropicToolBlockState({
    required this.toolCallId,
    required this.toolName,
    required this.providerExecuted,
    required this.isDynamic,
    required this.title,
    required this.providerMetadata,
  });
}

final class _AnthropicToolDescriptor {
  final String toolName;
  final ProviderMetadata? providerMetadata;
  final bool providerExecuted;
  final bool isDynamic;
  final String? title;

  const _AnthropicToolDescriptor({
    required this.toolName,
    required this.providerMetadata,
    required this.providerExecuted,
    required this.isDynamic,
    required this.title,
  });
}

final class _DecodedJsonValue {
  final Object? value;
  final FormatException? error;

  const _DecodedJsonValue({
    required this.value,
    this.error,
  });
}
