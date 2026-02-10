library;

import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

typedef JsonMap = Map<String, dynamic>;

bool shouldUpdateGoldens() => Platform.environment['UPDATE_GOLDENS'] == '1';

/// Reads a JSONL file where each non-empty line is a JSON object.
List<JsonMap> readJsonlObjects(String path) {
  final lines = File(path)
      .readAsLinesSync()
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList(growable: false);

  final objects = <JsonMap>[];
  for (final line in lines) {
    final decoded = jsonDecode(line);
    if (decoded is! JsonMap) {
      throw FormatException('Expected JSON object per line, got: $decoded');
    }
    objects.add(decoded);
  }
  return objects;
}

/// Stable JSON encoding for golden fixtures:
/// - Sort map keys recursively.
/// - Optionally omit null fields (default: true).
String stableJsonEncode(
  Object? value, {
  bool omitNulls = true,
}) {
  final normalized = _normalizeJsonLike(value, omitNulls: omitNulls);
  return jsonEncode(normalized);
}

Object? _normalizeJsonLike(
  Object? value, {
  required bool omitNulls,
}) {
  if (value == null) return null;

  if (value is DateTime) {
    return value.toIso8601String();
  }

  if (value is Map) {
    final entries = <MapEntry<String, Object?>>[];
    for (final e in value.entries) {
      final key = e.key.toString();
      final normalizedValue = _normalizeJsonLike(e.value, omitNulls: omitNulls);
      if (omitNulls && normalizedValue == null) continue;
      entries.add(MapEntry(key, normalizedValue));
    }

    final sorted = SplayTreeMap<String, Object?>();
    sorted.addEntries(entries);
    return sorted;
  }

  if (value is Iterable) {
    return value
        .map((v) => _normalizeJsonLike(v, omitNulls: omitNulls))
        .toList(growable: false);
  }

  if (value is String) {
    if (_shouldRedactBase64(value)) {
      return {
        r'$redacted': 'base64',
        'len': value.length,
        'hash': _fnv1a64Hex(value),
      };
    }
    return value;
  }

  if (value is num || value is bool) {
    return value;
  }

  // Fall back to a JSON-friendly representation for unexpected types.
  return value.toString();
}

bool _shouldRedactBase64(String value) {
  // Keep existing goldens stable; only redact very large base64-like blobs.
  if (value.length <= 4096) return false;
  return _looksLikeBase64(value);
}

bool _looksLikeBase64(String value) {
  // Base64 strings are typically padded with '=' and contain only A-Z a-z 0-9 + /
  // We accept '=' anywhere for robustness (some providers omit padding).
  for (var i = 0; i < value.length; i++) {
    final c = value.codeUnitAt(i);
    final isAz = c >= 0x41 && c <= 0x5A;
    final isaz = c >= 0x61 && c <= 0x7A;
    final is09 = c >= 0x30 && c <= 0x39;
    if (isAz || isaz || is09) continue;
    if (c == 0x2B /* + */ || c == 0x2F /* / */ || c == 0x3D /* = */) continue;
    return false;
  }
  return true;
}

String _fnv1a64Hex(String value) {
  // FNV-1a 64-bit (deterministic, fast, no extra deps).
  var hash = BigInt.parse('14695981039346656037'); // offset basis
  final prime = BigInt.parse('1099511628211');
  final mask = BigInt.parse('18446744073709551615'); // 2^64-1

  final bytes = utf8.encode(value);
  for (final b in bytes) {
    hash = (hash ^ BigInt.from(b)) * prime;
    hash &= mask;
  }

  final hex = hash.toRadixString(16).padLeft(16, '0');
  return 'fnv1a64:$hex';
}

List<String> toStableJsonlLines(
  Iterable<Object?> objects, {
  bool omitNulls = true,
}) =>
    objects
        .map((o) => stableJsonEncode(o, omitNulls: omitNulls))
        .toList(growable: false);

void writeStableJsonl(
  String path,
  Iterable<Object?> objects, {
  bool omitNulls = true,
}) {
  final file = File(path);
  file.parent.createSync(recursive: true);

  final lines = toStableJsonlLines(objects, omitNulls: omitNulls);
  file.writeAsStringSync('${lines.join('\n')}\n');
}

/// Compares [actualObjects] to a `.jsonl` golden file at [goldenPath].
///
/// To update goldens, set `UPDATE_GOLDENS=1`.
void expectStableJsonlGolden({
  required String goldenPath,
  required Iterable<Object?> actualObjects,
  bool omitNulls = true,
}) {
  final update = shouldUpdateGoldens();
  final file = File(goldenPath);

  final actualLines = toStableJsonlLines(actualObjects, omitNulls: omitNulls);

  if (update || !file.existsSync()) {
    writeStableJsonl(goldenPath, actualObjects, omitNulls: omitNulls);
    if (!update) {
      fail(
        'Golden file did not exist and was created: $goldenPath. '
        'Re-run tests to validate.',
      );
    }
    return;
  }

  final expectedLines = file
      .readAsLinesSync()
      .map((l) => l.trimRight())
      .where((l) => l.isNotEmpty)
      .toList(growable: false);

  if (expectedLines.length != actualLines.length) {
    fail(
      'Golden line count mismatch for $goldenPath: '
      'expected ${expectedLines.length}, got ${actualLines.length}. '
      'Set UPDATE_GOLDENS=1 to update.',
    );
  }

  for (var i = 0; i < expectedLines.length; i++) {
    final expected = expectedLines[i];
    final actual = actualLines[i];
    if (expected == actual) continue;
    fail(
      'Golden mismatch at $goldenPath line ${i + 1}.\n'
      'Expected: $expected\n'
      'Actual:   $actual\n'
      'Set UPDATE_GOLDENS=1 to update.',
    );
  }

  expect(actualLines.length, expectedLines.length);
}
