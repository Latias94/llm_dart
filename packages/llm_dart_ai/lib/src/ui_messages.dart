import 'package:llm_dart_core/llm_dart_core.dart';

/// UI message model for AI SDK-style streaming integrations.
///
/// This mirrors the high-level semantics of Vercel AI SDK `UIMessage`, but is
/// intentionally JSON-friendly to support Flutter/web/server runtimes.
class UIMessage {
  final String id;
  final String role;
  final Object? metadata;
  final List<Map<String, Object?>> parts;

  const UIMessage({
    required this.id,
    required this.role,
    this.metadata,
    this.parts = const <Map<String, Object?>>[],
  });

  UIMessage copyWith({
    String? id,
    String? role,
    Object? metadata,
    List<Map<String, Object?>>? parts,
  }) {
    return UIMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      metadata: metadata ?? this.metadata,
      parts: parts ?? this.parts,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'role': role,
        if (metadata != null) 'metadata': metadata,
        'parts': parts,
      };

  @override
  String toString() =>
      'UIMessage(id: $id, role: $role, parts: ${parts.length})';
}

Object? deepCloneJsonLike(Object? value) {
  if (value == null) return null;
  if (value is num || value is bool || value is String) return value;

  if (value is List) {
    return value.map(deepCloneJsonLike).toList(growable: false);
  }

  if (value is Map) {
    final out = <String, Object?>{};
    for (final entry in value.entries) {
      final k = entry.key;
      if (k is! String) continue;
      out[k] = deepCloneJsonLike(entry.value);
    }
    return out;
  }

  // Best-effort fallback for non-JSON values.
  return value;
}

UIMessage deepCloneUiMessage(UIMessage message) {
  return UIMessage(
    id: message.id,
    role: message.role,
    metadata: deepCloneJsonLike(message.metadata),
    parts: message.parts
        .map((p) =>
            (deepCloneJsonLike(p) as Map?)?.cast<String, Object?>() ??
            const <String, Object?>{})
        .toList(growable: false),
  );
}

Object? mergeJsonLike(Object? base, Object? patch) {
  if (patch == null) return base;
  if (base == null) return patch;

  if (base is Map && patch is Map) {
    final out = <String, Object?>{};
    for (final entry in base.entries) {
      final k = entry.key;
      if (k is! String) continue;
      out[k] = entry.value as Object?;
    }
    for (final entry in patch.entries) {
      final k = entry.key;
      if (k is! String) continue;
      final existing = out[k];
      out[k] = mergeJsonLike(existing, entry.value);
    }
    return out;
  }

  // Non-map patches override.
  return patch;
}

/// Deterministic-ish, local-only message id generator used as a fallback when
/// a stream does not provide a message id.
///
/// This is not intended for cryptographic use.
String fallbackUiMessageId() {
  return _fallbackUiMessageIdGenerator();
}

final IdGenerator _fallbackUiMessageIdGenerator = createIdGenerator(
  prefix: 'msg',
  separator: '_',
);
