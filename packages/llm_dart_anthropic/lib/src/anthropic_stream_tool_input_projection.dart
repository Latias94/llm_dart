import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_stream_tool_models.dart';

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
