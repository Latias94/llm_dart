import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_stream_state.dart';
import 'anthropic_stream_util.dart';

final class AnthropicStreamToolCodec {
  const AnthropicStreamToolCodec();

  Iterable<LanguageModelStreamEvent> emitPrepopulatedToolCall(
    Map<String, Object?> part,
    AnthropicMessagesStreamState state,
  ) sync* {
    final toolCallId = anthropicStreamAsString(part['id']);
    final toolName = anthropicStreamAsString(part['name']);
    if (toolCallId == null || toolName == null) {
      return;
    }

    final input =
        normalizeJsonValue(part['input']) ?? const <String, Object?>{};
    final encodedInput = jsonEncode(input);
    final providerMetadata = anthropicStreamProviderMetadata({
      'caller': part['caller'],
    });

    state.toolDescriptorsById[toolCallId] = AnthropicStreamToolDescriptor(
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

  Iterable<LanguageModelStreamEvent> startToolBlock({
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
    final providerMetadata = anthropicStreamProviderMetadata(metadataValues);
    final initialInputValue =
        normalizeJsonValue(initialInput) ?? const <String, Object?>{};
    final encodedInitialInput =
        initialInput == null ? '' : jsonEncode(initialInputValue);

    final toolState = AnthropicStreamToolBlockState(
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

    state.contentBlocksByIndex[index] = toolState;
    state.toolDescriptorsById[toolCallId] = AnthropicStreamToolDescriptor(
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

  Iterable<LanguageModelStreamEvent> finishToolBlock(
    AnthropicStreamToolBlockState contentBlock,
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

    state.toolDescriptorsById[contentBlock.toolCallId] =
        AnthropicStreamToolDescriptor(
      toolName: contentBlock.toolName,
      providerMetadata: contentBlock.providerMetadata,
      providerExecuted: contentBlock.providerExecuted,
      isDynamic: contentBlock.isDynamic,
      title: contentBlock.title,
    );
  }

  Iterable<LanguageModelStreamEvent> emitImmediateToolResult({
    required String blockType,
    required Map<String, Object?> contentBlock,
    required AnthropicMessagesStreamState state,
  }) sync* {
    final toolUseId = anthropicStreamAsString(contentBlock['tool_use_id']);
    if (toolUseId == null) {
      yield CustomEvent(
        kind: 'anthropic.$blockType',
        data: contentBlock,
      );
      return;
    }

    final descriptor = state.toolDescriptorsById[toolUseId];
    final providerMetadata = anthropicStreamProviderMetadata({
      ...anthropicStreamProviderMetadataValues(descriptor?.providerMetadata),
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
          final result = anthropicStreamAsMap(item);
          final url = anthropicStreamAsString(result?['url']);
          if (url == null) {
            continue;
          }

          yield SourceEvent(
            SourceReference(
              kind: SourceReferenceKind.url,
              sourceId: url,
              uri: Uri.tryParse(url),
              title: anthropicStreamAsString(result?['title']),
              providerMetadata: anthropicStreamProviderMetadata({
                'pageAge': anthropicStreamAsString(result?['page_age']),
                'resultType': anthropicStreamAsString(result?['type']),
              }),
            ),
          );
        }
      }
    }
  }

  bool isImmediateToolResultBlock(String? blockType) {
    return blockType == 'web_fetch_tool_result' ||
        blockType == 'web_search_tool_result' ||
        blockType == 'code_execution_tool_result' ||
        blockType == 'bash_code_execution_tool_result' ||
        blockType == 'text_editor_code_execution_tool_result' ||
        blockType == 'tool_search_tool_result' ||
        blockType == 'mcp_tool_result';
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

    final content = anthropicStreamAsMap(contentBlock['content']);
    final contentType = anthropicStreamAsString(content?['type']);
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

final class _DecodedJsonValue {
  final Object? value;
  final FormatException? error;

  const _DecodedJsonValue({
    required this.value,
    this.error,
  });
}
