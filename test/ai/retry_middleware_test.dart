import 'dart:async';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

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

class _FlakyChatModel extends ChatCapability
    implements ChatCallOptionsCapability, ChatStreamPartsCallOptionsCapability {
  int chatAttempts = 0;
  int streamAttempts = 0;
  int failTimes;
  final LLMError error;

  _FlakyChatModel({
    required this.failTimes,
    required this.error,
  });

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
    chatAttempts++;
    if (chatAttempts <= failTimes) {
      throw error;
    }
    return _TestChatResponse(text: 'ok');
  }

  @override
  Stream<LLMStreamPart> chatStreamPartsWithCallOptions(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) async* {
    streamAttempts++;
    if (streamAttempts <= failTimes) {
      throw error;
    }
    yield const LLMTextDeltaPart('hi');
    yield LLMFinishPart(_TestChatResponse(text: 'hi'));
  }
}

class _FlakyStreamErrorPartModel extends ChatCapability
    implements ChatStreamPartsCallOptionsCapability, ChatCallOptionsCapability {
  int streamAttempts = 0;
  int failTimes;
  final LLMError error;

  _FlakyStreamErrorPartModel({
    required this.failTimes,
    required this.error,
  });

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
    streamAttempts++;
    if (streamAttempts <= failTimes) {
      yield LLMErrorPart(error);
      return;
    }
    yield const LLMTextDeltaPart('hi');
    yield LLMFinishPart(_TestChatResponse(text: 'hi'));
  }
}

void main() {
  group('RetryMiddleware', () {
    test('retries transient chat errors and succeeds', () async {
      final delays = <Duration>[];
      final inner = _FlakyChatModel(
        failTimes: 2,
        error: const TimeoutError('timeout'),
      );

      final wrapped = wrapLanguageModelWithMiddleware(
        inner,
        middlewares: [
          RetryMiddleware(
            maxRetries: 3,
            sleep: (d) async => delays.add(d),
          ),
        ],
      ) as ChatCallOptionsCapability;

      final response = await wrapped.chatWithToolsWithCallOptions(
        [ChatMessage.user('hi')],
        null,
        callOptions: const LLMCallOptions(headers: {'X-Test': 'a'}),
      );

      expect(response.text, equals('ok'));
      expect(inner.chatAttempts, equals(3));
      expect(delays.length, equals(2));
    });

    test('does not retry non-retriable errors', () async {
      final inner = _FlakyChatModel(
        failTimes: 1,
        error: const InvalidRequestError('bad request'),
      );

      final wrapped = wrapLanguageModelWithMiddleware(
        inner,
        middlewares: [
          RetryMiddleware(
            maxRetries: 3,
            sleep: (_) async {},
          ),
        ],
      ) as ChatCallOptionsCapability;

      expect(
        () => wrapped.chatWithToolsWithCallOptions(
          [ChatMessage.user('hi')],
          null,
          callOptions: const LLMCallOptions(headers: {'X-Test': 'a'}),
        ),
        throwsA(isA<InvalidRequestError>()),
      );

      expect(inner.chatAttempts, equals(1));
    });

    test('retries streaming only before any parts are emitted', () async {
      final delays = <Duration>[];
      final inner = _FlakyChatModel(
        failTimes: 2,
        error: const ServerError('oops', statusCode: 500),
      );

      final wrapped = wrapLanguageModelWithMiddleware(
        inner,
        middlewares: [
          RetryMiddleware(
            maxRetries: 3,
            sleep: (d) async => delays.add(d),
          ),
        ],
      ) as ChatStreamPartsCallOptionsCapability;

      final parts = await wrapped.chatStreamPartsWithCallOptions(
        [ChatMessage.user('hi')],
        callOptions: const LLMCallOptions(headers: {'X-Test': 'a'}),
      ).toList();

      expect(inner.streamAttempts, equals(3));
      expect(parts.whereType<LLMTextDeltaPart>(), hasLength(1));
      expect(parts.whereType<LLMFinishPart>(), hasLength(1));
      expect(delays.length, equals(2));
    });

    test('retries streaming when first part is LLMErrorPart', () async {
      final delays = <Duration>[];
      final inner = _FlakyStreamErrorPartModel(
        failTimes: 2,
        error: const TimeoutError('timeout'),
      );

      final wrapped = wrapLanguageModelWithMiddleware(
        inner,
        middlewares: [
          RetryMiddleware(
            maxRetries: 3,
            sleep: (d) async => delays.add(d),
          ),
        ],
      ) as ChatStreamPartsCallOptionsCapability;

      final parts = await wrapped.chatStreamPartsWithCallOptions(
        [ChatMessage.user('hi')],
        callOptions: const LLMCallOptions(headers: {'X-Test': 'a'}),
      ).toList();

      expect(inner.streamAttempts, equals(3));
      expect(parts.whereType<LLMErrorPart>(), isEmpty);
      expect(parts.whereType<LLMTextDeltaPart>(), hasLength(1));
      expect(parts.whereType<LLMFinishPart>(), hasLength(1));
      expect(delays.length, equals(2));
    });

    test('cancels during backoff sleep', () async {
      final sleepCalled = Completer<void>();
      final sleepCompleter = Completer<void>();

      final inner = _FlakyChatModel(
        failTimes: 100,
        error: const TimeoutError('timeout'),
      );

      final wrapped = wrapLanguageModelWithMiddleware(
        inner,
        middlewares: [
          RetryMiddleware(
            maxRetries: 3,
            sleep: (_) async {
              if (!sleepCalled.isCompleted) sleepCalled.complete();
              return sleepCompleter.future;
            },
          ),
        ],
      ) as ChatCallOptionsCapability;

      final token = CancelToken();

      final future = wrapped.chatWithToolsWithCallOptions(
        [ChatMessage.user('hi')],
        null,
        callOptions: const LLMCallOptions(headers: {'X-Test': 'a'}),
        cancelToken: token,
      );

      await sleepCalled.future;
      token.cancel('stop');

      await expectLater(
        future,
        throwsA(isA<CancelledError>()),
      );
    });
  });
}
