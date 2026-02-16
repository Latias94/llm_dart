import 'dart:async';

import 'ui_message_stream_writer.dart';

/// Creates a UI message stream (chunk stream) that can be consumed by a UI client.
///
/// Upstream reference:
/// `repo-ref/ai/packages/ai/src/ui-message-stream/create-ui-message-stream.ts`
///
/// Design notes:
/// - This returns a Dart [Stream] of JSON-like maps (chunks).
/// - Use `uiMessageSseFromChunks(...)` to encode it as SSE (`data: ...\n\n`).
/// - The [writer] can be captured and used after [execute] returns; the stream
///   stays open until all merged streams complete.
Stream<Map<String, Object?>> createUiMessageStream({
  required FutureOr<void> Function(UIMessageStreamWriter writer) execute,
  String Function(Object error)? onError,
}) {
  final controller = StreamController<Map<String, Object?>>(sync: true);
  final ongoing = <Future<void>>[];

  void safeAdd(Map<String, Object?> chunk) {
    if (controller.isClosed) return;
    try {
      controller.add(chunk);
    } catch (_) {
      // Suppress errors when the stream has been closed.
    }
  }

  Map<String, Object?> errorChunk(Object error) => <String, Object?>{
        'type': 'error',
        'errorText': onError != null ? onError(error) : error.toString(),
      };

  final writer = _Writer(
    write: safeAdd,
    merge: (stream) {
      final task = () async {
        try {
          await for (final chunk in stream) {
            safeAdd(chunk);
          }
        } catch (e) {
          safeAdd(errorChunk(e));
        }
      }();
      ongoing.add(task);
    },
  );

  void startExecute() {
    try {
      final result = execute(writer);
      if (result is Future) {
        ongoing.add(
          result.catchError((e) {
            safeAdd(errorChunk(e));
          }).then((_) {}),
        );
      }
    } catch (e) {
      safeAdd(errorChunk(e));
    }
  }

  Future<void> waitForMergedStreamsAndClose() async {
    try {
      // Wait until all merged streams are done. This mirrors the AI SDK behavior
      // of allowing `writer.merge(...)` calls after `execute(...)` has returned.
      while (ongoing.isNotEmpty) {
        await ongoing.removeAt(0);
      }
    } finally {
      await controller.close();
    }
  }

  // Kick off execution and closing logic.
  scheduleMicrotask(startExecute);
  scheduleMicrotask(waitForMergedStreamsAndClose);

  return controller.stream;
}

class _Writer implements UIMessageStreamWriter {
  final void Function(Map<String, Object?> chunk) _write;
  final void Function(Stream<Map<String, Object?>> stream) _merge;

  const _Writer({
    required void Function(Map<String, Object?> chunk) write,
    required void Function(Stream<Map<String, Object?>> stream) merge,
  })  : _write = write,
        _merge = merge;

  @override
  void write(Map<String, Object?> chunk) => _write(chunk);

  @override
  void merge(Stream<Map<String, Object?>> stream) => _merge(stream);
}
