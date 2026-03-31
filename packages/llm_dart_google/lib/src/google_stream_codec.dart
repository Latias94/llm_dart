import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';

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
  String? lastCodeExecutionToolCallId;

  int blockCounter = 0;
  int toolCounter = 0;
  int codeExecutionCounter = 0;
  bool hasClientToolCalls = false;
  bool emittedResponseMetadata = false;
  bool finished = false;

  final Set<String> emittedSourceKeys = {};
}

final class GoogleGenerateContentStreamCodec {
  const GoogleGenerateContentStreamCodec();

  Iterable<TextStreamEvent> decodeChunk(
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

    for (final source in extractGroundingSources(
      asMap(candidate['groundingMetadata']),
    )) {
      final key = '${source.kind}:${source.sourceId}';
      if (state.emittedSourceKeys.add(key)) {
        yield SourceEvent(source);
      }
    }

    final content = asMap(candidate['content']);
    final parts = asList(content?['parts']);
    for (final rawPart in parts) {
      final part = asMap(rawPart);
      if (part == null) {
        continue;
      }

      final metadata = _thoughtSignatureMetadata(
        asString(part['thoughtSignature']),
        isThought: part['thought'] == true,
      );

      if (part case {'executableCode': final Object? executableCode}) {
        yield* _closeOpenBlocks(state);

        final toolCallId = 'code-execution-${state.codeExecutionCounter++}';
        state.lastCodeExecutionToolCallId = toolCallId;
        final input =
            normalizeJsonValue(executableCode) ?? const <String, Object?>{};
        final encodedInput = jsonEncode(input);

        yield ToolInputStartEvent(
          toolCallId: toolCallId,
          toolName: 'code_execution',
          providerExecuted: true,
          isDynamic: true,
          providerMetadata: metadata,
        );
        yield ToolInputDeltaEvent(
          toolCallId: toolCallId,
          delta: encodedInput,
          providerMetadata: metadata,
        );
        yield ToolInputEndEvent(
          toolCallId: toolCallId,
          providerMetadata: metadata,
        );
        yield ToolCallEvent(
          toolCall: ToolCallContent(
            toolCallId: toolCallId,
            toolName: 'code_execution',
            input: input,
            providerExecuted: true,
            isDynamic: true,
          ),
          providerMetadata: metadata,
        );
        continue;
      }

      if (part case {'codeExecutionResult': final Object? executionResult}) {
        yield* _closeOpenBlocks(state);

        final toolCallId = state.lastCodeExecutionToolCallId ??
            'code-execution-${state.codeExecutionCounter++}';
        final result = asMap(executionResult);
        yield ToolResultEvent(
          toolResult: ToolResultContent(
            toolCallId: toolCallId,
            toolName: 'code_execution',
            output: normalizeJsonValue(executionResult),
            isError: _isCodeExecutionError(result),
            isDynamic: true,
          ),
          providerMetadata: metadata,
        );
        state.lastCodeExecutionToolCallId = null;
        continue;
      }

      if (part case {'functionCall': final Object? functionCallValue}) {
        yield* _closeOpenBlocks(state);

        final functionCall = asMap(functionCallValue);
        final toolName = asString(functionCall?['name']);
        if (toolName == null) {
          continue;
        }

        state.hasClientToolCalls = true;
        final functionCallId = asString(functionCall?['id']);
        final toolCallId = functionCallId ?? 'tool-${state.toolCounter++}';
        final functionCallMetadata = mergeProviderMetadata(
          metadata,
          _functionCallIdMetadata(functionCallId),
        );
        final input = normalizeJsonValue(functionCall?['args']) ??
            const <String, Object?>{};
        final encodedInput = jsonEncode(input);

        yield ToolInputStartEvent(
          toolCallId: toolCallId,
          toolName: toolName,
          providerMetadata: functionCallMetadata,
        );
        yield ToolInputDeltaEvent(
          toolCallId: toolCallId,
          delta: encodedInput,
          providerMetadata: functionCallMetadata,
        );
        yield ToolInputEndEvent(
          toolCallId: toolCallId,
          providerMetadata: functionCallMetadata,
        );
        yield ToolCallEvent(
          toolCall: ToolCallContent(
            toolCallId: toolCallId,
            toolName: toolName,
            input: input,
          ),
          providerMetadata: functionCallMetadata,
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
            bytes: decodeBase64(data),
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

  Iterable<TextStreamEvent> finish(
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

  Iterable<TextStreamEvent> _emitFinish(
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
      providerMetadata: googleProviderMetadata({
        'promptFeedback': state.promptFeedback,
        'groundingMetadata': state.groundingMetadata,
        'urlContextMetadata': state.urlContextMetadata,
        'safetyRatings': state.safetyRatings,
        'usageMetadata': state.usageMetadata,
        'finishMessage': state.finishMessage,
      }),
    );
  }

  Iterable<TextStreamEvent> _closeOpenBlocks(
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

  ProviderMetadata? _thoughtSignatureMetadata(
    String? thoughtSignature, {
    required bool isThought,
  }) {
    if (thoughtSignature == null && !isThought) {
      return null;
    }

    return googleProviderMetadata({
      'thoughtSignature': thoughtSignature,
      if (isThought) 'thought': true,
    });
  }

  ProviderMetadata? _functionCallIdMetadata(String? functionCallId) {
    if (functionCallId == null || functionCallId.isEmpty) {
      return null;
    }

    return googleProviderMetadata({
      'functionCallId': functionCallId,
    });
  }

  bool _isCodeExecutionError(Map<String, Object?>? result) {
    final outcome = asString(result?['outcome'])?.toLowerCase();
    if (outcome == null) {
      return false;
    }

    return outcome.contains('error') || outcome.contains('fail');
  }
}
