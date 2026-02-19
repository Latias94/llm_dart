import 'dart:async';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

class _FakeChatTransport implements UiChatTransport {
  final List<Map<String, Object?>> chunks;

  _FakeChatTransport(this.chunks);

  @override
  FutureOr<Stream<Map<String, Object?>>>? reconnectToStream({
    required String chatId,
    Map<String, String>? headers,
    Map<String, Object?>? body,
    Object? metadata,
  }) =>
      null;

  @override
  FutureOr<Stream<Map<String, Object?>>> sendMessages({
    required String chatId,
    required List<UIMessage> messages,
    required String trigger,
    String? messageId,
    Map<String, String>? headers,
    Map<String, Object?>? body,
    Object? metadata,
    CancelToken? cancelToken,
  }) {
    return simulateStream(
      chunks: chunks,
      initialDelay: null,
      chunkDelay: null,
    );
  }
}

void main() {
  group('UiChat', () {
    test('sendMessage streams assistant response and calls onFinish', () async {
      var nextId = 0;
      String idGen() => 'id_${nextId++}';

      final transport = _FakeChatTransport(const [
        {'type': 'start'},
        {'type': 'start-step'},
        {'type': 'text-start', 'id': 't1'},
        {'type': 'text-delta', 'id': 't1', 'delta': 'Hello'},
        {'type': 'text-delta', 'id': 't1', 'delta': '.'},
        {'type': 'text-end', 'id': 't1'},
        {'type': 'finish-step'},
        {'type': 'finish', 'finishReason': 'stop'},
      ]);

      UiChatFinishEvent? finish;

      final chat = UiChat(
        init: UiChatInit(
          id: 'chat_1',
          generateId: idGen,
          transport: transport,
          onFinish: (evt) => finish = evt,
        ),
      );

      await chat.sendMessage('Hi');

      expect(chat.status, equals(UiChatStatus.ready));
      expect(chat.error, isNull);
      expect(chat.messages, hasLength(2));

      final user = chat.messages.first;
      expect(user.id, equals('id_0'));
      expect(user.role, equals('user'));
      expect(
          user.parts,
          equals(const [
            {'type': 'text', 'text': 'Hi'},
          ]));

      final assistant = chat.messages.last;
      expect(assistant.id, equals('id_1'));
      expect(assistant.role, equals('assistant'));

      final textParts =
          assistant.parts.where((p) => p['type'] == 'text').toList();
      expect(textParts, hasLength(1));
      expect(textParts.single['text'], equals('Hello.'));

      expect(finish, isNotNull);
      expect(finish!.isAbort, isFalse);
      expect(finish!.isError, isFalse);
      expect(finish!.finishReason, equals('stop'));
      expect(finish!.message.id, equals('id_1'));
      expect(finish!.messages, hasLength(2));
    });

    test('stop cancels an active request', () async {
      var nextId = 0;
      String idGen() => 'id_${nextId++}';

      final controller = StreamController<Map<String, Object?>>(sync: true);

      final transport = _CancelAwareTransport(
        stream: controller.stream,
      );

      UiChatFinishEvent? finish;

      final chat = UiChat(
        init: UiChatInit(
          id: 'chat_1',
          generateId: idGen,
          transport: transport,
          onFinish: (evt) => finish = evt,
        ),
      );

      final task = chat.sendMessage('Hi');

      controller.add(const {'type': 'start'});
      controller.add(const {'type': 'text-start', 'id': 't1'});
      controller.add(const {'type': 'text-delta', 'id': 't1', 'delta': 'A'});

      await chat.stop('User cancelled');
      await controller.close();

      await task;

      expect(chat.status, equals(UiChatStatus.ready));
      expect(finish, isNotNull);
      // The stream did not emit an abort chunk, so isAbort comes from cancellation.
      expect(finish!.isAbort, isTrue);
    });
  });
}

class _CancelAwareTransport implements UiChatTransport {
  final Stream<Map<String, Object?>> stream;

  _CancelAwareTransport({required this.stream});

  @override
  FutureOr<Stream<Map<String, Object?>>>? reconnectToStream({
    required String chatId,
    Map<String, String>? headers,
    Map<String, Object?>? body,
    Object? metadata,
  }) =>
      null;

  @override
  FutureOr<Stream<Map<String, Object?>>> sendMessages({
    required String chatId,
    required List<UIMessage> messages,
    required String trigger,
    String? messageId,
    Map<String, String>? headers,
    Map<String, Object?>? body,
    Object? metadata,
    CancelToken? cancelToken,
  }) async* {
    await for (final chunk in stream) {
      if (cancelToken?.isCancelled == true) {
        throw CancelledError(cancelToken?.reason?.toString() ?? 'Cancelled');
      }
      yield chunk;
    }

    if (cancelToken?.isCancelled == true) {
      throw CancelledError(cancelToken?.reason?.toString() ?? 'Cancelled');
    }
  }
}
