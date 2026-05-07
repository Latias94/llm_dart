part of 'legacy_chat_adapter.dart';

final class _LegacyChatResponse implements ChatResponse {
  @override
  final String? text;

  @override
  final List<ToolCall>? toolCalls;

  @override
  final String? thinking;

  @override
  final UsageInfo? usage;

  const _LegacyChatResponse({
    this.text,
    this.toolCalls,
    this.thinking,
    this.usage,
  });

  factory _LegacyChatResponse.fromResult(core.GenerateTextResult result) {
    final text = result.text.isEmpty ? null : result.text;
    final toolCalls = result.content
        .whereType<core.ToolCallContentPart>()
        .map(
          (part) => _toLegacyToolCall(
            part.toolCall.toolCallId,
            part.toolCall.toolName,
            part.toolCall.input,
          ),
        )
        .toList(growable: false);

    return _LegacyChatResponse(
      text: text,
      toolCalls: toolCalls.isEmpty ? null : toolCalls,
      thinking: result.reasoningText,
      usage: _convertUsage(result.usage),
    );
  }
}

ToolCall _toLegacyToolCall(
  String toolCallId,
  String toolName,
  Object? input,
) {
  return ToolCall(
    id: toolCallId,
    callType: 'function',
    function: FunctionCall(
      name: toolName,
      arguments: _encodeJsonValue(input),
    ),
  );
}

UsageInfo? _convertUsage(core.UsageStats? usage) {
  if (usage == null) {
    return null;
  }

  return UsageInfo(
    promptTokens: usage.inputTokens,
    completionTokens: usage.outputTokens,
    totalTokens: usage.totalTokens,
    reasoningTokens: usage.reasoningTokens,
  );
}

LLMError _toLegacyError(Object error) {
  if (error is LLMError) {
    return error;
  }

  if (error is core.ModelWarning) {
    return GenericError(error.message);
  }

  final message = error.toString();
  if (message.toLowerCase().contains('cancel')) {
    return CancelledError(message);
  }

  return GenericError(message);
}

Future<T> _awaitWithCancellation<T>(
  Future<T> operation,
  TransportCancellation? cancelToken,
) async {
  if (cancelToken == null) {
    return operation;
  }

  return Future.any([
    operation,
    cancelToken.whenCancelled.then<T>((_) => throw const CancelledError()),
  ]);
}
