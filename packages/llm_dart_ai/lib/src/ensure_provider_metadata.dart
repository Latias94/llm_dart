import 'dart:async';
import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';

/// Deduplicates provider metadata snapshot parts ([LLMProviderMetadataPart]).
///
/// Providers may emit multiple providerMetadata snapshots during streaming.
/// These parts are debug-oriented and can become noisy. This helper:
/// - Collapses consecutive [LLMProviderMetadataPart] into a single merged map.
/// - Drops exact duplicates (stable JSON) across the stream.
///
/// Note: providerMetadata snapshots are kept best-effort; they are not part of
/// the AI SDK v3 canonical stream parts.
Stream<LLMStreamPart> ensureProviderMetadataPart(
  Stream<LLMStreamPart> upstream,
) async* {
  String? lastEncoded;
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

      if (part is! LLMProviderMetadataPart) {
        yield part;
        continue;
      }

      var merged = Map<String, dynamic>.from(part.providerMetadata);

      // Merge consecutive provider metadata parts.
      while (await iterator.moveNext()) {
        final next = iterator.current;
        if (next is! LLMProviderMetadataPart) {
          buffered = next;
          break;
        }
        merged = _mergeProviderMetadata(merged, next.providerMetadata);
      }

      final encoded = _tryStableJsonEncode(merged);
      if (encoded != null && encoded == lastEncoded) {
        continue;
      }
      lastEncoded = encoded;
      yield LLMProviderMetadataPart(merged);
    }
  } finally {
    await iterator.cancel();
  }
}

Map<String, dynamic> _mergeProviderMetadata(
  Map<String, dynamic> a,
  Map<String, dynamic> b,
) {
  if (a.isEmpty) return Map<String, dynamic>.from(b);
  if (b.isEmpty) return Map<String, dynamic>.from(a);
  return _deepMergeJsonMaps(a, b);
}

Map<String, dynamic> _deepMergeJsonMaps(
  Map<String, dynamic> a,
  Map<String, dynamic> b,
) {
  final out = Map<String, dynamic>.from(a);
  for (final entry in b.entries) {
    final key = entry.key;
    final bv = entry.value;
    final av = out[key];
    if (av is Map && bv is Map) {
      out[key] = _deepMergeJsonMaps(
        av.cast<String, dynamic>(),
        bv.cast<String, dynamic>(),
      );
    } else {
      out[key] = bv;
    }
  }
  return out;
}

String? _tryStableJsonEncode(Object? value) {
  try {
    return jsonEncode(_normalizeJson(value));
  } catch (_) {
    return null;
  }
}

Object? _normalizeJson(Object? value) {
  if (value == null) return null;
  if (value is String || value is num || value is bool) return value;
  if (value is List) {
    return value.map(_normalizeJson).toList(growable: false);
  }
  if (value is Map) {
    final entries = <MapEntry<String, Object?>>[];
    for (final entry in value.entries) {
      entries.add(MapEntry(entry.key.toString(), _normalizeJson(entry.value)));
    }
    entries.sort((a, b) => a.key.compareTo(b.key));
    return {for (final e in entries) e.key: e.value};
  }
  return value.toString();
}
