import 'dart:convert';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

class _TestChatResponse extends ChatResponse {
  @override
  final String? text;

  @override
  final List<ToolCall>? toolCalls;

  @override
  final UsageInfo? usage;

  @override
  final Map<String, dynamic>? providerMetadata;

  _TestChatResponse({
    this.text,
    this.toolCalls,
    this.usage,
    this.providerMetadata,
  });
}

List<Map<String, Object?>> _decodeSseChunks(List<String> sseLines) {
  final out = <Map<String, Object?>>[];
  for (final line in sseLines) {
    if (!line.startsWith('data: ')) continue;
    final payload = line.substring('data: '.length).trim();
    if (payload == '[DONE]') continue;
    final obj = jsonDecode(payload);
    out.add((obj as Map).cast<String, Object?>());
  }
  return out;
}

void main() {
  group('ui message stream (ai-sdk style)', () {
    test('encodes text parts + finish and appends [DONE]', () async {
      final partsList = <LLMStreamPart>[
        const LLMTextStartPart(blockId: 't1'),
        const LLMTextDeltaPart('Hello', blockId: 't1'),
        const LLMTextEndPart('Hello', blockId: 't1'),
        LLMFinishPart(
          _TestChatResponse(text: 'Hello'),
          finishReason: const LLMFinishReason(
            unified: LLMUnifiedFinishReason.stop,
            raw: null,
          ),
        ),
      ];

      final chunks =
          await uiMessageChunksFromParts(Stream.fromIterable(partsList))
              .toList();
      expect(
        chunks,
        equals([
          const {'type': 'start'},
          const {'type': 'text-start', 'id': 't1'},
          const {'type': 'text-delta', 'id': 't1', 'delta': 'Hello'},
          const {'type': 'text-end', 'id': 't1'},
          const {'type': 'finish', 'finishReason': 'stop'},
        ]),
      );

      final sse = await uiMessageSseFromParts(Stream.fromIterable(partsList))
          .toList();
      expect(sse.last, equals('data: [DONE]\n\n'));

      final decoded = _decodeSseChunks(sse);
      expect(decoded, equals(chunks));
    });

    test('includes messageId and messageMetadata on start/finish when provided',
        () async {
      final partsList = <LLMStreamPart>[
        const LLMTextStartPart(blockId: 't1'),
        const LLMTextDeltaPart('Hello', blockId: 't1'),
        const LLMTextEndPart('Hello', blockId: 't1'),
        LLMFinishPart(
          _TestChatResponse(text: 'Hello'),
          finishReason: const LLMFinishReason(
            unified: LLMUnifiedFinishReason.stop,
            raw: null,
          ),
        ),
      ];

      final chunks = await uiMessageChunksFromParts(
        Stream.fromIterable(partsList),
        messageId: 'msg_1',
        startMessageMetadata: const {'phase': 'start'},
        finishMessageMetadata: (_) => const {'phase': 'finish'},
      ).toList();

      expect(
        chunks.first,
        equals(const {
          'type': 'start',
          'messageId': 'msg_1',
          'messageMetadata': {'phase': 'start'},
        }),
      );

      expect(
        chunks.last,
        equals(const {
          'type': 'finish',
          'finishReason': 'stop',
          'messageMetadata': {'phase': 'finish'},
        }),
      );
    });

    test('encodes tool input deltas and emits tool-input-available on end', () async {
      final parts = Stream<LLMStreamPart>.fromIterable([
        const LLMToolInputStartPart(id: 'call1', toolName: 'calc'),
        const LLMToolInputDeltaPart(id: 'call1', delta: '{"x":1}'),
        const LLMToolInputEndPart(id: 'call1'),
        LLMFinishPart(
          _TestChatResponse(),
          finishReason: const LLMFinishReason(
            unified: LLMUnifiedFinishReason.toolCalls,
            raw: null,
          ),
        ),
      ]);

      final chunks = await uiMessageChunksFromParts(parts, sendStart: false).toList();
      expect(
        chunks,
        equals([
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
          {
            'type': 'tool-input-available',
            'toolCallId': 'call1',
            'toolName': 'calc',
            'input': {'x': 1},
          },
          const {'type': 'finish', 'finishReason': 'tool-calls'},
        ]),
      );
    });

    test('maps ToolApprovalRequiredError to tool-output-denied + abort', () async {
      const toolCall = ToolCall(
        id: 'call1',
        callType: 'function',
        function: FunctionCall(name: 'calc', arguments: '{"x":1}'),
      );

      final state = ToolLoopBlockedState(
        stepIndex: 0,
        stepResult: GenerateTextResult(rawResponse: _TestChatResponse()),
        toolCalls: const [toolCall],
        toolCallsNeedingApproval: const [toolCall],
        steps: const <ToolLoopStep>[],
        messages: const <ChatMessage>[],
        prompt: null,
      );

      final parts = Stream<LLMStreamPart>.fromIterable([
        LLMErrorPart(ToolApprovalRequiredError(state: state)),
      ]);

      final chunks =
          await uiMessageChunksFromParts(parts, sendStart: false).toList();

      expect(
        chunks,
        equals([
          const {'type': 'tool-output-denied', 'toolCallId': 'call1'},
          const {'type': 'abort', 'reason': 'Tool approval required'},
        ]),
      );
    });

    test('encodes file parts as data: URLs', () async {
      final parts = Stream<LLMStreamPart>.fromIterable([
        const LLMFilePart(mediaType: 'image/png', data: 'AQID'),
        LLMFinishPart(
          _TestChatResponse(),
          finishReason: const LLMFinishReason(
            unified: LLMUnifiedFinishReason.other,
            raw: null,
          ),
        ),
      ]);

      final chunks = await uiMessageChunksFromParts(
        parts,
        sendStart: false,
        sendFinish: false,
      ).toList();

      expect(chunks, hasLength(1));
      expect(chunks.single['type'], equals('file'));
      expect(chunks.single['mediaType'], equals('image/png'));
      expect(
        chunks.single['url'],
        startsWith('data:image/png;base64,'),
      );
    });
  });
}
