import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';

/// Ensures open text/reasoning blocks are closed before emitting a finish part.
///
/// Some provider adapters may forget to emit `text-end` / `reasoning-end`
/// boundaries. AI SDK v3 consumers expect well-formed block lifecycles.
///
/// This also closes open `tool-input-*` blocks (best-effort) to keep
/// tool call input streaming structurally well-formed.
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

  final openToolInputIds = <String>[];
  final openToolInputIdSet = <String>{};

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

  LLMToolInputEndPart? closeToolInputIfOpen(String? id) {
    final effectiveId = id;
    if (effectiveId == null || effectiveId.trim().isEmpty) return null;
    if (!openToolInputIdSet.remove(effectiveId)) return null;
    openToolInputIds.remove(effectiveId);
    return LLMToolInputEndPart(id: effectiveId);
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

        case LLMToolInputStartPart(
            :final id,
            :final toolName,
            :final providerMetadata,
            :final providerExecuted,
            :final isDynamic,
            :final title,
          ):
          if (id.trim().isNotEmpty && openToolInputIdSet.add(id)) {
            openToolInputIds.add(id);
          }
          yield LLMToolInputStartPart(
            id: id,
            toolName: toolName,
            providerMetadata: providerMetadata,
            providerExecuted: providerExecuted,
            isDynamic: isDynamic,
            title: title,
          );

        case LLMToolInputDeltaPart(
            :final id,
            :final delta,
            :final providerMetadata,
          ):
          // We intentionally do not synthesize a missing tool-input-start here
          // because toolName is required. Close-on-finish still applies if a
          // start was seen previously.
          yield LLMToolInputDeltaPart(
            id: id,
            delta: delta,
            providerMetadata: providerMetadata,
          );

        case LLMToolInputEndPart(:final id, :final providerMetadata):
          openToolInputIdSet.remove(id);
          openToolInputIds.remove(id);
          yield LLMToolInputEndPart(
            id: id,
            providerMetadata: providerMetadata,
          );

        case LLMProviderToolCallPart(:final toolCallId):
          final end = closeToolInputIfOpen(toolCallId);
          if (end != null) yield end;
          yield part;

        case LLMProviderToolResultPart(:final toolCallId):
          final end = closeToolInputIfOpen(toolCallId);
          if (end != null) yield end;
          yield part;

        case LLMToolResultPart(:final result):
          final end = closeToolInputIfOpen(result.toolCallId);
          if (end != null) yield end;
          yield part;

        case LLMFinishPart():
          // Close tool-input blocks first (in a stable order).
          while (openToolInputIds.isNotEmpty) {
            final id = openToolInputIds.first;
            final end = closeToolInputIfOpen(id);
            if (end != null) yield end;
          }
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
