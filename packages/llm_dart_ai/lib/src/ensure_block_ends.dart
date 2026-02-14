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
  final toolNameByToolInputId = <String, String>{};
  final pendingToolInputIds = <String>[];
  final pendingToolInputIdSet = <String>{};
  final pendingToolInputDeltasById = <String, List<LLMToolInputDeltaPart>>{};
  final pendingToolInputEnds = <String>{};

  void appendText(String id, String delta) {
    (textBuffers[id] ??= StringBuffer()).write(delta);
  }

  void appendReasoning(String id, String delta) {
    (reasoningBuffers[id] ??= StringBuffer()).write(delta);
  }

  void rememberToolInputIdOrder(String id) {
    if (pendingToolInputIdSet.add(id)) {
      pendingToolInputIds.add(id);
    }
  }

  String toolNameForToolInputId(String id) =>
      toolNameByToolInputId[id] ?? 'unknown';

  String? inferToolNameFromProviderMetadata(Map<String, dynamic>? metadata) {
    if (metadata == null || metadata.isEmpty) return null;
    for (final entry in metadata.entries) {
      final value = entry.value;
      if (value is! Map) continue;
      final map = value.map((k, v) => MapEntry(k.toString(), v));
      final toolName = map['toolName'] ?? map['tool_name'];
      if (toolName is String && toolName.trim().isNotEmpty) {
        return toolName.trim();
      }
    }
    return null;
  }

  String? inferToolNameFromDelta(String delta) {
    String? extract(String key) {
      final pattern = '"$key":"';
      final start = delta.indexOf(pattern);
      if (start == -1) return null;
      final valueStart = start + pattern.length;
      final end = delta.indexOf('"', valueStart);
      if (end == -1) return null;
      final value = delta.substring(valueStart, end).trim();
      return value.isEmpty ? null : value;
    }

    return extract('toolName') ?? extract('tool_name');
  }

  bool hasPendingToolInputFragments(String id) =>
      pendingToolInputDeltasById.containsKey(id) ||
      pendingToolInputEnds.contains(id);

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

  LLMToolInputStartPart? startToolInputIfNeeded({
    required String id,
    Map<String, dynamic>? providerMetadata,
  }) {
    if (id.trim().isEmpty) return null;
    if (openToolInputIdSet.contains(id)) return null;

    openToolInputIdSet.add(id);
    openToolInputIds.add(id);

    return LLMToolInputStartPart(
      id: id,
      toolName: toolNameForToolInputId(id),
      providerMetadata: providerMetadata,
    );
  }

  Map<String, dynamic>? providerMetadataForPendingToolInput(String id) {
    final deltas = pendingToolInputDeltasById[id];
    if (deltas == null || deltas.isEmpty) return null;
    return deltas.first.providerMetadata;
  }

  Iterable<LLMStreamPart> flushPendingToolInputForId(String id) sync* {
    final deltas = pendingToolInputDeltasById.remove(id);
    if (deltas != null) {
      for (final d in deltas) {
        yield d;
      }
    }
    if (pendingToolInputEnds.remove(id)) {
      final end = closeToolInputIfOpen(id);
      if (end != null) yield end;
    }
  }

  Iterable<LLMStreamPart> handleToolInputDelta({
    required String id,
    required String delta,
    Map<String, dynamic>? providerMetadata,
  }) sync* {
    if (openToolInputIdSet.contains(id)) {
      yield LLMToolInputDeltaPart(
        id: id,
        delta: delta,
        providerMetadata: providerMetadata,
      );
      return;
    }

    final inferredFromMeta = inferToolNameFromProviderMetadata(providerMetadata);
    final inferredFromDelta = inferToolNameFromDelta(delta);
    final inferred = inferredFromMeta ?? inferredFromDelta;
    if (inferred != null && inferred.trim().isNotEmpty) {
      toolNameByToolInputId.putIfAbsent(id, () => inferred.trim());
    }

    // Buffer orphan deltas until we see a start (or until finish).
    // This preserves AI SDK v3 ordering invariants: deltas must follow a
    // tool-input-start boundary.
    rememberToolInputIdOrder(id);
    (pendingToolInputDeltasById[id] ??= <LLMToolInputDeltaPart>[]).add(
      LLMToolInputDeltaPart(
        id: id,
        delta: delta,
        providerMetadata: providerMetadata,
      ),
    );
  }

  Iterable<LLMStreamPart> handleToolInputEnd({
    required String id,
    Map<String, dynamic>? providerMetadata,
  }) sync* {
    if (openToolInputIdSet.contains(id)) {
      openToolInputIdSet.remove(id);
      openToolInputIds.remove(id);
      yield LLMToolInputEndPart(
        id: id,
        providerMetadata: providerMetadata,
      );
      return;
    }

    rememberToolInputIdOrder(id);
    pendingToolInputEnds.add(id);
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

        case LLMToolCallStartPart(:final toolCall):
        case LLMToolCallDeltaPart(:final toolCall):
          final callType = toolCall.callType.trim().toLowerCase();
          if (callType != 'function') {
            yield part;
            break;
          }
          final id = toolCall.id.trim();
          if (id.isNotEmpty) {
            final name = toolCall.function.name.trim();
            if (name.isNotEmpty) {
              toolNameByToolInputId[id] = name;
              final synthesizedStart = startToolInputIfNeeded(id: id);
              if (synthesizedStart != null) {
                yield synthesizedStart;
                for (final pending in flushPendingToolInputForId(id)) {
                  yield pending;
                }
              }
            }

            final delta = toolCall.function.arguments;
            if (delta.isNotEmpty) {
              for (final p in handleToolInputDelta(id: id, delta: delta)) {
                yield p;
              }
            }
          }
          yield part;

        case LLMToolCallEndPart(:final toolCallId):
          final id = toolCallId.trim();
          if (id.isNotEmpty) {
            // Ensure any buffered deltas are preceded by a start boundary.
            if (hasPendingToolInputFragments(id) &&
                !openToolInputIdSet.contains(id)) {
              final synthesizedStart = startToolInputIfNeeded(
                id: id,
                providerMetadata: providerMetadataForPendingToolInput(id),
              );
              if (synthesizedStart != null) {
                yield synthesizedStart;
                for (final pending in flushPendingToolInputForId(id)) {
                  yield pending;
                }
              }
            }
            for (final p in handleToolInputEnd(id: id)) {
              yield p;
            }
          }
          yield part;

        case LLMToolInputStartPart(
            :final id,
            :final toolName,
            :final providerMetadata,
            :final providerExecuted,
            :final isDynamic,
            :final title,
          ):
          toolNameByToolInputId[id] = toolName;
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
          for (final pending in flushPendingToolInputForId(id)) {
            yield pending;
          }

        case LLMToolInputDeltaPart(
            :final id,
            :final delta,
            :final providerMetadata,
          ):
          for (final p in handleToolInputDelta(
            id: id,
            delta: delta,
            providerMetadata: providerMetadata,
          )) {
            yield p;
          }

        case LLMToolInputEndPart(:final id, :final providerMetadata):
          for (final p in handleToolInputEnd(
            id: id,
            providerMetadata: providerMetadata,
          )) {
            yield p;
          }

        case LLMProviderToolCallPart(:final toolCallId):
          toolNameByToolInputId[toolCallId] = part.toolName;
          if (hasPendingToolInputFragments(toolCallId)) {
            final synthesizedStart = startToolInputIfNeeded(id: toolCallId);
            if (synthesizedStart != null) {
              yield synthesizedStart;
              for (final pending in flushPendingToolInputForId(toolCallId)) {
                yield pending;
              }
            }
          }
          final end = closeToolInputIfOpen(toolCallId);
          if (end != null) yield end;
          yield part;

        case LLMProviderToolResultPart(:final toolCallId):
          toolNameByToolInputId[toolCallId] = part.toolName;
          if (hasPendingToolInputFragments(toolCallId)) {
            final synthesizedStart = startToolInputIfNeeded(id: toolCallId);
            if (synthesizedStart != null) {
              yield synthesizedStart;
              for (final pending in flushPendingToolInputForId(toolCallId)) {
                yield pending;
              }
            }
          }
          final end = closeToolInputIfOpen(toolCallId);
          if (end != null) yield end;
          yield part;

        case LLMToolResultPart(:final result):
          if (hasPendingToolInputFragments(result.toolCallId)) {
            final synthesizedStart =
                startToolInputIfNeeded(id: result.toolCallId);
            if (synthesizedStart != null) {
              yield synthesizedStart;
              for (final pending
                  in flushPendingToolInputForId(result.toolCallId)) {
                yield pending;
              }
            }
          }
          final end = closeToolInputIfOpen(result.toolCallId);
          if (end != null) yield end;
          yield part;

        case LLMFinishPart():
          // Flush orphan tool-input fragments (delta/end without start) in a
          // stable order, then close any remaining open tool-input blocks.
          for (final id in pendingToolInputIds) {
            final synthesizedStart = startToolInputIfNeeded(
              id: id,
              providerMetadata: providerMetadataForPendingToolInput(id),
            );
            if (synthesizedStart == null) continue;
            yield synthesizedStart;
            for (final pending in flushPendingToolInputForId(id)) {
              yield pending;
            }
            final end = closeToolInputIfOpen(id);
            if (end != null) yield end;
          }
          pendingToolInputIds.clear();
          pendingToolInputIdSet.clear();
          pendingToolInputDeltasById.clear();
          pendingToolInputEnds.clear();

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
