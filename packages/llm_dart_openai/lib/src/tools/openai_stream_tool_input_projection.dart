import '../common/openai_streaming_support.dart';

final class OpenAIResolvedToolInput {
  final String toolCallId;
  final String toolName;
  final String? title;
  final String encodedArguments;
  final Object? decodedInput;
  final FormatException? decodeError;

  const OpenAIResolvedToolInput({
    required this.toolCallId,
    required this.toolName,
    required this.title,
    required this.encodedArguments,
    required this.decodedInput,
    required this.decodeError,
  });
}

OpenAIResolvedToolInput resolveOpenAIStreamToolInput({
  required OpenAIStreamToolCallState toolState,
  required String fallbackToolCallId,
  String fallbackToolName = 'function',
  String fallbackArguments = '{}',
  String? encodedArguments,
}) {
  final resolvedArguments =
      encodedArguments ?? toolState.encodedArguments(fallbackArguments);
  final decodedArguments = tryDecodeOpenAIJsonValue(resolvedArguments);

  return OpenAIResolvedToolInput(
    toolCallId: toolState.resolveToolCallId(fallbackToolCallId),
    toolName: toolState.resolveToolName(fallbackToolName),
    title: toolState.title,
    encodedArguments: resolvedArguments,
    decodedInput: decodedArguments.value,
    decodeError: decodedArguments.error,
  );
}

String formatInvalidOpenAIToolInputError(
  String toolName,
  FormatException error,
) {
  final message = error.message.trim();
  if (message.isEmpty) {
    return 'Invalid JSON tool arguments for "$toolName".';
  }

  return 'Invalid JSON tool arguments for "$toolName": $message';
}
