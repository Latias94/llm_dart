import 'dart:async';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:test/test.dart';

void main() {
  group('createUiMessageStream', () {
    test('writes chunks in order', () async {
      final stream = createUiMessageStream(
        execute: (writer) {
          writer.write(const {'type': 'start'});
          writer.write(const {'type': 'text-delta', 'id': 't1', 'delta': 'Hi'});
          writer.write(const {'type': 'finish'});
        },
      );

      final chunks = await stream.toList();
      expect(
        chunks,
        equals(const [
          {'type': 'start'},
          {'type': 'text-delta', 'id': 't1', 'delta': 'Hi'},
          {'type': 'finish'},
        ]),
      );
    });

    test('merges another stream and keeps stream open after execute returns',
        () async {
      final capturedCompleter = Completer<UIMessageStreamWriter>();
      final done = Completer<void>();

      final stream = createUiMessageStream(
        execute: (writer) async {
          if (!capturedCompleter.isCompleted) {
            capturedCompleter.complete(writer);
          }
          writer.write(const {'type': 'start'});
          await done.future;
        },
      );

      final captured = await capturedCompleter.future;

      // Merge after execute has returned (microtask scheduling).
      final controller = StreamController<Map<String, Object?>>(sync: true);
      captured.merge(controller.stream);

      controller.add(const {'type': 'text-delta', 'id': 't1', 'delta': 'A'});
      controller.add(const {'type': 'text-delta', 'id': 't1', 'delta': 'B'});
      await controller.close();
      done.complete();

      final chunks = await stream.toList();
      expect(
        chunks,
        equals(const [
          {'type': 'start'},
          {'type': 'text-delta', 'id': 't1', 'delta': 'A'},
          {'type': 'text-delta', 'id': 't1', 'delta': 'B'},
        ]),
      );
    });

    test('converts merge errors into error chunks', () async {
      final stream = createUiMessageStream(
        execute: (writer) {
          writer.merge(
            Stream<Map<String, Object?>>.error(StateError('boom')),
          );
        },
        onError: (e) => 'ERR:${e is StateError ? e.message : e.toString()}',
      );

      final chunks = await stream.toList();
      expect(chunks, hasLength(1));
      expect(
        chunks.single,
        equals(const {'type': 'error', 'errorText': 'ERR:boom'}),
      );
    });
  });
}
