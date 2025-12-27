library;

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/core/cancellation.dart';
import 'package:llm_dart_core/core/capability.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_core/models/tool_models.dart';
import 'package:test/test.dart';

class _FakeChatResponse implements ChatResponse {
  @override
  final String? text;

  @override
  final String? thinking;

  @override
  final List<ToolCall>? toolCalls;

  @override
  final UsageInfo? usage;

  final Map<String, dynamic>? _providerMetadata;

  const _FakeChatResponse({
    this.text,
    Map<String, dynamic>? providerMetadata,
  })  : thinking = null,
        toolCalls = null,
        usage = null,
        _providerMetadata = providerMetadata;

  @override
  Map<String, dynamic>? get providerMetadata => _providerMetadata;
}

class _FakeChatModel extends ChatCapability {
  final List<ChatStreamEvent> events;

  _FakeChatModel(this.events);

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    return const _FakeChatResponse(text: 'unused');
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    for (final e in events) {
      yield e;
    }
  }
}

class _SequencedStreamChatModel extends ChatCapability {
  final List<List<ChatStreamEvent>> steps;

  _SequencedStreamChatModel(this.steps);

  var _index = 0;

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) {
    throw UnsupportedError('chatWithTools not used in this test');
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    final events = steps[_index++];
    for (final e in events) {
      yield e;
    }
  }
}

void main() {
  group('Legacy streaming APIs use LLMStreamPart adapters', () {
    test('streamText still emits legacy parts', () async {
      final model = _FakeChatModel([
        const TextDeltaEvent('hi'),
        const CompletionEvent(
          _FakeChatResponse(
            text: 'hi',
            providerMetadata: {
              'openai': {'id': 'resp_1'}
            },
          ),
        ),
      ]);

      final parts = await streamText(
        model: model,
        messages: [ChatMessage.user('x')],
      ).toList();

      expect(parts[0], isA<TextDeltaPart>());
      expect((parts[0] as TextDeltaPart).delta, equals('hi'));
      expect(parts[1], isA<FinishPart>());
      expect((parts[1] as FinishPart).result.providerMetadata, isNotNull);
    });

    test('streamToolLoop still emits legacy parts and finish', () async {
      final model = _SequencedStreamChatModel([
        [
          ToolCallDeltaEvent(
            ToolCall(
              id: 'call_1',
              callType: 'function',
              function: FunctionCall(name: 'ping', arguments: '{}'),
            ),
          ),
          const CompletionEvent(_FakeChatResponse()),
        ],
        [
          const TextDeltaEvent('ok'),
          const CompletionEvent(_FakeChatResponse(text: 'ok')),
        ],
      ]);

      final parts = await streamToolLoop(
        model: model,
        messages: [ChatMessage.user('x')],
        toolHandlers: {'ping': (toolCall, {cancelToken}) => 'pong'},
      ).toList();

      expect(parts.whereType<ToolCallDeltaPart>(), hasLength(1));
      expect(parts.whereType<TextDeltaPart>(), hasLength(1));
      expect(parts.last, isA<FinishPart>());
      expect((parts.last as FinishPart).result.text, equals('ok'));
    });
  });
}
