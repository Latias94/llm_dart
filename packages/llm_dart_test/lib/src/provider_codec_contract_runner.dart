import 'dart:convert';
import 'dart:io';

import 'package:llm_dart_provider/llm_dart_provider.dart';

/// Shared golden-fixture runner for provider codec contract tests.
///
/// Provider packages still own their concrete request and stream codecs. This
/// helper owns only the repeated test policy: fixture lookup, JSON comparison,
/// and provider stream-event fixture projection.
final class ProviderCodecContractRunner {
  final List<String> fixtureRoots;
  final String? label;

  ProviderCodecContractRunner({
    required Iterable<String> fixtureRoots,
    this.label,
  }) : fixtureRoots = List.unmodifiable(fixtureRoots);

  ProviderCodecContractRunner.forWorkspacePackage(
    String packageName, {
    this.label,
  }) : fixtureRoots = List.unmodifiable([
          'packages/$packageName/test/fixtures',
          'test/fixtures',
        ]);

  Object? readJsonFixture(String relativePath) {
    final file = resolveJsonFixture(relativePath);
    return jsonDecode(file.readAsStringSync()) as Object?;
  }

  File resolveJsonFixture(String relativePath) {
    final searchedPaths = <String>[];

    for (final root in fixtureRoots) {
      final file = File('$root/$relativePath');
      searchedPaths.add(file.path);
      if (file.existsSync()) {
        return file;
      }
    }

    throw ProviderCodecFixtureNotFound(
      relativePath: relativePath,
      searchedPaths: searchedPaths,
      label: label,
    );
  }

  void expectJsonFixture(String relativePath, Object? actual) {
    final expected = readJsonFixture(relativePath);
    if (_jsonEquals(actual, expected)) {
      return;
    }

    throw ProviderCodecFixtureMismatch(
      relativePath: relativePath,
      expected: expected,
      actual: actual,
      label: label,
    );
  }

  void expectLanguageModelStreamEventsFixture(
    String relativePath,
    Iterable<LanguageModelStreamEvent> events,
  ) {
    expectJsonFixture(
      relativePath,
      const LanguageModelStreamEventJsonCodec()
          .encodeEvents(events.toList(growable: false)),
    );
  }
}

class ProviderCodecContractException implements Exception {
  final String message;

  const ProviderCodecContractException(this.message);

  @override
  String toString() => message;
}

final class ProviderCodecFixtureNotFound
    extends ProviderCodecContractException {
  final String relativePath;
  final List<String> searchedPaths;
  final String? label;

  ProviderCodecFixtureNotFound({
    required this.relativePath,
    required Iterable<String> searchedPaths,
    this.label,
  })  : searchedPaths = List.unmodifiable(searchedPaths),
        super(
          _formatNotFoundMessage(
            relativePath: relativePath,
            searchedPaths: searchedPaths,
            label: label,
          ),
        );
}

final class ProviderCodecFixtureMismatch
    extends ProviderCodecContractException {
  final String relativePath;
  final Object? expected;
  final Object? actual;
  final String? label;

  ProviderCodecFixtureMismatch({
    required this.relativePath,
    required this.expected,
    required this.actual,
    this.label,
  }) : super(
          _formatMismatchMessage(
            relativePath: relativePath,
            expected: expected,
            actual: actual,
            label: label,
          ),
        );
}

String _formatNotFoundMessage({
  required String relativePath,
  required Iterable<String> searchedPaths,
  required String? label,
}) {
  final prefix = label == null ? '' : '$label: ';
  return '${prefix}provider codec fixture "$relativePath" was not found. '
      'Searched: ${searchedPaths.join(', ')}.';
}

String _formatMismatchMessage({
  required String relativePath,
  required Object? expected,
  required Object? actual,
  required String? label,
}) {
  final prefix = label == null ? '' : '$label: ';
  return '${prefix}provider codec fixture "$relativePath" did not match.\n'
      'Expected:\n${_prettyJson(expected)}\n'
      'Actual:\n${_prettyJson(actual)}';
}

String _prettyJson(Object? value) {
  try {
    return const JsonEncoder.withIndent('  ').convert(value);
  } catch (_) {
    return value.toString();
  }
}

bool _jsonEquals(Object? left, Object? right) {
  if (identical(left, right)) {
    return true;
  }
  if (left == null || right == null) {
    return false;
  }
  if (left is String || left is num || left is bool) {
    return left == right;
  }
  if (left is List && right is List) {
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index += 1) {
      if (!_jsonEquals(left[index], right[index])) {
        return false;
      }
    }
    return true;
  }
  if (left is Map && right is Map) {
    if (left.length != right.length) {
      return false;
    }
    for (final entry in left.entries) {
      if (!right.containsKey(entry.key)) {
        return false;
      }
      if (!_jsonEquals(entry.value, right[entry.key])) {
        return false;
      }
    }
    return true;
  }
  return false;
}
