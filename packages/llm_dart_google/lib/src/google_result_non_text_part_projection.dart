import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_content_projection_support.dart';
import 'google_file_projection.dart';
import 'google_server_tool_replay.dart';
import 'google_shared.dart';

final class GoogleResultNonTextPartProjection {
  final List<ContentPart> content;
  final bool hasClientToolCalls;

  const GoogleResultNonTextPartProjection({
    required this.content,
    this.hasClientToolCalls = false,
  });
}

Iterable<ContentPart> projectGoogleResultExecutableCodePart({
  required GoogleCodeExecutionTracker tracker,
  required Object? executableCode,
  ProviderMetadata? metadata,
}) sync* {
  final projectedToolCall = projectGoogleCodeExecutionToolCall(
    tracker: tracker,
    executableCode: executableCode,
    providerMetadata: metadata,
  );
  yield googleProjectedToolCallContentPart(projectedToolCall);
}

Iterable<ContentPart> projectGoogleResultCodeExecutionResultPart({
  required GoogleCodeExecutionTracker tracker,
  required Object? executionResult,
  ProviderMetadata? metadata,
}) sync* {
  final projectedToolResult = projectGoogleCodeExecutionToolResult(
    tracker: tracker,
    executionResult: executionResult,
    providerMetadata: metadata,
  );
  yield googleProjectedToolResultContentPart(projectedToolResult);
}

GoogleResultNonTextPartProjection projectGoogleResultFunctionCallPart({
  required Object? functionCallValue,
  required String fallbackToolCallId,
  ProviderMetadata? metadata,
}) {
  final functionCall = asMap(functionCallValue);
  final projectedToolCall = projectGoogleFunctionToolCall(
    functionCall: functionCall,
    fallbackToolCallId: fallbackToolCallId,
    providerMetadata: metadata,
  );
  if (projectedToolCall == null) {
    return const GoogleResultNonTextPartProjection(content: []);
  }

  return GoogleResultNonTextPartProjection(
    content: [googleProjectedToolCallContentPart(projectedToolCall)],
    hasClientToolCalls: true,
  );
}

Iterable<ContentPart> projectGoogleResultServerToolCallPart({
  required Object? toolCallValue,
  ProviderMetadata? metadata,
}) sync* {
  final toolCall = asMap(toolCallValue);
  if (toolCall == null) {
    return;
  }

  final replay = GoogleToolCallReplay.fromToolCall(
    toolCall,
    providerMetadata: metadata,
  );
  yield replay.toCustomContentPart();
}

Iterable<ContentPart> projectGoogleResultServerToolResponsePart({
  required Object? toolResponseValue,
  ProviderMetadata? metadata,
}) sync* {
  final toolResponse = asMap(toolResponseValue);
  if (toolResponse == null) {
    return;
  }

  final replay = GoogleToolResponseReplay.fromToolResponse(
    toolResponse,
    providerMetadata: metadata,
  );
  yield replay.toCustomContentPart();
}

Iterable<ContentPart> projectGoogleResultInlineDataPart({
  required Map<String, Object?> part,
  required Object? inlineDataValue,
  ProviderMetadata? metadata,
}) sync* {
  final projectedFile = projectGoogleInlineDataFile(
    inlineDataValue: inlineDataValue,
    isThought: part['thought'] == true,
    providerMetadata: metadata,
  );
  if (projectedFile != null) {
    yield googleProjectedFileContentPart(projectedFile);
  }
}
