import 'package:llm_dart_provider/llm_dart_provider.dart';

final class OpenAIResponsesNativeShellCallProjection {
  final String toolCallId;
  final String toolName;
  final Object? input;
  final bool providerExecuted;
  final ProviderMetadata? providerMetadata;

  const OpenAIResponsesNativeShellCallProjection({
    required this.toolCallId,
    required this.toolName,
    required this.input,
    required this.providerExecuted,
    required this.providerMetadata,
  });

  ToolCallContent toToolCall() {
    return ToolCallContent(
      toolCallId: toolCallId,
      toolName: toolName,
      input: input,
      providerExecuted: providerExecuted,
    );
  }
}

final class OpenAIResponsesNativeShellOutputProjection {
  final String toolCallId;
  final String toolName;
  final Object? output;
  final ProviderMetadata? providerMetadata;

  const OpenAIResponsesNativeShellOutputProjection({
    required this.toolCallId,
    required this.toolName,
    required this.output,
    required this.providerMetadata,
  });

  ToolResultContent toToolResult() {
    return ToolResultContent(
      toolCallId: toolCallId,
      toolName: toolName,
      output: output,
    );
  }
}
