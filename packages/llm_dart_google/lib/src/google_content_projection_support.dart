import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_provider_metadata_support.dart';
import 'google_shared.dart';

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

ToolCallContent googleProjectedToolCallContent(GoogleProjectedToolCall call) {
  return ToolCallContent(
    toolCallId: call.toolCallId,
    toolName: call.toolName,
    input: call.input,
    providerExecuted: call.providerExecuted,
    isDynamic: call.isDynamic,
  );
}

ToolResultContent googleProjectedToolResultContent(
  GoogleProjectedToolResult result,
) {
  return ToolResultContent(
    toolCallId: result.toolCallId,
    toolName: result.toolName,
    toolOutput: result.toolOutput,
    isDynamic: result.isDynamic,
  );
}

ToolCallContentPart googleProjectedToolCallContentPart(
  GoogleProjectedToolCall call,
) {
  return ToolCallContentPart(
    googleProjectedToolCallContent(call),
    providerMetadata: call.providerMetadata,
  );
}

ToolResultContentPart googleProjectedToolResultContentPart(
  GoogleProjectedToolResult result,
) {
  return ToolResultContentPart(
    googleProjectedToolResultContent(result),
    providerMetadata: result.providerMetadata,
  );
}

Iterable<LanguageModelStreamEvent> emitGoogleProjectedToolCallEvents(
  GoogleProjectedToolCall call,
) sync* {
  yield ToolInputStartEvent(
    toolCallId: call.toolCallId,
    toolName: call.toolName,
    providerExecuted: call.providerExecuted,
    isDynamic: call.isDynamic,
    providerMetadata: call.providerMetadata,
  );
  yield ToolInputDeltaEvent(
    toolCallId: call.toolCallId,
    delta: call.encodedInput,
    providerMetadata: call.providerMetadata,
  );
  yield ToolInputEndEvent(
    toolCallId: call.toolCallId,
    providerMetadata: call.providerMetadata,
  );
  yield ToolCallEvent(
    toolCall: googleProjectedToolCallContent(call),
    providerMetadata: call.providerMetadata,
  );
}

ToolResultEvent googleProjectedToolResultEvent(
  GoogleProjectedToolResult result,
) {
  return ToolResultEvent(
    toolResult: googleProjectedToolResultContent(result),
    providerMetadata: result.providerMetadata,
  );
}

void attachGoogleMetadataToLastContent(
  List<ContentPart> content,
  ProviderMetadata? metadata,
) {
  if (metadata == null || content.isEmpty) {
    return;
  }

  final last = content.removeLast();
  switch (last) {
    case TextContentPart(:final text, :final providerMetadata):
      content.add(
        TextContentPart(
          text,
          providerMetadata: mergeProviderMetadata(providerMetadata, metadata),
        ),
      );
    case ReasoningContentPart(:final text, :final providerMetadata):
      content.add(
        ReasoningContentPart(
          text,
          providerMetadata: mergeProviderMetadata(providerMetadata, metadata),
        ),
      );
    case ReasoningFileContentPart(:final file, :final providerMetadata):
      content.add(
        ReasoningFileContentPart(
          file,
          providerMetadata: mergeProviderMetadata(providerMetadata, metadata),
        ),
      );
    case ToolCallContentPart(:final toolCall, :final providerMetadata):
      content.add(
        ToolCallContentPart(
          toolCall,
          providerMetadata: mergeProviderMetadata(providerMetadata, metadata),
        ),
      );
    case ToolResultContentPart(:final toolResult, :final providerMetadata):
      content.add(
        ToolResultContentPart(
          toolResult,
          providerMetadata: mergeProviderMetadata(providerMetadata, metadata),
        ),
      );
    case FileContentPart(:final file, :final providerMetadata):
      content.add(
        FileContentPart(
          file,
          providerMetadata: mergeProviderMetadata(providerMetadata, metadata),
        ),
      );
    case CustomContentPart(
        :final kind,
        :final data,
        :final providerMetadata,
      ):
      content.add(
        CustomContentPart(
          kind: kind,
          data: data,
          providerMetadata: mergeProviderMetadata(providerMetadata, metadata),
        ),
      );
    default:
      content.add(last);
  }
}

bool isGoogleCodeExecutionError(Map<String, Object?>? result) {
  final outcome = asString(result?['outcome'])?.toLowerCase();
  if (outcome == null) {
    return false;
  }

  return outcome.contains('error') || outcome.contains('fail');
}
