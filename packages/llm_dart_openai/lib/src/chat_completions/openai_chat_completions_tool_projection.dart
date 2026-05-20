import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../common/openai_streaming_support.dart';

List<ToolCallContentPart> decodeOpenAIChatCompletionsToolCalls(
  List<Object?> rawToolCalls, {
  required ProviderMetadata? Function(Map<String, Object?> values)
      providerMetadata,
}) {
  final result = <ToolCallContentPart>[];

  for (final rawToolCall in rawToolCalls) {
    final toolCall = _asMap(rawToolCall);
    if (toolCall == null) {
      continue;
    }

    final toolCallId = _asString(toolCall['id']);
    final function = _asMap(toolCall['function']);
    final toolName = _asString(function?['name']);
    if (toolCallId == null || toolName == null) {
      continue;
    }

    final encodedArguments = _asString(function?['arguments']) ?? '{}';
    result.add(
      ToolCallContentPart(
        ToolCallContent(
          toolCallId: toolCallId,
          toolName: toolName,
          input: tryDecodeOpenAIJsonValue(encodedArguments).value,
        ),
        providerMetadata: providerMetadata({
          'toolCallId': toolCallId,
        }),
      ),
    );
  }

  return result;
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

String? _asString(Object? value) => value is String ? value : null;
