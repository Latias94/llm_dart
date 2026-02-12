import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';

/// Ensures open text/reasoning blocks are closed before emitting a finish part.
///
/// Some provider adapters may forget to emit `text-end` / `reasoning-end`
/// boundaries. AI SDK v3 consumers expect well-formed block lifecycles.
///
/// Behavior:
/// - Tracks text/reasoning deltas per block id.
/// - If a new `*-start` is seen while another block is open, the previous block
///   is closed best-effort before starting the new one (non-overlapping blocks).
/// - When a [LLMFinishPart] is encountered, any open blocks are closed (in a
///   deterministic order) before emitting the finish part.
Stream<LLMStreamPart> ensureBlockEndsPart(
  Stream<LLMStreamPart> upstream,
) async* {
  final textBuffers = <String, StringBuffer>{};
  final reasoningBuffers = <String, StringBuffer>{};

  String? currentTextId;
  String? currentReasoningId;

  void appendText(String id, String delta) {
    (textBuffers[id] ??= StringBuffer()).write(delta);
  }

  void appendReasoning(String id, String delta) {
    (reasoningBuffers[id] ??= StringBuffer()).write(delta);
  }

  LLMTextEndPart? closeTextIfOpen(String? id) {
    final effectiveId = id;
    if (effectiveId == null || effectiveId.trim().isEmpty) return null;
    final buffer = textBuffers[effectiveId]?.toString() ?? '';
    currentTextId = null;
    textBuffers.remove(effectiveId);
    return LLMTextEndPart(buffer, blockId: effectiveId);
  }

  LLMReasoningEndPart? closeReasoningIfOpen(String? id) {
    final effectiveId = id;
    if (effectiveId == null || effectiveId.trim().isEmpty) return null;
    final buffer = reasoningBuffers[effectiveId]?.toString() ?? '';
    currentReasoningId = null;
    reasoningBuffers.remove(effectiveId);
    return LLMReasoningEndPart(buffer, blockId: effectiveId);
  }

  final iterator = StreamIterator(upstream);
  try {
    while (await iterator.moveNext()) {
      final part = iterator.current;

      switch (part) {
        case LLMTextStartPart(:final blockId, :final providerMetadata):
          final id = blockId;
          if (currentTextId != null &&
              id != null &&
              id.isNotEmpty &&
              currentTextId != id) {
            final end = closeTextIfOpen(currentTextId);
            if (end != null) yield end;
          }
          if (id != null && id.trim().isNotEmpty) {
            currentTextId = id;
            textBuffers.putIfAbsent(id, StringBuffer.new);
          }
          yield LLMTextStartPart(
              blockId: id, providerMetadata: providerMetadata);

        case LLMTextDeltaPart(
            :final delta,
            :final blockId,
            :final providerMetadata,
          ):
          final id = blockId;
          if (id != null && id.trim().isNotEmpty) {
            currentTextId = id;
            appendText(id, delta);
          }
          yield LLMTextDeltaPart(delta,
              blockId: id, providerMetadata: providerMetadata);

        case LLMTextEndPart(
            :final text,
            :final blockId,
            :final providerMetadata,
          ):
          final id = blockId;
          if (id != null && id.trim().isNotEmpty) {
            textBuffers[id] = StringBuffer(text);
            if (currentTextId == id) currentTextId = null;
            textBuffers.remove(id);
          }
          yield LLMTextEndPart(text,
              blockId: id, providerMetadata: providerMetadata);

        case LLMReasoningStartPart(:final blockId, :final providerMetadata):
          final id = blockId;
          if (currentReasoningId != null &&
              id != null &&
              id.isNotEmpty &&
              currentReasoningId != id) {
            final end = closeReasoningIfOpen(currentReasoningId);
            if (end != null) yield end;
          }
          if (id != null && id.trim().isNotEmpty) {
            currentReasoningId = id;
            reasoningBuffers.putIfAbsent(id, StringBuffer.new);
          }
          yield LLMReasoningStartPart(
            blockId: id,
            providerMetadata: providerMetadata,
          );

        case LLMReasoningDeltaPart(
            :final delta,
            :final blockId,
            :final providerMetadata,
          ):
          final id = blockId;
          if (id != null && id.trim().isNotEmpty) {
            currentReasoningId = id;
            appendReasoning(id, delta);
          }
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
          final id = blockId;
          if (id != null && id.trim().isNotEmpty) {
            reasoningBuffers[id] = StringBuffer(thinking);
            if (currentReasoningId == id) currentReasoningId = null;
            reasoningBuffers.remove(id);
          }
          yield LLMReasoningEndPart(
            thinking,
            blockId: id,
            providerMetadata: providerMetadata,
          );

        case LLMFinishPart():
          final reasoningEnd = closeReasoningIfOpen(currentReasoningId);
          if (reasoningEnd != null) yield reasoningEnd;
          final textEnd = closeTextIfOpen(currentTextId);
          if (textEnd != null) yield textEnd;
          yield part;

        default:
          yield part;
      }
    }
  } finally {
    await iterator.cancel();
  }
}
