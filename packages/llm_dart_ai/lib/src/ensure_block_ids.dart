import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';

/// Ensure text/reasoning stream parts carry stable non-empty block ids.
///
/// This is a normalization layer to make parts-first streaming deterministic and
/// AI SDK v3-friendly.
///
/// - If a provider already emits `blockId`, it is preserved.
/// - If a provider omits block ids, ids are injected deterministically:
///   `text_1`, `text_2`, ... and `reasoning_1`, `reasoning_2`, ...
/// - If a delta/end part is seen without a corresponding start, a new id is
///   injected best-effort (the stream is considered malformed but recoverable).
Stream<LLMStreamPart> ensureBlockIdsPart(
    Stream<LLMStreamPart> upstream) async* {
  var textCounter = 1;
  var reasoningCounter = 1;

  String? currentTextId;
  String? currentReasoningId;

  String newTextId() => 'text_${textCounter++}';
  String newReasoningId() => 'reasoning_${reasoningCounter++}';

  final iterator = StreamIterator(upstream);
  try {
    while (await iterator.moveNext()) {
      final part = iterator.current;

      switch (part) {
        case LLMTextStartPart(:final blockId, :final providerMetadata):
          final id = (blockId != null && blockId.trim().isNotEmpty)
              ? blockId
              : newTextId();
          currentTextId = id;
          yield LLMTextStartPart(
              blockId: id, providerMetadata: providerMetadata);

        case LLMTextDeltaPart(
            :final delta,
            :final blockId,
            :final providerMetadata,
          ):
          final id = (blockId != null && blockId.trim().isNotEmpty)
              ? blockId
              : (currentTextId ??= newTextId());
          yield LLMTextDeltaPart(
            delta,
            blockId: id,
            providerMetadata: providerMetadata,
          );

        case LLMTextEndPart(
            :final text,
            :final blockId,
            :final providerMetadata,
          ):
          final id = (blockId != null && blockId.trim().isNotEmpty)
              ? blockId
              : (currentTextId ??= newTextId());
          currentTextId = null;
          yield LLMTextEndPart(
            text,
            blockId: id,
            providerMetadata: providerMetadata,
          );

        case LLMReasoningStartPart(:final blockId, :final providerMetadata):
          final id = (blockId != null && blockId.trim().isNotEmpty)
              ? blockId
              : newReasoningId();
          currentReasoningId = id;
          yield LLMReasoningStartPart(
            blockId: id,
            providerMetadata: providerMetadata,
          );

        case LLMReasoningDeltaPart(
            :final delta,
            :final blockId,
            :final providerMetadata,
          ):
          final id = (blockId != null && blockId.trim().isNotEmpty)
              ? blockId
              : (currentReasoningId ??= newReasoningId());
          yield LLMReasoningDeltaPart(
            delta,
            blockId: id,
            providerMetadata: providerMetadata,
          );

        case LLMReasoningEndPart(
            :final thinking,
            :final blockId,
            :final providerMetadata,
          ):
          final id = (blockId != null && blockId.trim().isNotEmpty)
              ? blockId
              : (currentReasoningId ??= newReasoningId());
          currentReasoningId = null;
          yield LLMReasoningEndPart(
            thinking,
            blockId: id,
            providerMetadata: providerMetadata,
          );

        default:
          yield part;
      }
    }
  } finally {
    await iterator.cancel();
  }
}
