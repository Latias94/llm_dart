import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_content_projection_support.dart';
import 'google_file_projection.dart';
import 'google_provider_metadata_support.dart';
import 'google_server_tool_replay.dart';
import 'google_shared.dart';
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
      yield* closeOpenBlocks(state);

      final projectedToolCall = projectGoogleCodeExecutionToolCall(
        tracker: state.codeExecutionTracker,
        executableCode: executableCode,
        providerMetadata: metadata,
      );

      yield* emitGoogleProjectedToolCallEvents(projectedToolCall);
      return;
    }

    if (part case {'codeExecutionResult': final Object? executionResult}) {
      yield* closeOpenBlocks(state);

      final projectedToolResult = projectGoogleCodeExecutionToolResult(
        tracker: state.codeExecutionTracker,
        executionResult: executionResult,
        providerMetadata: metadata,
      );
      yield googleProjectedToolResultEvent(projectedToolResult);
      return;
    }

    if (part case {'functionCall': final Object? functionCallValue}) {
      yield* closeOpenBlocks(state);

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
      yield* closeOpenBlocks(state);

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
      yield* closeOpenBlocks(state);

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
      yield* _decodeTextPart(
        part,
        textValue: textValue,
        metadata: metadata,
        state: state,
      );
      return;
    }

    if (part case {'inlineData': final Object? inlineDataValue}) {
      yield* closeOpenBlocks(state);

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

  Iterable<LanguageModelStreamEvent> closeOpenBlocks(
    GoogleGenerateContentStreamState state,
  ) sync* {
    if (state.currentTextBlockId != null) {
      yield TextEndEvent(id: state.currentTextBlockId!);
      state.currentTextBlockId = null;
    }

    if (state.currentReasoningBlockId != null) {
      yield ReasoningEndEvent(id: state.currentReasoningBlockId!);
      state.currentReasoningBlockId = null;
    }
  }

  Iterable<LanguageModelStreamEvent> _decodeTextPart(
    Map<String, Object?> part, {
    required Object? textValue,
    required ProviderMetadata? metadata,
    required GoogleGenerateContentStreamState state,
  }) sync* {
    final text = asString(textValue) ?? '';
    if (part['thought'] == true) {
      if (state.currentTextBlockId != null) {
        yield TextEndEvent(id: state.currentTextBlockId!);
        state.currentTextBlockId = null;
      }

      final shouldStart = state.currentReasoningBlockId == null;
      state.currentReasoningBlockId ??= '${state.blockCounter++}';

      if (shouldStart) {
        yield ReasoningStartEvent(
          id: state.currentReasoningBlockId!,
          providerMetadata: metadata,
        );
      }

      if (text.isEmpty) {
        if (metadata != null) {
          yield ReasoningDeltaEvent(
            id: state.currentReasoningBlockId!,
            delta: '',
            providerMetadata: metadata,
          );
        }
      } else {
        yield ReasoningDeltaEvent(
          id: state.currentReasoningBlockId!,
          delta: text,
          providerMetadata: metadata,
        );
      }
      return;
    }

    if (state.currentReasoningBlockId != null) {
      yield ReasoningEndEvent(id: state.currentReasoningBlockId!);
      state.currentReasoningBlockId = null;
    }

    final shouldStart = state.currentTextBlockId == null;
    state.currentTextBlockId ??= '${state.blockCounter++}';

    if (shouldStart) {
      yield TextStartEvent(
        id: state.currentTextBlockId!,
        providerMetadata: metadata,
      );
    }

    if (text.isEmpty) {
      if (metadata != null) {
        yield TextDeltaEvent(
          id: state.currentTextBlockId!,
          delta: '',
          providerMetadata: metadata,
        );
      }
    } else {
      yield TextDeltaEvent(
        id: state.currentTextBlockId!,
        delta: text,
        providerMetadata: metadata,
      );
    }
  }
}
