import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

class _CapturingCallOptionsChatModel extends ChatCapability
    implements ChatCallOptionsCapability {
  LLMCallOptions? lastCallOptions;

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) {
    throw StateError('chatWithTools should not be used in this test.');
  }

  @override
  Future<ChatResponse> chatWithToolsWithCallOptions(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) async {
    lastCallOptions = callOptions;
    return _TestChatResponse(text: 'ok');
  }
}

class _TestChatResponse extends ChatResponse {
  @override
  final String? text;

  @override
  List<ToolCall>? get toolCalls => null;

  @override
  UsageInfo? get usage => null;

  @override
  Map<String, dynamic>? get providerMetadata => null;

  _TestChatResponse({this.text});
}

class _CapturingCallOptionsStreamModel extends ChatCapability
    implements ChatStreamPartsCallOptionsCapability, ChatCallOptionsCapability {
  LLMCallOptions? lastStreamCallOptions;

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) {
    throw StateError('chatWithTools should not be used in this test.');
  }

  @override
  Future<ChatResponse> chatWithToolsWithCallOptions(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) async {
    return _TestChatResponse(text: 'ok');
  }

  @override
  Stream<LLMStreamPart> chatStreamPartsWithCallOptions(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) async* {
    lastStreamCallOptions = callOptions;
    yield const LLMTextDeltaPart('hi');
    yield LLMFinishPart(_TestChatResponse(text: 'hi'));
  }
}

void main() {
  group('LanguageModelMiddleware', () {
    test('DefaultCallOptionsMiddleware merges call options', () async {
      final inner = _CapturingCallOptionsChatModel();
      final wrapped = wrapLanguageModelWithMiddleware(
        inner,
        middlewares: const [
          DefaultCallOptionsMiddleware(
            LLMCallOptions(
              headers: {'X-Test': 'a', 'X-Other': '1'},
              body: {
                'a': {'b': 1, 'c': 2},
              },
            ),
          ),
        ],
      ) as ChatCallOptionsCapability;

      await wrapped.chatWithToolsWithCallOptions(
        [ChatMessage.user('hi')],
        null,
        callOptions: const LLMCallOptions(
          headers: {'x-test': 'b'},
          body: {
            'a': {'b': 9},
          },
        ),
      );

      final effective = inner.lastCallOptions!;
      expect(effective.headers!.length, equals(2));
      expect(effective.headers!['x-test'], equals('b'));
      expect(effective.headers!.containsKey('X-Test'), isFalse);
      expect(effective.headers!['X-Other'], equals('1'));
      expect(
        effective.body,
        equals({
          'a': {'b': 9, 'c': 2},
        }),
      );
    });

    test('DefaultCallOptionsMiddleware applies to streaming', () async {
      final inner = _CapturingCallOptionsStreamModel();
      final wrapped = wrapLanguageModelWithMiddleware(
        inner,
        middlewares: const [
          DefaultCallOptionsMiddleware(
            LLMCallOptions(headers: {'X-Test': 'a'}),
          ),
        ],
      ) as ChatStreamPartsCallOptionsCapability;

      await wrapped
          .chatStreamPartsWithCallOptions(
            [ChatMessage.user('hi')],
            callOptions: const LLMCallOptions(headers: {'x-test': 'b'}),
          )
          .toList();

      final effective = inner.lastStreamCallOptions!;
      expect(effective.headers, equals({'x-test': 'b'}));
    });
  });
}
