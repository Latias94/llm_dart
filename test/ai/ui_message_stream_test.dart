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
  })  : toolCalls = null,
        usage = null,
        providerMetadata = null;
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

      final sse =
          await uiMessageSseFromParts(Stream.fromIterable(partsList)).toList();
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

    test('emits message-metadata chunks when messageMetadata callback is set',
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
        sendStart: false,
        messageMetadata: (_) => const {'traceId': 't'},
      ).toList();

      expect(
        chunks,
        equals([
          const {'type': 'text-start', 'id': 't1'},
          const {
            'type': 'message-metadata',
            'messageMetadata': {'traceId': 't'}
          },
          const {'type': 'text-delta', 'id': 't1', 'delta': 'Hello'},
          const {
            'type': 'message-metadata',
            'messageMetadata': {'traceId': 't'}
          },
          const {'type': 'text-end', 'id': 't1'},
          const {
            'type': 'message-metadata',
            'messageMetadata': {'traceId': 't'}
          },
          const {'type': 'finish', 'finishReason': 'stop'},
        ]),
      );
    });

    test('encodes tool input deltas and emits tool-input-available on end',
        () async {
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

      final chunks =
          await uiMessageChunksFromParts(parts, sendStart: false).toList();
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

    test('maps tool approval request to tool-approval-request', () async {
      final parts = Stream<LLMStreamPart>.fromIterable([
        const LLMProviderToolApprovalRequestPart(
          approvalId: 'apr_1',
          toolCallId: 'call1',
          toolName: 'calc',
          input: {'x': 1},
        ),
        LLMFinishPart(
          _TestChatResponse(),
          finishReason: const LLMFinishReason(
            unified: LLMUnifiedFinishReason.toolCalls,
            raw: null,
          ),
        ),
      ]);

      final chunks =
          await uiMessageChunksFromParts(parts, sendStart: false).toList();

      expect(
        chunks,
        equals([
          const {
            'type': 'tool-approval-request',
            'approvalId': 'apr_1',
            'toolCallId': 'call1',
          },
          const {'type': 'finish', 'finishReason': 'tool-calls'},
        ]),
      );
    });

    test(
        'emits data-tool-loop-blocked when ToolLoopBlockedState raw part is present',
        () async {
      const toolCall = V3ToolCall(
        toolCallId: 'call1',
        toolName: 'calc',
        input: '{"x":1}',
      );

      final state = ToolLoopBlockedState(
        stepIndex: 2,
        stepResult: GenerateTextResult(rawResponse: _TestChatResponse()),
        toolCalls: const [toolCall],
        toolApprovalRequests: const [
          ToolApprovalRequest(
            approvalId: 'apr_1',
            toolCall: toolCall,
          ),
        ],
        steps: const <ToolLoopStep>[],
        messages: const <ChatMessage>[],
        prompt: null,
      );

      final parts = Stream<LLMStreamPart>.fromIterable([
        const LLMProviderToolApprovalRequestPart(
          approvalId: 'apr_1',
          toolCallId: 'call1',
          toolName: 'calc',
          input: {'x': 1},
        ),
        LLMToolLoopBlockedPart(state),
        LLMFinishPart(
          _TestChatResponse(),
          finishReason: const LLMFinishReason(
            unified: LLMUnifiedFinishReason.toolCalls,
            raw: null,
          ),
        ),
      ]);

      final chunks = await uiMessageChunksFromParts(
        parts,
        sendStart: false,
        toolApprovalBlockedStateData: (s) => {
          'stepIndex': s.stepIndex,
          'toolCallIds':
              s.toolApprovalRequests.map((r) => r.toolCall.toolCallId).toList(),
        },
      ).toList();

      expect(
        chunks,
        equals([
          const {
            'type': 'tool-approval-request',
            'approvalId': 'apr_1',
            'toolCallId': 'call1',
          },
          {
            'type': 'data-tool-blocked',
            'data': {
              'kind': 'tool-loop',
              'stepIndex': 2,
              'approvalIds': ['apr_1'],
              'toolCallIds': ['call1'],
              'extra': {
                'stepIndex': 2,
                'toolCallIds': ['call1'],
              },
            },
          },
          {
            'type': 'data-tool-loop-blocked',
            'data': {
              'kind': 'tool-loop',
              'stepIndex': 2,
              'approvalIds': ['apr_1'],
              'toolCallIds': ['call1'],
              'extra': {
                'stepIndex': 2,
                'toolCallIds': ['call1'],
              },
            },
          },
          const {'type': 'finish', 'finishReason': 'tool-calls'},
        ]),
      );
    });

    test(
        'emits data-tool-approval-blocked when provider tool approval state is present',
        () async {
      final blockedState = ProviderToolApprovalBlockedState(
        stepIndex: 0,
        prompt: Prompt(messages: [PromptMessage.user('hi')]),
        approvalRequests: const [
          LLMProviderToolApprovalRequestPart(
            approvalId: 'apr_1',
            toolCallId: 'call_1',
            toolName: 'mcp.web_search',
            input: {'q': 'hello'},
          ),
        ],
        assistantText: 'ok',
        providerToolCalls: const [
          LLMProviderToolCallPart(
            toolCallId: 'call_1',
            toolName: 'mcp.web_search',
            input: {'q': 'hello'},
            providerExecuted: true,
          ),
        ],
      );

      final parts = Stream<LLMStreamPart>.fromIterable([
        const LLMProviderToolApprovalRequestPart(
          approvalId: 'apr_1',
          toolCallId: 'call_1',
          toolName: 'mcp.web_search',
          input: {'q': 'hello'},
        ),
        LLMProviderToolApprovalBlockedPart(blockedState),
        LLMFinishPart(
          _TestChatResponse(),
          finishReason: const LLMFinishReason(
            unified: LLMUnifiedFinishReason.toolCalls,
            raw: null,
          ),
        ),
      ]);

      final chunks = await uiMessageChunksFromParts(
        parts,
        sendStart: false,
        providerToolApprovalBlockedStateData: (s) => {
          'stepIndex': s.stepIndex,
          'approvalIds': s.approvalRequests.map((r) => r.approvalId).toList(),
        },
      ).toList();

      expect(
        chunks,
        equals([
          const {
            'type': 'tool-approval-request',
            'approvalId': 'apr_1',
            'toolCallId': 'call_1',
          },
          {
            'type': 'data-tool-blocked',
            'data': {
              'kind': 'provider-tool-approval',
              'stepIndex': 0,
              'approvalIds': ['apr_1'],
              'toolCallIds': ['call_1'],
              'extra': {
                'stepIndex': 0,
                'approvalIds': ['apr_1'],
              },
            },
          },
          {
            'type': 'data-tool-approval-blocked',
            'data': {
              'kind': 'provider-tool-approval',
              'stepIndex': 0,
              'approvalIds': ['apr_1'],
              'toolCallIds': ['call_1'],
              'extra': {
                'stepIndex': 0,
                'approvalIds': ['apr_1'],
              },
            },
          },
          const {'type': 'finish', 'finishReason': 'tool-calls'},
        ]),
      );
    });

    test('maps execution-denied tool result to tool-output-denied', () async {
      final parts = Stream<LLMStreamPart>.fromIterable([
        LLMToolResultPart(
          ToolResult.success(
            toolCallId: 'call1',
            result: {'type': 'execution-denied'},
          ),
        ),
        LLMFinishPart(
          _TestChatResponse(),
          finishReason: const LLMFinishReason(
            unified: LLMUnifiedFinishReason.other,
            raw: null,
          ),
        ),
      ]);

      final chunks =
          await uiMessageChunksFromParts(parts, sendStart: false).toList();

      expect(
        chunks,
        equals([
          const {'type': 'tool-output-denied', 'toolCallId': 'call1'},
          const {'type': 'finish', 'finishReason': 'other'},
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

    test('maps provider tool call to tool-input-available', () async {
      final parts = Stream<LLMStreamPart>.fromIterable([
        const LLMProviderToolCallPart(
          toolCallId: 'prov_1',
          toolName: 'web_search',
          input: {'q': 'hello'},
          providerExecuted: true,
          supportsDeferredResults: true,
          isDynamic: false,
          providerMetadata: {
            'openai': {'event': 'response.output_item.added'},
          },
        ),
        LLMFinishPart(_TestChatResponse()),
      ]);

      final chunks =
          await uiMessageChunksFromParts(parts, sendStart: false).toList();

      expect(
        chunks,
        equals([
          {
            'type': 'tool-input-available',
            'toolCallId': 'prov_1',
            'toolName': 'web_search',
            'input': {'q': 'hello'},
            'providerExecuted': true,
            'providerMetadata': {
              'openai': {'event': 'response.output_item.added'},
            },
          },
          const {'type': 'finish'},
        ]),
      );
    });

    test('maps provider tool delta to data-provider-tool-delta', () async {
      final parts = Stream<LLMStreamPart>.fromIterable([
        const LLMProviderToolDeltaPart(
          toolCallId: 'prov_1',
          toolName: 'web_search',
          status: 'in_progress',
          data: {'n': 1},
          providerMetadata: {
            'openai': {'event': 'response.web_search_call.in_progress'},
          },
        ),
        LLMFinishPart(_TestChatResponse()),
      ]);

      final chunks =
          await uiMessageChunksFromParts(parts, sendStart: false).toList();

      expect(
        chunks,
        equals([
          {
            'type': 'data-provider-tool-delta',
            'id': 'prov_1',
            'data': {
              'toolCallId': 'prov_1',
              'toolName': 'web_search',
              'status': 'in_progress',
              'data': {'n': 1},
              'providerMetadata': {
                'openai': {'event': 'response.web_search_call.in_progress'},
              },
            },
          },
          const {'type': 'finish'},
        ]),
      );
    });

    test('maps provider tool result to tool-output-*', () async {
      final parts = Stream<LLMStreamPart>.fromIterable([
        const LLMProviderToolResultPart(
          toolCallId: 'prov_1',
          toolName: 'web_search',
          result: {'sources': []},
          preliminary: true,
          isDynamic: true,
        ),
        const LLMProviderToolResultPart(
          toolCallId: 'prov_2',
          toolName: 'web_search',
          result: {'sources': []},
          isError: true,
        ),
        LLMFinishPart(_TestChatResponse()),
      ]);

      final chunks =
          await uiMessageChunksFromParts(parts, sendStart: false).toList();

      expect(
        chunks,
        equals([
          {
            'type': 'tool-output-available',
            'toolCallId': 'prov_1',
            'output': {'sources': []},
            'providerExecuted': true,
            'dynamic': true,
            'preliminary': true,
          },
          const {
            'type': 'tool-output-error',
            'toolCallId': 'prov_2',
            'errorText': '{"sources":[]}',
            'providerExecuted': true,
          },
          const {'type': 'finish'},
        ]),
      );
    });
  });
}
