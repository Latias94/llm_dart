import 'dart:async';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:test/test.dart';

void main() {
  group('readUiMessageStream (ai-sdk style)', () {
    test('builds text and reasoning parts incrementally', () async {
      final chunks = Stream.fromIterable(<Map<String, Object?>>[
        const {'type': 'start', 'messageId': 'msg_1'},
        const {'type': 'text-start', 'id': 't1'},
        const {'type': 'text-delta', 'id': 't1', 'delta': 'Hel'},
        const {'type': 'text-delta', 'id': 't1', 'delta': 'lo'},
        const {'type': 'text-end', 'id': 't1'},
        const {'type': 'reasoning-start', 'id': 'r1'},
        const {'type': 'reasoning-delta', 'id': 'r1', 'delta': 'Think'},
        const {'type': 'reasoning-end', 'id': 'r1'},
        const {'type': 'finish', 'finishReason': 'stop'},
      ]);

      final snapshots = await readUiMessageStream(chunks: chunks).toList();
      expect(snapshots, isNotEmpty);

      final last = snapshots.last;
      expect(last.id, equals('msg_1'));
      expect(last.role, equals('assistant'));

      final textParts =
          last.parts.where((p) => p['type'] == 'text').toList(growable: false);
      expect(textParts, hasLength(1));
      expect(textParts.single['text'], equals('Hello'));
      expect(textParts.single['state'], equals('done'));

      final reasoningParts = last.parts
          .where((p) => p['type'] == 'reasoning')
          .toList(growable: false);
      expect(reasoningParts, hasLength(1));
      expect(reasoningParts.single['text'], equals('Think'));
      expect(reasoningParts.single['state'], equals('done'));
    });

    test('merges message metadata from start + message-metadata + finish',
        () async {
      final chunks = Stream.fromIterable(<Map<String, Object?>>[
        const {
          'type': 'start',
          'messageId': 'msg_1',
          'messageMetadata': {
            'a': 1,
            'nested': {'x': 1}
          },
        },
        const {
          'type': 'message-metadata',
          'messageMetadata': {
            'b': 2,
            'nested': {'y': 2}
          },
        },
        const {
          'type': 'finish',
          'finishReason': 'stop',
          'messageMetadata': {
            'nested': {'x': 3}
          },
        },
      ]);

      final last = await readUiMessageStream(chunks: chunks).last;
      expect(last.metadata, isA<Map>());
      final meta = (last.metadata as Map).cast<String, Object?>();
      expect(meta['a'], equals(1));
      expect(meta['b'], equals(2));
      expect(meta['nested'], equals(const {'x': 3, 'y': 2}));
    });

    test('builds tool invocation parts from tool input/output chunks',
        () async {
      final chunks = Stream.fromIterable(<Map<String, Object?>>[
        const {'type': 'start', 'messageId': 'msg_1'},
        const {
          'type': 'tool-input-start',
          'toolCallId': 'call1',
          'toolName': 'calc',
        },
        const {
          'type': 'tool-input-delta',
          'toolCallId': 'call1',
          'inputTextDelta': '{"x":1}',
        },
        const {
          'type': 'tool-input-available',
          'toolCallId': 'call1',
          'toolName': 'calc',
          'input': {'x': 1},
        },
        const {
          'type': 'tool-output-available',
          'toolCallId': 'call1',
          'output': {'y': 2},
        },
        const {'type': 'finish', 'finishReason': 'tool-calls'},
      ]);

      final last = await readUiMessageStream(chunks: chunks).last;

      final toolParts = last.parts
          .where((p) => p['type'] == 'tool-calc')
          .toList(growable: false);
      expect(toolParts, hasLength(1));
      final tool = toolParts.single;
      expect(tool['toolCallId'], equals('call1'));
      expect(tool['state'], equals('output-available'));
      expect(tool['input'], equals(const {'x': 1}));
      expect(tool['output'], equals(const {'y': 2}));
    });

    test('maps sources and files into UI message parts', () async {
      final chunks = Stream.fromIterable(<Map<String, Object?>>[
        const {'type': 'start', 'messageId': 'msg_1'},
        const {
          'type': 'source-url',
          'sourceId': 's1',
          'url': 'https://example.com',
          'title': 'Example',
        },
        const {
          'type': 'file',
          'url': 'data:text/plain;base64,SGVsbG8=',
          'mediaType': 'text/plain',
        },
        const {'type': 'finish', 'finishReason': 'stop'},
      ]);

      final last = await readUiMessageStream(chunks: chunks).last;
      expect(
        last.parts.where((p) => p['type'] == 'source').single,
        equals(const {
          'type': 'source',
          'sourceType': 'url',
          'id': 's1',
          'url': 'https://example.com',
          'title': 'Example',
        }),
      );
      expect(
        last.parts.where((p) => p['type'] == 'file').single,
        equals(const {
          'type': 'file',
          'url': 'data:text/plain;base64,SGVsbG8=',
          'mediaType': 'text/plain',
        }),
      );
    });

    test('terminates when receiving an error chunk (terminateOnError=true)',
        () async {
      final chunks = Stream.fromIterable(<Map<String, Object?>>[
        const {'type': 'start', 'messageId': 'msg_1'},
        const {'type': 'text-start', 'id': 't1'},
        const {'type': 'text-delta', 'id': 't1', 'delta': 'Hello'},
        const {'type': 'error', 'errorText': 'Test error message'},
      ]);

      expect(
        () => readUiMessageStream(
          chunks: chunks,
          terminateOnError: true,
        ).toList(),
        throwsA(
          isA<UiMessageStreamError>().having(
            (e) => e.message,
            'message',
            contains('Test error message'),
          ),
        ),
      );
    });
  });

  group('handleUiMessageStreamFinish (ai-sdk style)', () {
    test('injects messageId into start chunk when missing', () async {
      final rawChunks = Stream.fromIterable(<Map<String, Object?>>[
        const {'type': 'start'},
        const {'type': 'finish', 'finishReason': 'stop'},
      ]);

      final out = await handleUiMessageStreamFinish(
        chunks: rawChunks,
        messageId: 'msg_1',
      ).toList();

      expect(out.first, equals(const {'type': 'start', 'messageId': 'msg_1'}));
    });

    test('calls onStepFinish and onFinish callbacks', () async {
      final rawChunks = Stream.fromIterable(<Map<String, Object?>>[
        const {'type': 'start', 'messageId': 'msg_1'},
        const {'type': 'start-step'},
        const {'type': 'finish-step'},
        const {'type': 'finish', 'finishReason': 'stop'},
      ]);

      var stepCalls = 0;
      var finishCalls = 0;
      String? finishReason;

      final outStream = handleUiMessageStreamFinish(
        chunks: rawChunks,
        onStepFinish: (evt) {
          stepCalls++;
          expect(evt.responseMessage.id, equals('msg_1'));
        },
        onFinish: (evt) {
          finishCalls++;
          finishReason = evt.finishReason;
          expect(evt.responseMessage.id, equals('msg_1'));
          expect(evt.isAborted, isFalse);
        },
      );

      await outStream.drain();
      expect(stepCalls, equals(1));
      expect(finishCalls, equals(1));
      expect(finishReason, equals('stop'));
    });

    test('treats last assistant message as continuation', () async {
      final rawChunks = Stream.fromIterable(<Map<String, Object?>>[
        const {'type': 'start'},
        const {'type': 'text-start', 'id': 't1'},
        const {'type': 'text-delta', 'id': 't1', 'delta': 'Hi'},
        const {'type': 'text-end', 'id': 't1'},
        const {'type': 'finish', 'finishReason': 'stop'},
      ]);

      final original = UIMessage(
        id: 'msg_prev',
        role: 'assistant',
        parts: const [
          {'type': 'text', 'text': 'Prev', 'state': 'done'}
        ],
      );

      UiMessageStreamFinishEvent? finish;
      final stream = handleUiMessageStreamFinish(
        chunks: rawChunks,
        messageId: 'msg_new',
        originalMessages: [original],
        onFinish: (evt) => finish = evt,
      );

      await stream.drain();
      expect(finish, isNotNull);
      expect(finish!.isContinuation, isTrue);
      expect(finish!.responseMessage.id, equals('msg_prev'));
      expect(
        finish!.responseMessage.parts.where((p) => p['type'] == 'text').length,
        equals(2),
      );
    });
  });
}
