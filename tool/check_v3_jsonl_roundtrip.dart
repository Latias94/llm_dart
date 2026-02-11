import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:llm_dart_core/llm_dart_core.dart';

typedef JsonMap = Map<String, dynamic>;

void main(List<String> args) {
  final check = args.contains('--check') || !args.contains('--write');
  if (!check) {
    stderr.writeln('This tool is check-only. Pass --check.');
    exitCode = 2;
    return;
  }

  final dir = Directory('test/fixtures/v3_parts');
  if (!dir.existsSync()) {
    stderr.writeln('Missing directory: ${dir.path}');
    exitCode = 2;
    return;
  }

  final jsonlFiles = dir
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((f) => f.path.endsWith('.jsonl'))
      .map((f) => f.path)
      .toList(growable: false)
    ..sort();

  if (jsonlFiles.isEmpty) {
    stderr.writeln('No .jsonl goldens found under ${dir.path}');
    exitCode = 2;
    return;
  }

  var failures = 0;

  for (final path in jsonlFiles) {
    final expectedObjects = _readJsonlObjects(path);
    List<LLMStreamPart> parts;
    try {
      parts = decodeV3StreamParts(expectedObjects);
    } catch (e) {
      failures++;
      stderr.writeln('[roundtrip] decode failed: $path');
      stderr.writeln('  $e');
      continue;
    }

    final encoded = encodeV3StreamParts(parts);

    final expectedLines = expectedObjects
        .map((o) => _stableJsonEncode(o, omitNulls: true))
        .toList(growable: false);
    final actualLines = encoded
        .map((o) => _stableJsonEncode(o, omitNulls: true))
        .toList(growable: false);

    if (expectedLines.length != actualLines.length) {
      failures++;
      stderr.writeln(
        '[roundtrip] line count mismatch: $path '
        '(expected ${expectedLines.length}, got ${actualLines.length})',
      );
      continue;
    }

    var mismatch = -1;
    for (var i = 0; i < expectedLines.length; i++) {
      if (expectedLines[i] != actualLines[i]) {
        mismatch = i;
        break;
      }
    }

    if (mismatch != -1) {
      failures++;
      stderr.writeln('[roundtrip] mismatch: $path line ${mismatch + 1}');
      stderr.writeln('  expected: ${expectedLines[mismatch]}');
      stderr.writeln('  actual:   ${actualLines[mismatch]}');
      continue;
    }
  }

  if (failures > 0) {
    stderr.writeln('v3 jsonl round-trip check failed: $failures file(s).');
    exitCode = 1;
    return;
  }

  stdout.writeln('v3 jsonl round-trip OK (${jsonlFiles.length} files).');
}

List<JsonMap> _readJsonlObjects(String path) {
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

String _stableJsonEncode(
  Object? value, {
  required bool omitNulls,
}) {
  final normalized = _normalizeJsonLike(value, omitNulls: omitNulls);
  return jsonEncode(normalized);
}

Object? _normalizeJsonLike(
  Object? value, {
  required bool omitNulls,
}) {
  if (value == null) return null;

  if (value is DateTime) return value.toIso8601String();

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

  if (value is num || value is bool) return value;

  return value.toString();
}

bool _shouldRedactBase64(String value) {
  if (value.length <= 4096) return false;
  return _looksLikeBase64(value);
}

bool _looksLikeBase64(String value) {
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
