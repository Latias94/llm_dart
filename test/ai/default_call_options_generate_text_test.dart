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

void main() {
  group('generateText defaultCallOptions', () {
    test('uses defaultCallOptions when per-call callOptions is empty', () async {
      final model = _CapturingCallOptionsChatModel();

      final result = await generateText(
        model: model,
        prompt: 'hi',
        defaultCallOptions: const LLMCallOptions(
          headers: {'X-Test': 'a'},
          body: {'a': 1},
        ),
      );

      expect(result.text, equals('ok'));
      expect(model.lastCallOptions, isNotNull);
      expect(model.lastCallOptions!.headers, equals({'X-Test': 'a'}));
      expect(model.lastCallOptions!.body, equals({'a': 1}));
    });

    test('merges defaultCallOptions + callOptions (case-insensitive headers)',
        () async {
      final model = _CapturingCallOptionsChatModel();

      await generateText(
        model: model,
        prompt: 'hi',
        defaultCallOptions: const LLMCallOptions(
          headers: {'X-Test': 'a', 'X-Other': '1'},
          body: {
            'a': {'b': 1, 'c': 2},
          },
        ),
        callOptions: const LLMCallOptions(
          headers: {'x-test': 'b'},
          body: {
            'a': {'b': 9},
          },
        ),
      );

      final effective = model.lastCallOptions!;
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
  });
}
