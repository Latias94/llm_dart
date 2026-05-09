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

Iterable<SourceContentPart> projectGoogleGroundingContentParts(
  Map<String, Object?>? groundingMetadata,
) sync* {
  for (final source in extractGroundingSources(groundingMetadata)) {
    yield SourceContentPart(source);
  }
}

Iterable<SourceEvent> emitGoogleGroundingSourceEvents(
  Map<String, Object?>? groundingMetadata, {
  required Set<String> emittedSourceKeys,
}) sync* {
  for (final source in extractGroundingSources(groundingMetadata)) {
    final key = '${source.kind}:${source.sourceId}';
    if (emittedSourceKeys.add(key)) {
      yield SourceEvent(source);
    }
  }
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
