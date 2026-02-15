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

class _CallOptionsChatModel extends ChatCapability
    implements ChatCallOptionsCapability, ChatStreamPartsCallOptionsCapability {
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
    return _TestChatResponse(text: 'ok');
  }

  @override
  Stream<LLMStreamPart> chatStreamPartsWithCallOptions(
    List<ChatMessage> messages, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) async* {
    yield const LLMTextDeltaPart('hi');
    yield LLMFinishPart(_TestChatResponse(text: 'hi'));
  }
}

void main() {
  group('TelemetryMiddleware', () {
    test('emits start + finish for chat without leaking header values',
        () async {
      final events = <LanguageModelTelemetryEvent>[];
      final model = wrapLanguageModelWithMiddleware(
        _CallOptionsChatModel(),
        middlewares: [
          const DefaultCallOptionsMiddleware(
            LLMCallOptions(headers: {'Authorization': 'secret'}),
          ),
          TelemetryMiddleware(onEvent: events.add),
        ],
      ) as ChatCallOptionsCapability;

      await model.chatWithToolsWithCallOptions(
        [ChatMessage.user('hi')],
        null,
        callOptions: const LLMCallOptions(headers: {'X-Test': 'a'}),
      );

      expect(events.whereType<LanguageModelChatStartEvent>(), hasLength(1));
      expect(events.whereType<LanguageModelChatFinishEvent>(), hasLength(1));

      final start = events.whereType<LanguageModelChatStartEvent>().single;
      expect(start.callOptions.headerNamesLower, contains('authorization'));
      expect(start.callOptions.headerNamesLower, contains('x-test'));
      expect(
        start.callOptions.headerNamesLower.join(','),
        isNot(contains('secret')),
      );
    });

    test('emits part events + finish for streaming', () async {
      final events = <LanguageModelTelemetryEvent>[];
      final model = wrapLanguageModelWithMiddleware(
        _CallOptionsChatModel(),
        middlewares: [
          const DefaultCallOptionsMiddleware(
            LLMCallOptions(headers: {'X-Test': 'a'}),
          ),
          TelemetryMiddleware(onEvent: events.add),
        ],
      ) as ChatStreamPartsCallOptionsCapability;

      await model.chatStreamPartsWithCallOptions(
        [ChatMessage.user('hi')],
        callOptions: const LLMCallOptions(),
      ).toList();

      expect(events.whereType<LanguageModelStreamStartEvent>(), hasLength(1));
      expect(events.whereType<LanguageModelStreamPartEvent>().length,
          greaterThanOrEqualTo(2));
      expect(events.whereType<LanguageModelStreamFinishEvent>(), hasLength(1));
    });
  });
}
