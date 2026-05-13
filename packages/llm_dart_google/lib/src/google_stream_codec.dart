import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_content_projection_support.dart';
import 'google_provider_metadata_support.dart';
import 'google_server_tool_replay.dart';
import 'google_shared.dart';

final class GoogleGenerateContentStreamState {
  String? responseId;
  String? modelVersion;
  Map<String, Object?>? promptFeedback;
  Map<String, Object?>? usageMetadata;
  Map<String, Object?>? groundingMetadata;
  Map<String, Object?>? urlContextMetadata;
  List<Object?>? safetyRatings;
  String? rawFinishReason;
  String? finishMessage;

  String? currentTextBlockId;
  String? currentReasoningBlockId;

  int blockCounter = 0;
  int toolCounter = 0;
  bool hasClientToolCalls = false;
  bool emittedResponseMetadata = false;
  bool finished = false;

  final Set<String> emittedSourceKeys = {};
  final GoogleCodeExecutionTracker codeExecutionTracker =
      GoogleCodeExecutionTracker();
}

final class GoogleGenerateContentStreamCodec {
  const GoogleGenerateContentStreamCodec();

  Iterable<LanguageModelStreamEvent> decodeChunk(
    Map<String, Object?> chunk,
    GoogleGenerateContentStreamState state,
  ) sync* {
    state.responseId = asString(chunk['responseId']) ?? state.responseId;
    state.modelVersion = asString(chunk['modelVersion']) ?? state.modelVersion;
    state.promptFeedback =
        asMap(chunk['promptFeedback']) ?? state.promptFeedback;
    state.usageMetadata = asMap(chunk['usageMetadata']) ?? state.usageMetadata;

    if (!state.emittedResponseMetadata &&
        (state.responseId != null || state.modelVersion != null)) {
      state.emittedResponseMetadata = true;
      yield ResponseMetadataEvent(
        responseId: state.responseId,
        modelId: state.modelVersion,
      );
    }

    final candidates = asList(chunk['candidates']);
    final candidate = candidates.isEmpty ? null : asMap(candidates.first);
    if (candidate == null) {
      return;
    }

    state.groundingMetadata =
        asMap(candidate['groundingMetadata']) ?? state.groundingMetadata;
    state.urlContextMetadata =
        asMap(candidate['urlContextMetadata']) ?? state.urlContextMetadata;
    final safetyRatings = asList(candidate['safetyRatings']);
    if (safetyRatings.isNotEmpty) {
      state.safetyRatings = safetyRatings;
    }
    state.rawFinishReason =
        asString(candidate['finishReason']) ?? state.rawFinishReason;
    state.finishMessage =
        asString(candidate['finishMessage']) ?? state.finishMessage;

    for (final event in emitGoogleGroundingSourceEvents(
      asMap(candidate['groundingMetadata']),
      emittedSourceKeys: state.emittedSourceKeys,
    )) {
      yield event;
    }

    final content = asMap(candidate['content']);
    final parts = asList(content?['parts']);
    for (final rawPart in parts) {
      final part = asMap(rawPart);
      if (part == null) {
        continue;
      }

      final metadata = googleThoughtSignatureMetadata(
        asString(part['thoughtSignature']),
        isThought: part['thought'] == true,
      );

      if (part case {'executableCode': final Object? executableCode}) {
        yield* _closeOpenBlocks(state);

        final projectedToolCall = projectGoogleCodeExecutionToolCall(
          tracker: state.codeExecutionTracker,
          executableCode: executableCode,
          providerMetadata: metadata,
        );

        yield ToolInputStartEvent(
          toolCallId: projectedToolCall.toolCallId,
          toolName: projectedToolCall.toolName,
          providerExecuted: projectedToolCall.providerExecuted,
          isDynamic: projectedToolCall.isDynamic,
          providerMetadata: projectedToolCall.providerMetadata,
        );
        yield ToolInputDeltaEvent(
          toolCallId: projectedToolCall.toolCallId,
          delta: projectedToolCall.encodedInput,
          providerMetadata: projectedToolCall.providerMetadata,
        );
        yield ToolInputEndEvent(
          toolCallId: projectedToolCall.toolCallId,
          providerMetadata: projectedToolCall.providerMetadata,
        );
        yield ToolCallEvent(
          toolCall: ToolCallContent(
            toolCallId: projectedToolCall.toolCallId,
            toolName: projectedToolCall.toolName,
            input: projectedToolCall.input,
            providerExecuted: projectedToolCall.providerExecuted,
            isDynamic: projectedToolCall.isDynamic,
          ),
          providerMetadata: projectedToolCall.providerMetadata,
        );
        continue;
      }

      if (part case {'codeExecutionResult': final Object? executionResult}) {
        yield* _closeOpenBlocks(state);

        final projectedToolResult = projectGoogleCodeExecutionToolResult(
          tracker: state.codeExecutionTracker,
          executionResult: executionResult,
          providerMetadata: metadata,
        );
        yield ToolResultEvent(
          toolResult: ToolResultContent(
            toolCallId: projectedToolResult.toolCallId,
            toolName: projectedToolResult.toolName,
            toolOutput: projectedToolResult.toolOutput,
            isDynamic: projectedToolResult.isDynamic,
          ),
          providerMetadata: projectedToolResult.providerMetadata,
        );
        continue;
      }

      if (part case {'functionCall': final Object? functionCallValue}) {
        yield* _closeOpenBlocks(state);

        final functionCall = asMap(functionCallValue);
        final functionCallId = asString(functionCall?['id']);
        final projectedToolCall = projectGoogleFunctionToolCall(
          functionCall: functionCall,
          fallbackToolCallId: 'tool-${state.toolCounter}',
          providerMetadata: metadata,
        );
        if (projectedToolCall == null) {
          continue;
        }

        state.hasClientToolCalls = true;
        if (functionCallId == null) {
          state.toolCounter += 1;
        }

        yield ToolInputStartEvent(
          toolCallId: projectedToolCall.toolCallId,
          toolName: projectedToolCall.toolName,
          providerMetadata: projectedToolCall.providerMetadata,
        );
        yield ToolInputDeltaEvent(
          toolCallId: projectedToolCall.toolCallId,
          delta: projectedToolCall.encodedInput,
          providerMetadata: projectedToolCall.providerMetadata,
        );
        yield ToolInputEndEvent(
          toolCallId: projectedToolCall.toolCallId,
          providerMetadata: projectedToolCall.providerMetadata,
        );
        yield ToolCallEvent(
          toolCall: ToolCallContent(
            toolCallId: projectedToolCall.toolCallId,
            toolName: projectedToolCall.toolName,
            input: projectedToolCall.input,
          ),
          providerMetadata: projectedToolCall.providerMetadata,
        );
        continue;
      }

      if (part case {'toolCall': final Object? toolCallValue}) {
        yield* _closeOpenBlocks(state);

        final toolCall = asMap(toolCallValue);
        if (toolCall == null) {
          continue;
        }

        final replay = GoogleToolCallReplay.fromToolCall(
          toolCall,
          providerMetadata: metadata,
        );
        yield replay.toCustomEvent();
        continue;
      }

      if (part case {'toolResponse': final Object? toolResponseValue}) {
        yield* _closeOpenBlocks(state);

        final toolResponse = asMap(toolResponseValue);
        if (toolResponse == null) {
          continue;
        }

        final replay = GoogleToolResponseReplay.fromToolResponse(
          toolResponse,
          providerMetadata: metadata,
        );
        yield replay.toCustomEvent();
        continue;
      }

      if (part case {'text': final Object? textValue}) {
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
          continue;
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
        continue;
      }

      if (part case {'inlineData': final Object? inlineDataValue}) {
        yield* _closeOpenBlocks(state);

        final inlineData = asMap(inlineDataValue);
        final mediaType = asString(inlineData?['mimeType']);
        final data = asString(inlineData?['data']);
        if (mediaType != null && data != null) {
          final file = GeneratedFile(
            mediaType: mediaType,
            data: FileBytesData(
              decodeBase64(data) ??
                  (throw FormatException(
                    'Expected Google inlineData.data to be base64.',
                  )),
            ),
          );

          if (part['thought'] == true) {
            yield ReasoningFileEvent(
              file,
              providerMetadata: metadata,
            );
          } else {
            yield FileEvent(
              file,
              providerMetadata: metadata,
            );
          }
        }
      }
    }

    if (asString(candidate['finishReason']) != null) {
      yield* _emitFinish(state);
    }
  }

  Iterable<LanguageModelStreamEvent> finish(
    GoogleGenerateContentStreamState state,
  ) sync* {
    if (state.finished) {
      return;
    }

    if (!state.emittedResponseMetadata &&
        (state.responseId != null || state.modelVersion != null)) {
      state.emittedResponseMetadata = true;
      yield ResponseMetadataEvent(
        responseId: state.responseId,
        modelId: state.modelVersion,
      );
    }

    if (state.responseId != null ||
        state.modelVersion != null ||
        state.usageMetadata != null) {
      yield* _emitFinish(state);
    }
  }

  Iterable<LanguageModelStreamEvent> _emitFinish(
    GoogleGenerateContentStreamState state,
  ) sync* {
    if (state.finished) {
      return;
    }

    yield* _closeOpenBlocks(state);
    state.finished = true;
    yield FinishEvent(
      finishReason: mapGoogleFinishReason(
        state.rawFinishReason,
        hasClientToolCalls: state.hasClientToolCalls,
      ),
      rawFinishReason: state.rawFinishReason,
      usage: decodeGoogleUsage(state.usageMetadata),
      providerMetadata: buildGoogleGenerationMetadata(
        promptFeedback: state.promptFeedback,
        groundingMetadata: state.groundingMetadata,
        urlContextMetadata: state.urlContextMetadata,
        safetyRatings: state.safetyRatings,
        usageMetadata: state.usageMetadata,
        finishMessage: state.finishMessage,
      ),
    );
  }

  Iterable<LanguageModelStreamEvent> _closeOpenBlocks(
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
}
