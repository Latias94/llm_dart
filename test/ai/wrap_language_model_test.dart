import 'dart:async';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

class _CapturingCallOptionsChatModel extends ChatCapability
    implements ChatCallOptionsCapability {
  LLMCallOptions? lastCallOptions;
  List<ChatMessage>? lastMessages;

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) {
    throw StateError('chatWithTools should not be used in this test.');
  }

  @override
  Future<ChatResponse> chatWithToolsWithCallOptions(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    List<ProviderTool>? providerTools,
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) async {
    lastMessages = messages;
    lastCallOptions = callOptions;
    return _TestChatResponse(text: 'ok');
  }
}

class _BasicChatModel extends ChatCapability {
  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) async {
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

void main() {
  group('wrapLanguageModel (default call options)', () {
    test('applies defaults on chatWithTools', () async {
      final inner = _CapturingCallOptionsChatModel();
      final wrapped = wrapLanguageModel(
        inner,
        defaultCallOptions: const LLMCallOptions(
          headers: {'X-Test': 'a'},
          body: {'a': 1},
        ),
      );

      final response = await wrapped.chatWithTools(
        [ChatMessage.user('hi')],
        null,
      );

      expect(response.text, equals('ok'));
      expect(inner.lastCallOptions, isNotNull);
      expect(inner.lastCallOptions!.headers, equals({'X-Test': 'a'}));
      expect(inner.lastCallOptions!.body, equals({'a': 1}));
    });

    test('merges defaults + per-call overrides (case-insensitive headers)', () async {
      final inner = _CapturingCallOptionsChatModel();
      final wrapped = wrapLanguageModel(
        inner,
        defaultCallOptions: const LLMCallOptions(
          headers: {'X-Test': 'a', 'X-Other': '1'},
          body: {
            'a': {'b': 1, 'c': 2},
            'k': 1,
          },
        ),
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
          'k': 1,
        }),
      );
    });

    test('throws when defaults require callOptions but model does not support them',
        () async {
      final wrapped = wrapLanguageModel(
        _BasicChatModel(),
        defaultCallOptions: const LLMCallOptions(headers: {'X-Test': 'a'}),
      );

      expect(
        () => wrapped.chatWithTools([ChatMessage.user('hi')], null),
        throwsA(isA<InvalidRequestError>()),
      );
    });
  });
}
