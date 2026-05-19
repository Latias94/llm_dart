import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_content_projection_support.dart';
import 'google_file_projection.dart';
import 'google_provider_metadata_support.dart';
import 'google_server_tool_replay.dart';
import 'google_shared.dart';
import 'google_stream_block_projection.dart';
import 'google_stream_state.dart';

final class GoogleStreamPartCodec {
  const GoogleStreamPartCodec();

  Iterable<LanguageModelStreamEvent> decodePart(
    Map<String, Object?> part,
    GoogleGenerateContentStreamState state,
  ) sync* {
    final metadata = googleThoughtSignatureMetadata(
      asString(part['thoughtSignature']),
      isThought: part['thought'] == true,
    );

    if (part case {'executableCode': final Object? executableCode}) {
      yield* closeGoogleStreamBlocks(state);

      final projectedToolCall = projectGoogleCodeExecutionToolCall(
        tracker: state.codeExecutionTracker,
        executableCode: executableCode,
        providerMetadata: metadata,
      );

      yield* emitGoogleProjectedToolCallEvents(projectedToolCall);
      return;
    }

    if (part case {'codeExecutionResult': final Object? executionResult}) {
      yield* closeGoogleStreamBlocks(state);

      final projectedToolResult = projectGoogleCodeExecutionToolResult(
        tracker: state.codeExecutionTracker,
        executionResult: executionResult,
        providerMetadata: metadata,
      );
      yield googleProjectedToolResultEvent(projectedToolResult);
      return;
    }

    if (part case {'functionCall': final Object? functionCallValue}) {
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
      return;
    }

    if (part case {'toolCall': final Object? toolCallValue}) {
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
      return;
    }

    if (part case {'toolResponse': final Object? toolResponseValue}) {
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
      return;
    }

    if (part case {'text': final Object? textValue}) {
      yield* decodeGoogleStreamTextPart(
        part,
        textValue: textValue,
        metadata: metadata,
        state: state,
      );
      return;
    }

    if (part case {'inlineData': final Object? inlineDataValue}) {
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
  }
}
