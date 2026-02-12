import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';

/// Ensures response-metadata parts are not spammy and remain deterministic.
///
/// Strategy:
/// - If multiple [LLMResponseMetadataPart] are emitted consecutively, collapse
///   them into a single merged part.
/// - If additional response-metadata parts appear later in the stream, they are
///   dropped (best-effort dedupe).
/// - When step boundaries ([LLMStepStartPart]) are present, response metadata is
///   allowed once per step (AI SDK-style tool loop semantics).
///
/// This keeps us close to the AI SDK v3 intent that response metadata is sent
/// once it becomes available.
Stream<LLMStreamPart> ensureResponseMetadataPart(
  Stream<LLMStreamPart> upstream,
) async* {
  var emitted = false;
  LLMStreamPart? buffered;

  final iterator = StreamIterator(upstream);
  try {
    while (true) {
      if (buffered == null) {
        if (!await iterator.moveNext()) break;
        buffered = iterator.current;
      }

      final part = buffered;
      buffered = null;

      if (part is LLMStepStartPart) {
        // Tool loop step boundary: allow response metadata again for the next step.
        emitted = false;
        yield part;
        continue;
      }

      if (part is! LLMResponseMetadataPart) {
        yield part;
        continue;
      }

      if (emitted) {
        // Drop subsequent response metadata parts (dedupe).
        continue;
      }

      var merged = part;

      // Merge consecutive response metadata parts.
      while (await iterator.moveNext()) {
        final next = iterator.current;
        if (next is! LLMResponseMetadataPart) {
          buffered = next;
          break;
        }
        merged = _mergeResponseMetadata(merged, next);
      }

      emitted = true;
      yield merged;
    }
  } finally {
    await iterator.cancel();
  }
}

LLMResponseMetadataPart _mergeResponseMetadata(
  LLMResponseMetadataPart a,
  LLMResponseMetadataPart b,
) {
  Map<String, String>? mergeHeaders(
      Map<String, String>? x, Map<String, String>? y) {
    if (x == null || x.isEmpty) {
      return y == null ? null : Map<String, String>.from(y);
    }
    if (y == null || y.isEmpty) {
      return Map<String, String>.from(x);
    }
    return {
      ...x,
      ...y,
    };
  }

  Map<String, dynamic>? mergeMap(
      Map<String, dynamic>? x, Map<String, dynamic>? y) {
    if (x == null || x.isEmpty) {
      return y == null ? null : Map<String, dynamic>.from(y);
    }
    if (y == null || y.isEmpty) {
      return Map<String, dynamic>.from(x);
    }
    return {
      ...x,
      ...y,
    };
  }

  return LLMResponseMetadataPart(
    id: a.id ?? b.id,
    timestamp: a.timestamp ?? b.timestamp,
    model: a.model ?? b.model,
    headers: mergeHeaders(a.headers, b.headers),
    body: a.body ?? b.body,
    status: a.status ?? b.status,
    systemFingerprint: a.systemFingerprint ?? b.systemFingerprint,
    providerMetadata: mergeMap(a.providerMetadata, b.providerMetadata),
    raw: mergeMap(a.raw, b.raw),
  );
}
