import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_stream_util.dart';
import 'anthropic_tool_result_projection.dart';

final class AnthropicProjectedToolCall {
  final String toolCallId;
  final String toolName;
  final Object? input;
  final String encodedInput;
  final bool providerExecuted;
  final bool isDynamic;
  final String? title;
  final ProviderMetadata? providerMetadata;

  const AnthropicProjectedToolCall({
    required this.toolCallId,
    required this.toolName,
    required this.input,
    required this.encodedInput,
    this.providerExecuted = false,
    this.isDynamic = false,
    this.title,
    this.providerMetadata,
  });
}

final class AnthropicFinishedToolInputProjection {
  final AnthropicProjectedToolCall? toolCall;
  final ToolInputErrorEvent? errorEvent;

  const AnthropicFinishedToolInputProjection.toolCall(
    AnthropicProjectedToolCall projectedToolCall,
  )   : toolCall = projectedToolCall,
        errorEvent = null;

  const AnthropicFinishedToolInputProjection.error(
    ToolInputErrorEvent projectedError,
  )   : toolCall = null,
        errorEvent = projectedError;

  bool get hasToolCall => toolCall != null;

  Iterable<LanguageModelStreamEvent> emitEvents() sync* {
    final error = errorEvent;
    if (error != null) {
      yield error;
      return;
    }

    final call = toolCall;
    if (call == null) {
      return;
    }

    yield ToolInputEndEvent(
      toolCallId: call.toolCallId,
      providerMetadata: call.providerMetadata,
    );
    yield ToolCallEvent(
      toolCall: anthropicProjectedToolCallContent(call),
      providerMetadata: call.providerMetadata,
    );
  }
}

AnthropicProjectedToolCall projectAnthropicToolCall({
  required String toolCallId,
  required String toolName,
  required Object? input,
  required ProviderMetadata? providerMetadata,
  bool providerExecuted = false,
  bool isDynamic = false,
  String? title,
  bool emitInputDeltaForNull = true,
}) {
  final normalizedInput =
      normalizeJsonValue(input) ?? const <String, Object?>{};
  final encodedInput = input == null && !emitInputDeltaForNull
      ? ''
      : jsonEncode(normalizedInput);

  return AnthropicProjectedToolCall(
    toolCallId: toolCallId,
    toolName: toolName,
    input: normalizedInput,
    encodedInput: encodedInput,
    providerExecuted: providerExecuted,
    isDynamic: isDynamic,
    title: title,
    providerMetadata: providerMetadata,
  );
}

AnthropicFinishedToolInputProjection projectAnthropicFinishedToolInput({
  required String toolCallId,
  required String toolName,
  required String encodedInput,
  required ProviderMetadata? providerMetadata,
  bool providerExecuted = false,
  bool isDynamic = false,
  String? title,
}) {
  final decodedInput = _tryDecodeJsonValue(encodedInput);
  final error = decodedInput.error;
  if (error != null) {
    return AnthropicFinishedToolInputProjection.error(
      ToolInputErrorEvent(
        toolCallId: toolCallId,
        toolName: toolName,
        input: encodedInput,
        errorText: _formatInvalidToolInputError(toolName, error),
        providerExecuted: providerExecuted,
        isDynamic: isDynamic,
        title: title,
        providerMetadata: providerMetadata,
      ),
    );
  }

  return AnthropicFinishedToolInputProjection.toolCall(
    AnthropicProjectedToolCall(
      toolCallId: toolCallId,
      toolName: toolName,
      input: decodedInput.value,
      encodedInput: encodedInput,
      providerExecuted: providerExecuted,
      isDynamic: isDynamic,
      title: title,
      providerMetadata: providerMetadata,
    ),
  );
}

ToolCallContent anthropicProjectedToolCallContent(
  AnthropicProjectedToolCall call,
) {
  return ToolCallContent(
    toolCallId: call.toolCallId,
    toolName: call.toolName,
    input: call.input,
    providerExecuted: call.providerExecuted,
    isDynamic: call.isDynamic,
    title: call.title,
  );
}

Iterable<LanguageModelStreamEvent> emitAnthropicToolInputStartEvents(
  AnthropicProjectedToolCall call,
) sync* {
  yield ToolInputStartEvent(
    toolCallId: call.toolCallId,
    toolName: call.toolName,
    providerExecuted: call.providerExecuted,
    isDynamic: call.isDynamic,
    title: call.title,
    providerMetadata: call.providerMetadata,
  );

  if (call.encodedInput.isNotEmpty) {
    yield ToolInputDeltaEvent(
      toolCallId: call.toolCallId,
      delta: call.encodedInput,
      providerMetadata: call.providerMetadata,
    );
  }
}

Iterable<LanguageModelStreamEvent> emitAnthropicProjectedToolCallEvents(
  AnthropicProjectedToolCall call,
) sync* {
  yield* emitAnthropicToolInputStartEvents(call);
  yield ToolInputEndEvent(
    toolCallId: call.toolCallId,
    providerMetadata: call.providerMetadata,
  );
  yield ToolCallEvent(
    toolCall: anthropicProjectedToolCallContent(call),
    providerMetadata: call.providerMetadata,
  );
}

Iterable<LanguageModelStreamEvent> emitAnthropicImmediateToolResultEvents({
  required String blockType,
  required Map<String, Object?> contentBlock,
  required ProviderMetadata? descriptorProviderMetadata,
  required String? descriptorToolName,
  required bool? descriptorIsDynamic,
}) sync* {
  final toolUseId = anthropicStreamAsString(contentBlock['tool_use_id']);
  if (toolUseId == null) {
    yield CustomEvent(
      kind: 'anthropic.$blockType',
      data: contentBlock,
    );
    return;
  }

  final providerMetadata = anthropicStreamProviderMetadata({
    ...anthropicStreamProviderMetadataValues(descriptorProviderMetadata),
    'blockType': blockType,
  });
  final toolName =
      descriptorToolName ?? anthropicFallbackToolResultName(blockType);

  yield ToolResultEvent(
    toolResult: ToolResultContent(
      toolCallId: toolUseId,
      toolName: toolName,
      toolOutput: anthropicToolResultOutput(blockType, contentBlock),
      isDynamic:
          descriptorIsDynamic ?? isAnthropicDynamicToolResultBlock(blockType),
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
    yield* emitAnthropicWebSearchToolResultSourceEvents(contentBlock);
  }
}

Iterable<SourceEvent> emitAnthropicWebSearchToolResultSourceEvents(
  Map<String, Object?> contentBlock,
) sync* {
  for (final source
      in projectAnthropicWebSearchToolResultSources(contentBlock)) {
    yield SourceEvent(source);
  }
}

Iterable<SourceReference> projectAnthropicWebSearchToolResultSources(
  Map<String, Object?> contentBlock,
) sync* {
  final resultList = contentBlock['content'];
  if (resultList is! List) {
    return;
  }

  for (final item in resultList) {
    final result = anthropicStreamAsMap(item);
    final url = anthropicStreamAsString(result?['url']);
    if (url == null) {
      continue;
    }

    yield SourceReference(
      kind: SourceReferenceKind.url,
      sourceId: url,
      uri: Uri.tryParse(url),
      title: anthropicStreamAsString(result?['title']),
      providerMetadata: anthropicStreamProviderMetadata({
        'pageAge': anthropicStreamAsString(result?['page_age']),
        'resultType': anthropicStreamAsString(result?['type']),
      }),
    );
  }
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

final class _DecodedJsonValue {
  final Object? value;
  final FormatException? error;

  const _DecodedJsonValue({
    required this.value,
    this.error,
  });
}
