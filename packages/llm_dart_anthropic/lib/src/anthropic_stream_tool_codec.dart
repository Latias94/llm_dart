import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_stream_state.dart';
import 'anthropic_tool_result_projection.dart';
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
    final toolName =
        descriptor?.toolName ?? anthropicFallbackToolResultName(blockType);

    yield ToolResultEvent(
      toolResult: ToolResultContent(
        toolCallId: toolUseId,
        toolName: toolName,
        toolOutput: anthropicToolResultOutput(blockType, contentBlock),
        isDynamic: descriptor?.isDynamic ??
            isAnthropicDynamicToolResultBlock(blockType),
      ),
      providerMetadata: providerMetadata,
    );

    final customKind = anthropicToolResultCustomKind(blockType);
    if (customKind != null) {
      yield CustomEvent(
        kind: customKind,
        data: anthropicToolResultReplayPayload(
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
    return isAnthropicToolResultBlockType(blockType);
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
}

final class _DecodedJsonValue {
  final Object? value;
  final FormatException? error;

  const _DecodedJsonValue({
    required this.value,
    this.error,
  });
}
