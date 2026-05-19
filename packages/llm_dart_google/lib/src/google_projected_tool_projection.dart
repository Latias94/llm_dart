import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_projected_tool_models.dart';
import 'google_provider_metadata_support.dart';
import 'google_shared.dart';

GoogleProjectedToolCall projectGoogleCodeExecutionToolCall({
  required GoogleCodeExecutionTracker tracker,
  required Object? executableCode,
  ProviderMetadata? providerMetadata,
}) {
  final toolCallId = tracker.startToolCall();
  final input = normalizeJsonValue(executableCode) ?? const <String, Object?>{};

  return GoogleProjectedToolCall(
    toolCallId: toolCallId,
    toolName: 'code_execution',
    input: input,
    encodedInput: jsonEncode(input),
    providerExecuted: true,
    isDynamic: true,
    providerMetadata: providerMetadata,
  );
}

GoogleProjectedToolResult projectGoogleCodeExecutionToolResult({
  required GoogleCodeExecutionTracker tracker,
  required Object? executionResult,
  ProviderMetadata? providerMetadata,
}) {
  final normalizedResult = asMap(executionResult);

  return GoogleProjectedToolResult(
    toolCallId: tracker.consumeResultToolCall(),
    toolName: 'code_execution',
    toolOutput: ToolOutput.fromValue(
      normalizeJsonValue(executionResult),
      isError: isGoogleCodeExecutionError(normalizedResult),
    ),
    isDynamic: true,
    providerMetadata: providerMetadata,
  );
}

GoogleProjectedToolCall? projectGoogleFunctionToolCall({
  required Map<String, Object?>? functionCall,
  required String fallbackToolCallId,
  ProviderMetadata? providerMetadata,
}) {
  final toolName = asString(functionCall?['name']);
  if (toolName == null) {
    return null;
  }

  final functionCallId = asString(functionCall?['id']);
  final input =
      normalizeJsonValue(functionCall?['args']) ?? const <String, Object?>{};

  return GoogleProjectedToolCall(
    toolCallId: functionCallId ?? fallbackToolCallId,
    toolName: toolName,
    input: input,
    encodedInput: jsonEncode(input),
    providerMetadata: mergeProviderMetadata(
      providerMetadata,
      googleFunctionCallIdMetadata(functionCallId),
    ),
  );
}

bool isGoogleCodeExecutionError(Map<String, Object?>? result) {
  final outcome = asString(result?['outcome'])?.toLowerCase();
  if (outcome == null) {
    return false;
  }

  return outcome.contains('error') || outcome.contains('fail');
}
