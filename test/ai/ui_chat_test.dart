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

    test('sendMessage replaces an existing user message when messageId is set',
        () async {
      var nextId = 0;
      String idGen() => 'id_${nextId++}';

      final transport = _FakeChatTransport(const [
        {'type': 'start'},
        {'type': 'text-start', 'id': 't1'},
        {'type': 'text-delta', 'id': 't1', 'delta': 'Done'},
        {'type': 'text-end', 'id': 't1'},
        {'type': 'finish'},
      ]);

      final chat = UiChat(
        init: UiChatInit(
          id: 'chat_1',
          generateId: idGen,
          transport: transport,
        ),
      );

      await chat.sendMessage('A');
      await chat.sendMessage('B');

      expect(chat.messages, hasLength(4));
      final firstUser = chat.messages.first;
      expect(firstUser.role, equals('user'));

      await chat.send(
        text: 'A2',
        messageId: firstUser.id,
      );

      // All messages after the replaced message are removed before submit,
      // then a new assistant message is streamed.
      expect(chat.messages, hasLength(2));
      expect(chat.messages.first.id, equals(firstUser.id));
      expect(
        chat.messages.first.parts,
        equals(const [
          {'type': 'text', 'text': 'A2'}
        ]),
      );
      expect(chat.messages.last.role, equals('assistant'));
    });

    test('sendMessage accepts parts/files/metadata', () async {
      var nextId = 0;
      String idGen() => 'id_${nextId++}';

      final transport = _FakeChatTransport(const [
        {'type': 'start'},
        {'type': 'finish'},
      ]);

      final chat = UiChat(
        init: UiChatInit(
          id: 'chat_1',
          generateId: idGen,
          transport: transport,
        ),
      );

      await chat.send(
        text: 'Hi',
        metadata: const {'m': 1},
        files: const [
          {
            'type': 'file',
            'url': 'data:text/plain;base64,SGVsbG8=',
            'mediaType': 'text/plain',
          },
        ],
        parts: const [
          {
            'type': 'data-custom',
            'data': {'x': 1}
          },
        ],
      );

      final user = chat.messages.first;
      expect(user.metadata, equals(const {'m': 1}));
      expect(user.parts, hasLength(3));
      expect(user.parts.first['type'], equals('file'));
      expect(user.parts[1]['type'], equals('data-custom'));
      expect(user.parts.last, equals(const {'type': 'text', 'text': 'Hi'}));
    });

    test('resumeStream is a no-op when there is no active stream', () async {
      var nextId = 0;
      String idGen() => 'id_${nextId++}';

      final chat = UiChat(
        init: UiChatInit(
          id: 'chat_1',
          generateId: idGen,
          transport: _NoResumeTransport(),
        ),
      );

      expect(chat.status, equals(UiChatStatus.ready));
      await chat.resumeStream();
      expect(chat.status, equals(UiChatStatus.ready));
      expect(chat.error, isNull);
    });

    test('addToolOutput updates the active response during streaming',
        () async {
      var nextId = 0;
      String idGen() => 'id_${nextId++}';

      final controller = StreamController<Map<String, Object?>>(sync: true);
      final transport = _StreamTransport(stream: controller.stream);

      final chat = UiChat(
        init: UiChatInit(
          id: 'chat_1',
          generateId: idGen,
          transport: transport,
        ),
      );

      final task = chat.sendMessage('Hi');

      controller.add(const {'type': 'start'});
      controller.add(const {
        'type': 'tool-input-available',
        'toolCallId': 'call_1',
        'toolName': 'calc',
        'input': {'x': 1},
      });

      // Wait until the tool invocation has been applied and the assistant
      // message is visible in state.
      var sawTool = false;
      for (var i = 0; i < 50; i++) {
        final last = chat.messages.isEmpty ? null : chat.messages.last;
        if (last?.role == 'assistant' &&
            last!.parts.any((p) => p['toolCallId'] == 'call_1')) {
          sawTool = true;
          break;
        }
        await Future<void>.delayed(Duration.zero);
      }
      expect(sawTool, isTrue);

      await chat.addToolOutput(
        toolCallId: 'call_1',
        toolState: 'output-available',
        output: const {'y': 2},
      );

      controller.add(const {'type': 'text-start', 'id': 't1'});
      controller.add(const {'type': 'text-delta', 'id': 't1', 'delta': 'OK'});
      controller.add(const {'type': 'text-end', 'id': 't1'});
      controller.add(const {'type': 'finish'});
      await controller.close();

      await task;

      final assistant = chat.messages.last;
      final toolPart =
          assistant.parts.where((p) => p['toolCallId'] == 'call_1').single;
      expect(toolPart['state'], equals('output-available'));
      expect(toolPart['output'], equals(const {'y': 2}));
    });

    test('onToolCall is invoked for tool-input-available chunks', () async {
      var nextId = 0;
      String idGen() => 'id_${nextId++}';

      final controller = StreamController<Map<String, Object?>>(sync: true);
      final transport = _StreamTransport(stream: controller.stream);

      var toolCalls = 0;
      late final UiChat chat;
      chat = UiChat(
        init: UiChatInit(
          id: 'chat_1',
          generateId: idGen,
          transport: transport,
          onToolCall: ({required toolCall}) async {
            toolCalls++;
            await chat.addToolOutput(
              toolCallId: toolCall['toolCallId'] as String,
              toolState: 'output-available',
              output: const {'ok': true},
            );
          },
        ),
      );

      final task = chat.sendMessage('Hi');

      controller.add(const {'type': 'start'});
      controller.add(const {
        'type': 'tool-input-available',
        'toolCallId': 'call_1',
        'toolName': 'calc',
        'input': {'x': 1},
      });
      controller.add(const {'type': 'finish'});
      await controller.close();

      await task;

      expect(toolCalls, equals(1));
      final assistant = chat.messages.last;
      final toolPart =
          assistant.parts.where((p) => p['toolCallId'] == 'call_1').single;
      expect(toolPart['state'], equals('output-available'));
      expect(toolPart['output'], equals(const {'ok': true}));
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

      // Ensure the request has started before attempting to stop it.
      var started = false;
      for (var i = 0; i < 50; i++) {
        if (chat.status == UiChatStatus.submitted ||
            chat.status == UiChatStatus.streaming) {
          started = true;
          break;
        }
        await Future<void>.delayed(Duration.zero);
      }
      expect(started, isTrue);

      await chat.stop('User cancelled');
      await controller.close();

      await task;

      expect(chat.status, equals(UiChatStatus.ready));
      expect(finish, isNotNull);
      // The stream did not emit an abort chunk, so isAbort comes from cancellation.
      expect(finish!.isAbort, isTrue);
    });

    test('addToolOutput can trigger sendAutomaticallyWhen', () async {
      var nextId = 0;
      String idGen() => 'id_${nextId++}';

      final calls = <String>[];
      final didAutoSend = Completer<void>();
      final transport = _CountingTransport(
        onSendMessages: (trigger) {
          calls.add(trigger);
          if (calls.length == 1) {
            didAutoSend.complete();
          }
        },
      );

      var autoSent = false;
      final chat = UiChat(
        init: UiChatInit(
          id: 'chat_1',
          generateId: idGen,
          transport: transport,
          sendAutomaticallyWhen: ({required messages}) {
            if (autoSent) return false;
            final last = messages.isEmpty ? null : messages.last;
            final hasToolOutput = last?.parts.any((p) =>
                    p['toolCallId'] == 'call_1' &&
                    p['state'] == 'output-available') ==
                true;
            if (!hasToolOutput) return false;
            autoSent = true;
            return true;
          },
        ),
      );

      // Seed an assistant message with a tool invocation.
      chat.state.messages = [
        UIMessage(
          id: 'id_0',
          role: 'assistant',
          parts: [
            {
              'type': 'tool-calc',
              'toolCallId': 'call_1',
              'state': 'input-available',
              'input': {'x': 1},
            }
          ],
        ),
      ];

      await chat.addToolOutput(
        toolCallId: 'call_1',
        toolState: 'output-available',
        output: const {'y': 2},
      );

      await didAutoSend.future.timeout(const Duration(seconds: 2));
      expect(calls, equals(['submit-message']));
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

class _NoResumeTransport implements UiChatTransport {
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
    throw StateError('sendMessages should not be called for resumeStream');
  }

  @override
  FutureOr<Stream<Map<String, Object?>>>? reconnectToStream({
    required String chatId,
    Map<String, String>? headers,
    Map<String, Object?>? body,
    Object? metadata,
  }) =>
      null;
}

class _StreamTransport implements UiChatTransport {
  final Stream<Map<String, Object?>> stream;

  _StreamTransport({required this.stream});

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
  }) =>
      stream;

  @override
  FutureOr<Stream<Map<String, Object?>>>? reconnectToStream({
    required String chatId,
    Map<String, String>? headers,
    Map<String, Object?>? body,
    Object? metadata,
  }) =>
      null;
}

typedef _OnSendMessages = void Function(String trigger);

class _CountingTransport implements UiChatTransport {
  final _OnSendMessages onSendMessages;

  _CountingTransport({required this.onSendMessages});

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
    onSendMessages(trigger);
    return simulateStream(
      chunks: const [
        {'type': 'start'},
        {'type': 'finish'},
      ],
      initialDelay: null,
      chunkDelay: null,
    );
  }

  @override
  FutureOr<Stream<Map<String, Object?>>>? reconnectToStream({
    required String chatId,
    Map<String, String>? headers,
    Map<String, Object?>? body,
    Object? metadata,
  }) =>
      null;
}
