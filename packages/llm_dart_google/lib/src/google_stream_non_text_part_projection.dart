import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_content_projection_support.dart';
import 'google_file_projection.dart';
import 'google_server_tool_replay.dart';
import 'google_shared.dart';
import 'google_stream_block_projection.dart';
import 'google_stream_state.dart';

Iterable<LanguageModelStreamEvent> decodeGoogleStreamExecutableCodePart(
  Object? executableCode,
  GoogleGenerateContentStreamState state,
  ProviderMetadata? metadata,
) sync* {
  yield* closeGoogleStreamBlocks(state);

  final projectedToolCall = projectGoogleCodeExecutionToolCall(
    tracker: state.codeExecutionTracker,
    executableCode: executableCode,
    providerMetadata: metadata,
  );

  yield* emitGoogleProjectedToolCallEvents(projectedToolCall);
}

Iterable<LanguageModelStreamEvent> decodeGoogleStreamCodeExecutionResultPart(
  Object? executionResult,
  GoogleGenerateContentStreamState state,
  ProviderMetadata? metadata,
) sync* {
  yield* closeGoogleStreamBlocks(state);

  final projectedToolResult = projectGoogleCodeExecutionToolResult(
    tracker: state.codeExecutionTracker,
    executionResult: executionResult,
    providerMetadata: metadata,
  );
  yield googleProjectedToolResultEvent(projectedToolResult);
}

Iterable<LanguageModelStreamEvent> decodeGoogleStreamFunctionCallPart(
  Object? functionCallValue,
  GoogleGenerateContentStreamState state,
  ProviderMetadata? metadata,
) sync* {
  yield* closeGoogleStreamBlocks(state);

  final functionCall = asMap(functionCallValue);
  final functionCallId = asString(functionCall?['id']);
  final projectedToolCall = projectGoogleFunctionToolCall(
    functionCall: functionCall,
    fallbackToolCallId: 'tool-${state.toolCounter}',
    providerMetadata: metadata,
  );
  if (projectedToolCall == null) {
    return;
  }

  state.hasClientToolCalls = true;
  if (functionCallId == null) {
    state.toolCounter += 1;
  }

  yield* emitGoogleProjectedToolCallEvents(projectedToolCall);
}

Iterable<LanguageModelStreamEvent> decodeGoogleStreamServerToolCallPart(
  Object? toolCallValue,
  GoogleGenerateContentStreamState state,
  ProviderMetadata? metadata,
) sync* {
  yield* closeGoogleStreamBlocks(state);

  final toolCall = asMap(toolCallValue);
  if (toolCall == null) {
    return;
  }

  final replay = GoogleToolCallReplay.fromToolCall(
    toolCall,
    providerMetadata: metadata,
  );
  yield replay.toCustomEvent();
}

Iterable<LanguageModelStreamEvent> decodeGoogleStreamServerToolResponsePart(
  Object? toolResponseValue,
  GoogleGenerateContentStreamState state,
  ProviderMetadata? metadata,
) sync* {
  yield* closeGoogleStreamBlocks(state);

  final toolResponse = asMap(toolResponseValue);
  if (toolResponse == null) {
    return;
  }

  final replay = GoogleToolResponseReplay.fromToolResponse(
    toolResponse,
    providerMetadata: metadata,
  );
  yield replay.toCustomEvent();
}

Iterable<LanguageModelStreamEvent> decodeGoogleStreamInlineDataPart(
  Map<String, Object?> part,
  Object? inlineDataValue,
  GoogleGenerateContentStreamState state,
  ProviderMetadata? metadata,
) sync* {
  yield* closeGoogleStreamBlocks(state);

  final projectedFile = projectGoogleInlineDataFile(
    inlineDataValue: inlineDataValue,
    isThought: part['thought'] == true,
    providerMetadata: metadata,
  );
  if (projectedFile != null) {
    yield googleProjectedFileEvent(projectedFile);
  }
}
