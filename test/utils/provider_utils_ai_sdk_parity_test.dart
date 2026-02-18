import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:test/test.dart';

void main() {
  group('provider-utils AI SDK parity', () {
    test('combineHeaders merges in order', () {
      final out = combineHeaders(
        {'a': '1', 'b': '1'},
        {'b': '2', 'c': null},
      );

      expect(out, equals({'a': '1', 'b': '2', 'c': null}));
    });

    test('normalizeHeaders lowercases keys and drops null values', () {
      final out = normalizeHeaders({
        'Content-Type': 'application/json',
        'X-Empty': null,
        'X-Num': 123,
      });

      expect(out, equals({'content-type': 'application/json', 'x-num': '123'}));
    });

    test('withoutTrailingSlash removes a single trailing slash', () {
      expect(withoutTrailingSlash(null), isNull);
      expect(
          withoutTrailingSlash('https://example.com'), 'https://example.com');
      expect(
          withoutTrailingSlash('https://example.com/'), 'https://example.com');
      expect(withoutTrailingSlash('https://example.com//'),
          'https://example.com/');
    });

    test('loadApiKey prefers parameter', () {
      final key = loadApiKey(
        apiKey: 'k',
        environmentVariableName: 'X',
        description: 'Test',
      );
      expect(key, 'k');
    });

    test('loadApiKey falls back to injected environment', () {
      final key = loadApiKey(
        apiKey: null,
        environmentVariableName: 'TEST_KEY',
        description: 'Test',
        environmentLookup: (name) => name == 'TEST_KEY' ? 'env' : null,
      );
      expect(key, 'env');
    });

    test('loadSetting throws when missing', () {
      expect(
        () => loadSetting(
          settingValue: null,
          environmentVariableName: 'TEST_SETTING',
          settingName: 'setting',
          description: 'Test',
          environmentLookup: (_) => null,
        ),
        throwsA(isA<LoadSettingError>()),
      );
    });

    test('loadOptionalSetting returns null when missing', () {
      final value = loadOptionalSetting(
        settingValue: null,
        environmentVariableName: 'TEST_SETTING',
        environmentLookup: (_) => null,
      );
      expect(value, isNull);
    });

    test('parseJsonEventStream parses SSE data events and ignores [DONE]',
        () async {
      final chunks = Stream<List<int>>.fromIterable([
        'data: {"ok":1}\n\n'.codeUnits,
        'data: [DONE]\n\n'.codeUnits,
        'data: {"ok":2}\n\n'.codeUnits,
      ]);

      final results = <ParseResult<Map<String, Object?>>>[];

      await for (final r in parseJsonEventStream<Map<String, Object?>>(
        stream: chunks,
        decode: (json) =>
            (json as Map?)?.cast<String, Object?>() ?? <String, Object?>{},
      )) {
        results.add(r);
      }

      expect(results.where((r) => r.success).length, 2);
      final values =
          results.where((r) => r.success).map((r) => r.value).toList();
      expect(
          values,
          containsAll(<Map<String, Object?>>[
            {'ok': 1},
            {'ok': 2},
          ]));
    });
  });
}
