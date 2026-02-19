import 'dart:async';
import 'dart:typed_data';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:test/test.dart';

void main() {
  group('provider-utils AI SDK parity', () {
    test('resolve resolves value/future/function', () async {
      expect(await resolve<String>('a'), 'a');
      expect(await resolve<String>(Future.value('b')), 'b');
      expect(await resolve<String>(() => 'c'), 'c');
      expect(await resolve<String>(() async => 'd'), 'd');
    });

    test('removeUndefinedEntries drops null values', () {
      final out = removeUndefinedEntries<String>({
        'a': '1',
        'b': null,
        'c': '3',
      });
      expect(out, equals({'a': '1', 'c': '3'}));
    });

    test('getErrorMessage returns stable strings', () {
      expect(getErrorMessage(null), 'unknown error');
      expect(getErrorMessage('x'), 'x');
      expect(getErrorMessage(const InvalidRequestError('bad')), 'bad');
      expect(getErrorMessage({'a': 1}), '{"a":1}');
      expect(getErrorMessage(Exception('oops')), contains('oops'));
    });

    test('isAbortError recognizes cancel/timeout', () {
      expect(isAbortError(const CancelledError('cancel')), isTrue);
      expect(isAbortError(const TimeoutError('timeout')), isTrue);
      expect(isAbortError(const GenericError('no')), isFalse);
    });

    test('isUrlSupported matches media type prefixes and wildcard', () {
      final supportedUrls = <String, List<RegExp>>{
        'image/*': [RegExp(r'^https://example\.com/')],
        '*': [RegExp(r'^https://wild\.com/')],
      };

      expect(
        isUrlSupported(
          mediaType: 'image/png',
          url: 'HTTPS://EXAMPLE.COM/A.PNG',
          supportedUrls: supportedUrls,
        ),
        isTrue,
      );

      expect(
        isUrlSupported(
          mediaType: 'text/plain',
          url: 'https://wild.com/x',
          supportedUrls: supportedUrls,
        ),
        isTrue,
      );

      expect(
        isUrlSupported(
          mediaType: 'text/plain',
          url: 'https://example.com/x',
          supportedUrls: supportedUrls,
        ),
        isFalse,
      );
    });

    test('readResponseWithSizeLimit returns bytes within limit', () async {
      final out = await readResponseWithSizeLimit(
        body: Stream<List<int>>.fromIterable([
          <int>[1, 2],
          <int>[3],
        ]),
        url: Uri.parse('https://example.com/file'),
        maxBytes: 3,
      );

      expect(out, equals(Uint8List.fromList([1, 2, 3])));
    });

    test('readResponseWithSizeLimit early rejects by contentLength', () async {
      Future<void> run() async {
        await readResponseWithSizeLimit(
          body: const Stream<List<int>>.empty(),
          url: Uri.parse('https://example.com/file'),
          maxBytes: 2,
          contentLength: 3,
        );
      }

      await expectLater(
        run,
        throwsA(
          isA<DownloadError>().having(
            (e) => e.url.toString(),
            'url',
            'https://example.com/file',
          ),
        ),
      );
    });

    test('readResponseWithSizeLimit rejects when stream exceeds limit',
        () async {
      Future<void> run() async {
        await readResponseWithSizeLimit(
          body: Stream<List<int>>.fromIterable([
            <int>[1, 2],
            <int>[3],
          ]),
          url: Uri.parse('https://example.com/file'),
          maxBytes: 2,
        );
      }

      await expectLater(run, throwsA(isA<DownloadError>()));
    });

    test('parseProviderOptions returns null when namespace absent', () async {
      final out = await parseProviderOptions<Map<String, dynamic>>(
        provider: 'openai',
        providerOptions: const <String, Map<String, dynamic>>{},
        parse: (raw) async => raw as Map<String, dynamic>,
      );
      expect(out, isNull);
    });

    test('parseProviderOptions parses namespaced options', () async {
      final out = await parseProviderOptions<Map<String, dynamic>>(
        provider: 'openai',
        providerOptions: const <String, Map<String, dynamic>>{
          'openai': <String, dynamic>{'foo': 1},
        },
        parse: (raw) => raw as Map<String, dynamic>,
      );
      expect(out, equals({'foo': 1}));
    });

    test('parseProviderOptions throws InvalidArgumentError on parse error',
        () async {
      Future<void> run() async {
        await parseProviderOptions<int>(
          provider: 'openai',
          providerOptions: const <String, Map<String, dynamic>>{
            'openai': <String, dynamic>{'foo': 1},
          },
          parse: (raw) => throw StateError('nope'),
        );
      }

      await expectLater(
        run,
        throwsA(
          isA<InvalidArgumentError>()
              .having((e) => e.argument, 'argument', 'providerOptions'),
        ),
      );
    });

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
