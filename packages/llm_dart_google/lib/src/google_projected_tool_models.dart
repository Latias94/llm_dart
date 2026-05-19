import 'package:llm_dart_provider/llm_dart_provider.dart';

final class GoogleCodeExecutionTracker {
  int counter;
  String? lastToolCallId;

  GoogleCodeExecutionTracker({
    this.counter = 0,
    this.lastToolCallId,
  });

  String startToolCall() {
    final toolCallId = 'code-execution-$counter';
    counter += 1;
    lastToolCallId = toolCallId;
    return toolCallId;
  }

  String consumeResultToolCall() {
    final toolCallId = lastToolCallId ?? 'code-execution-$counter';
    if (lastToolCallId == null) {
      counter += 1;
    }
    lastToolCallId = null;
    return toolCallId;
  }
}

final class GoogleProjectedToolCall {
  final String toolCallId;
  final String toolName;
  final Object? input;
  final String encodedInput;
  final bool providerExecuted;
  final bool isDynamic;
  final ProviderMetadata? providerMetadata;

  const GoogleProjectedToolCall({
    required this.toolCallId,
    required this.toolName,
    required this.input,
    required this.encodedInput,
    this.providerExecuted = false,
    this.isDynamic = false,
    this.providerMetadata,
  });
}

final class GoogleProjectedToolResult {
  final String toolCallId;
  final String toolName;
  final ToolOutput toolOutput;
  final bool isDynamic;
  final ProviderMetadata? providerMetadata;

  const GoogleProjectedToolResult({
    required this.toolCallId,
    required this.toolName,
    required this.toolOutput,
    this.isDynamic = false,
    this.providerMetadata,
  });
}
