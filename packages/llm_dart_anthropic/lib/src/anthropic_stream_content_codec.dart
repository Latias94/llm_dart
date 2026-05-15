import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_stream_state.dart';
import 'anthropic_stream_tool_codec.dart';
import 'anthropic_stream_util.dart';

final class AnthropicStreamContentCodec {
  final AnthropicStreamToolCodec toolCodec;

  const AnthropicStreamContentCodec({
    this.toolCodec = const AnthropicStreamToolCodec(),
  });

  Iterable<LanguageModelStreamEvent> decodeContentBlockStart(
    Map<String, Object?> chunk,
    AnthropicMessagesStreamState state,
  ) sync* {
    final index = anthropicStreamAsInt(chunk['index']);
    final contentBlock = anthropicStreamAsMap(chunk['content_block']);
    if (index == null || contentBlock == null) {
      return;
    }

    final blockType = anthropicStreamAsString(contentBlock['type']);
    final blockMetadata = anthropicStreamProviderMetadata({
      'blockIndex': index,
      'blockType': blockType,
    });

    if (blockType == 'text' || blockType == 'compaction') {
      final metadata = blockType == 'compaction'
          ? anthropicStreamProviderMetadata({
              'blockIndex': index,
              'blockType': blockType,
              'type': 'compaction',
            })
          : blockMetadata;
      state.contentBlocksByIndex[index] = AnthropicStreamTextBlockState(
        id: '$index',
        providerMetadata: metadata,
      );
      yield TextStartEvent(id: '$index', providerMetadata: metadata);
      return;
    }

    if (blockType == 'thinking' || blockType == 'redacted_thinking') {
      final metadata = blockType == 'redacted_thinking'
          ? anthropicStreamProviderMetadata({
              'blockIndex': index,
              'blockType': blockType,
              'redactedData': contentBlock['data'],
            })
          : blockMetadata;
      state.contentBlocksByIndex[index] = AnthropicStreamReasoningBlockState(
        id: '$index',
        providerMetadata: metadata,
      );
      yield ReasoningStartEvent(id: '$index', providerMetadata: metadata);
      return;
    }

    if (blockType == 'tool_use') {
      yield* toolCodec.startToolBlock(
        index: index,
        toolCallId:
            anthropicStreamAsString(contentBlock['id']) ?? 'tool-$index',
        toolName: anthropicStreamAsString(contentBlock['name']) ?? 'tool',
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
      final toolName = anthropicStreamAsString(contentBlock['name']) ?? 'tool';
      yield* toolCodec.startToolBlock(
        index: index,
        toolCallId:
            anthropicStreamAsString(contentBlock['id']) ?? 'tool-$index',
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
      final rawToolName =
          anthropicStreamAsString(contentBlock['name']) ?? 'tool';
      yield* toolCodec.startToolBlock(
        index: index,
        toolCallId:
            anthropicStreamAsString(contentBlock['id']) ?? 'tool-$index',
        toolName: 'mcp.$rawToolName',
        initialInput: contentBlock['input'],
        providerExecuted: true,
        isDynamic: true,
        title: anthropicStreamAsString(contentBlock['server_name']),
        metadataValues: {
          'blockIndex': index,
          'blockType': blockType,
          'serverName': anthropicStreamAsString(contentBlock['server_name']),
        },
        state: state,
      );
      return;
    }

    if (toolCodec.isImmediateToolResultBlock(blockType)) {
      yield* toolCodec.emitImmediateToolResult(
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
  }

  Iterable<LanguageModelStreamEvent> decodeContentBlockDelta(
    Map<String, Object?> chunk,
    AnthropicMessagesStreamState state,
  ) sync* {
    final index = anthropicStreamAsInt(chunk['index']);
    final delta = anthropicStreamAsMap(chunk['delta']);
    if (index == null || delta == null) {
      return;
    }

    final deltaType = anthropicStreamAsString(delta['type']);
    final contentBlock = state.contentBlocksByIndex[index];
    if (deltaType == 'text_delta' || deltaType == 'compaction_delta') {
      if (contentBlock is! AnthropicStreamTextBlockState) {
        return;
      }

      final value = deltaType == 'text_delta'
          ? anthropicStreamAsString(delta['text'])
          : anthropicStreamAsString(delta['content']);
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
      if (contentBlock is! AnthropicStreamReasoningBlockState) {
        return;
      }

      final value = anthropicStreamAsString(delta['thinking']);
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
      if (contentBlock is! AnthropicStreamReasoningBlockState) {
        return;
      }

      yield ReasoningDeltaEvent(
        id: contentBlock.id,
        delta: '',
        providerMetadata: anthropicStreamProviderMetadata({
          'blockIndex': index,
          'blockType': 'thinking',
          'signature': anthropicStreamAsString(delta['signature']),
        }),
      );
      return;
    }

    if (deltaType == 'input_json_delta') {
      if (contentBlock is! AnthropicStreamToolBlockState) {
        return;
      }

      final partialJson = anthropicStreamAsString(delta['partial_json']);
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
      final citation = anthropicStreamAsMap(delta['citation']);
      final source = _decodeCitationSource(citation);
      if (source != null) {
        yield SourceEvent(source);
      }
    }
  }

  Iterable<LanguageModelStreamEvent> decodeContentBlockStop(
    Map<String, Object?> chunk,
    AnthropicMessagesStreamState state,
  ) sync* {
    final index = anthropicStreamAsInt(chunk['index']);
    if (index == null) {
      return;
    }

    final contentBlock = state.contentBlocksByIndex.remove(index);
    if (contentBlock is AnthropicStreamTextBlockState) {
      yield TextEndEvent(
        id: contentBlock.id,
        providerMetadata: contentBlock.providerMetadata,
      );
      return;
    }

    if (contentBlock is AnthropicStreamReasoningBlockState) {
      yield ReasoningEndEvent(
        id: contentBlock.id,
        providerMetadata: contentBlock.providerMetadata,
      );
      return;
    }

    if (contentBlock is AnthropicStreamToolBlockState) {
      yield* toolCodec.finishToolBlock(contentBlock, state);
    }
  }

  SourceReference? _decodeCitationSource(Map<String, Object?>? citation) {
    if (citation == null) {
      return null;
    }

    final type = anthropicStreamAsString(citation['type']);
    if (type == 'web_search_result_location') {
      final url = anthropicStreamAsString(citation['url']);
      if (url == null) {
        return null;
      }

      return SourceReference(
        kind: SourceReferenceKind.url,
        sourceId: url,
        uri: Uri.tryParse(url),
        title: anthropicStreamAsString(citation['title']),
        providerMetadata: anthropicStreamProviderMetadata({
          'citationType': type,
          'citedText': anthropicStreamAsString(citation['cited_text']),
          'encryptedIndex':
              anthropicStreamAsString(citation['encrypted_index']),
        }),
      );
    }

    if (type == 'page_location' || type == 'char_location') {
      final documentIndex = anthropicStreamAsInt(citation['document_index']);
      return SourceReference(
        kind: SourceReferenceKind.document,
        sourceId: 'document-${documentIndex ?? 0}',
        title: anthropicStreamAsString(citation['document_title']),
        providerMetadata: anthropicStreamProviderMetadata({
          'citationType': type,
          'citedText': anthropicStreamAsString(citation['cited_text']),
          'documentIndex': documentIndex,
          'startPageNumber':
              anthropicStreamAsInt(citation['start_page_number']),
          'endPageNumber': anthropicStreamAsInt(citation['end_page_number']),
          'startCharIndex': anthropicStreamAsInt(citation['start_char_index']),
          'endCharIndex': anthropicStreamAsInt(citation['end_char_index']),
        }),
      );
    }

    return null;
  }
}
