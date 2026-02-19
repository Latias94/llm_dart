import 'dart:async';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:test/test.dart';

void main() {
  group('createUiMessageStream', () {
    test('writes chunks in order', () async {
      final stream = createUiMessageStream(
        execute: (writer) {
          writer.write(const {'type': 'text-start', 'id': 't1'});
          writer.write(const {'type': 'text-delta', 'id': 't1', 'delta': 'Hi'});
          writer.write(const {'type': 'text-end', 'id': 't1'});
        },
      );

      final chunks = await stream.toList();
      expect(
        chunks,
        equals(const [
          {'type': 'text-start', 'id': 't1'},
          {'type': 'text-delta', 'id': 't1', 'delta': 'Hi'},
          {'type': 'text-end', 'id': 't1'},
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
          writer.write(const {'type': 'text-start', 'id': 't1'});
          await done.future;
        },
      );

      final captured = await capturedCompleter.future;

      // Merge after execute has returned (microtask scheduling).
      final controller = StreamController<Map<String, Object?>>(sync: true);
      captured.merge(controller.stream);

      controller.add(const {'type': 'text-delta', 'id': 't1', 'delta': 'A'});
      controller.add(const {'type': 'text-delta', 'id': 't1', 'delta': 'B'});
      controller.add(const {'type': 'text-end', 'id': 't1'});
      await controller.close();
      done.complete();

      final chunks = await stream.toList();
      expect(
        chunks,
        equals(const [
          {'type': 'text-start', 'id': 't1'},
          {'type': 'text-delta', 'id': 't1', 'delta': 'A'},
          {'type': 'text-delta', 'id': 't1', 'delta': 'B'},
          {'type': 'text-end', 'id': 't1'},
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

    test('exposes writer.onError for nested streams', () async {
      final stream = createUiMessageStream(
        onError: (e) => 'P:${e is StateError ? e.message : e.toString()}',
        execute: (writer) {
          final child = createUiMessageStream(
            onError: writer.onError,
            execute: (childWriter) {
              childWriter.merge(
                Stream<Map<String, Object?>>.error(StateError('boom')),
              );
            },
          );

          writer.merge(child);
        },
      );

      final chunks = await stream.toList();
      expect(chunks, hasLength(1));
      expect(
        chunks.single,
        equals(const {'type': 'error', 'errorText': 'P:boom'}),
      );
    });

    test('injects messageId into start chunk and calls onFinish', () async {
      UiMessageStreamFinishEvent? finishEvent;

      final stream = createUiMessageStream(
        generateId: () => 'msg_fixed',
        onFinish: (event) => finishEvent = event,
        execute: (writer) {
          writer.write(const {'type': 'start'});
          writer.write(const {'type': 'finish', 'finishReason': 'stop'});
        },
      );

      final chunks = await stream.toList();
      expect(chunks, hasLength(2));
      expect(chunks.first['type'], equals('start'));
      expect(chunks.first['messageId'], equals('msg_fixed'));

      expect(finishEvent, isNotNull);
      expect(finishEvent!.isAborted, isFalse);
      expect(finishEvent!.isContinuation, isFalse);
      expect(finishEvent!.responseMessage.id, equals('msg_fixed'));
      expect(finishEvent!.finishReason, equals('stop'));
    });
  });
}
