import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';

import 'tool_types.dart';

/// Built-in [ToolCallRepair] strategies.
///
/// These are intentionally conservative and are **not enabled by default**.
/// The goal is to provide an opt-in escape hatch for "fearless refactors"
/// where upstream models/providers may emit malformed JSON tool arguments.
class ToolCallRepairStrategies {
  /// Attempt to repair common JSON formatting issues and normalize into a JSON object.
  ///
  /// Behavior:
  /// - Only attempts repairs for `invalid_json` and `arguments_not_object`.
  /// - Never changes tool name or tool id.
  /// - Returns a normalized JSON string (via `jsonEncode`) if a JSON object can be recovered.
  /// - Returns `null` when it cannot safely recover an object.
  static ToolCallRepair fixCommonJsonObject() {
    return (
      V3ToolCall toolCall, {
      required String reason,
      String? errorMessage,
      List<String>? validationErrors,
    }) {
      if (reason != 'invalid_json' && reason != 'arguments_not_object') {
        return null;
      }

      final raw = toolCall.input;
      final repaired = _repairToJsonObjectString(raw);
      return repaired;
    };
  }
}

String? _repairToJsonObjectString(String raw) {
  var s = raw.trim();
  if (s.isEmpty) s = '{}';

  s = _stripMarkdownCodeFence(s);
  s = _stripBom(s).trim();

  // Cheap fixes for common model outputs.
  s = _replaceSmartQuotes(s);
  s = _removeTrailingCommas(s);

  // If it already parses as a JSON object, normalize and return.
  final decoded0 = _tryJsonDecode(s);
  if (decoded0 is Map) {
    return jsonEncode(_stringifyJsonMap(decoded0));
  }

  // Try a minimal "missing closing brace" fix for object-looking payloads.
  if (s.startsWith('{') && !s.endsWith('}')) {
    final candidate = '${s.trimRight()}}';
    final decoded1 = _tryJsonDecode(candidate);
    if (decoded1 is Map) {
      return jsonEncode(_stringifyJsonMap(decoded1));
    }
  }

  // Nothing we can safely recover.
  return null;
}

Object? _tryJsonDecode(String s) {
  try {
    return jsonDecode(s);
  } catch (_) {
    return null;
  }
}

String _stripMarkdownCodeFence(String s) {
  // Handle:
  // ```json
  // {...}
  // ```
  if (!s.startsWith('```')) return s;

  final lines = const LineSplitter().convert(s);
  if (lines.length < 2) return s;

  final first = lines.first.trimLeft();
  if (!first.startsWith('```')) return s;

  final last = lines.last.trimRight();
  if (!last.startsWith('```')) return s;

  final body = lines.sublist(1, lines.length - 1).join('\n').trim();
  return body.isEmpty ? s : body;
}

String _stripBom(String s) {
  if (s.isEmpty) return s;
  // UTF-8 BOM: U+FEFF
  if (s.codeUnitAt(0) == 0xFEFF) return s.substring(1);
  return s;
}

String _replaceSmartQuotes(String s) {
  return s
      .replaceAll('“', '"')
      .replaceAll('”', '"')
      .replaceAll('‘', "'")
      .replaceAll('’', "'");
}

String _removeTrailingCommas(String s) {
  // Fix `{ "a": 1, }` and `[1,2,]`.
  return s.replaceAll(RegExp(r',\s*}'), '}').replaceAll(RegExp(r',\s*]'), ']');
}

Map<String, dynamic> _stringifyJsonMap(Map map) {
  final out = <String, dynamic>{};
  for (final entry in map.entries) {
    out[entry.key.toString()] = entry.value;
  }
  return out;
}
