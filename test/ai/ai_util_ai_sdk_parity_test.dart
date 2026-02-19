import 'dart:async';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('ai util AI SDK parity', () {
    test('cosineSimilarity throws on length mismatch', () {
      expect(
        () => cosineSimilarity([1, 2], [1]),
        throwsA(isA<InvalidArgumentError>()),
      );
    });

    test('cosineSimilarity returns 0 for zero vectors', () {
      expect(cosineSimilarity([0, 0], [0, 0]), equals(0));
    });

    test('isDeepEqualData compares JSON-like structures', () {
      expect(
        isDeepEqualData(
          {
            'a': 1,
            'b': [true, 'x'],
            'c': {'d': 2},
          },
          {
            'a': 1,
            'b': [true, 'x'],
            'c': {'d': 2},
          },
        ),
        isTrue,
      );

      expect(
        isDeepEqualData(
          {'a': 1},
          {'a': 2},
        ),
        isFalse,
      );
    });

    test('parsePartialJson returns repaired-parse for partial object', () {
      final out = parsePartialJson('{"a":1');
      expect(out.state, equals('failed-parse'));

      final repaired = parsePartialJson('{"a":1} trailing');
      expect(repaired.state, equals('repaired-parse'));
      expect(repaired.value, equals({'a': 1}));
    });

    test('getTextFromDataUrl decodes base64 payload', () {
      final text = getTextFromDataUrl('data:text/plain;base64,SGVsbG8=');
      expect(text, equals('Hello'));
    });

    test('SerialJobExecutor runs jobs serially', () async {
      final exec = SerialJobExecutor();
      final order = <int>[];

      final a = exec.run(() async {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        order.add(1);
      });
      final b = exec.run(() async {
        order.add(2);
      });

      await Future.wait([a, b]);
      expect(order, equals([1, 2]));
    });

    test('consumeStream drains stream and calls onError on failure', () async {
      final errors = <Object>[];
      await consumeStream<int>(
        stream: Stream<int>.error(StateError('boom')),
        onError: errors.add,
      );
      expect(errors.single, isA<StateError>());
    });

    test('simulateStream emits values in order', () async {
      final out = await simulateStream(
        chunks: const [1, 2, 3],
        initialDelay: null,
        chunkDelay: null,
      ).toList();
      expect(out, equals([1, 2, 3]));
    });
  });
}
