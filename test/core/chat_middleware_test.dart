import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

class _TestChatResponse implements ChatResponse {
  final String _text;

  _TestChatResponse(this._text);

  @override
  String? get text => _text;

  @override
  List<ToolCall>? get toolCalls => null;

  @override
  UsageInfo? get usage => null;

   @override
   String? get thinking => null;

   @override
   List<CallWarning> get warnings => const [];

   @override
   Map<String, dynamic>? get metadata => null;
}

class _TestChatProvider implements ChatCapability, ProviderCapabilities {
  final LLMConfig config;
  List<ChatMessage> lastMessages = [];
  List<Tool>? lastTools;

  _TestChatProvider(this.config);

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  }) {
    return chatWithTools(messages, null, cancelToken: cancelToken);
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    lastMessages = messages;
    lastTools = tools;
    final text = messages.map((m) => m.content).join('|');
    return _TestChatResponse(text);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    lastMessages = messages;
    lastTools = tools;
    yield const TextDeltaEvent('base');
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async => null;

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async =>
      'summary';

  @override
  Set<LLMCapability> get supportedCapabilities =>
      {LLMCapability.chat, LLMCapability.streaming};

  @override
  bool supports(LLMCapability capability) =>
      supportedCapabilities.contains(capability);
}

class _TestProviderFactory extends LLMProviderFactory<ChatCapability> {
  @override
  String get providerId => 'test-middleware-provider';

  @override
  Set<LLMCapability> get supportedCapabilities =>
      {LLMCapability.chat, LLMCapability.streaming};

  @override
  ChatCapability create(LLMConfig config) => _TestChatProvider(config);

  @override
  bool validateConfig(LLMConfig config) => true;

  @override
  LLMConfig getDefaultConfig() =>
      LLMConfig(baseUrl: 'http://localhost', model: 'test-model');
}

void main() {
  group('ChatMiddleware', () {
    setUp(() {
      // Ensure the test provider factory is registered.
      LLMProviderRegistry.registerOrReplace(_TestProviderFactory());
    });

    test('transform chain is applied in order for chat', () async {
      final transforms = <String>[];

      final provider = await ai()
          .provider('test-middleware-provider')
          .middlewares([
        ChatMiddleware(
          transform: (ctx) async {
            expect(ctx.operationKind, ChatOperationKind.chat);
            transforms.add('t1');
            final updatedMessages = [
              ...ctx.messages,
              ChatMessage.user('t1'),
            ];
            return ctx.copyWith(messages: updatedMessages);
          },
        ),
        ChatMiddleware(
          transform: (ctx) async {
            expect(ctx.operationKind, ChatOperationKind.chat);
            transforms.add('t2');
            final updatedMessages = [
              ...ctx.messages,
              ChatMessage.user('t2'),
            ];
            return ctx.copyWith(messages: updatedMessages);
          },
        ),
      ]).buildWithMiddleware();

      final response =
          await provider.chat([ChatMessage.user('base')]) as _TestChatResponse;

      expect(transforms, ['t1', 't2']);
      expect(response.text, 'base|t1|t2');
    });

    test('wrapChat middlewares wrap in correct order', () async {
      final provider = await ai()
          .provider('test-middleware-provider')
          .middlewares([
        ChatMiddleware(
          wrapChat: (next, ctx) async {
            final res = await next(ctx);
            return _TestChatResponse('M1(${res.text})');
          },
        ),
        ChatMiddleware(
          wrapChat: (next, ctx) async {
            final res = await next(ctx);
            return _TestChatResponse('M2(${res.text})');
          },
        ),
      ]).buildWithMiddleware();

      final response =
          await provider.chat([ChatMessage.user('base')]) as _TestChatResponse;

      // 外层中间件在列表前面，结果应该是 M1(M2(base))
      expect(response.text, 'M1(M2(base))');
    });

    test('wrapStream middlewares wrap in correct order', () async {
      final provider = await ai()
          .provider('test-middleware-provider')
          .middlewares([
        ChatMiddleware(
          wrapStream: (next, ctx) {
            final base = next(ctx);
            return base.map((event) {
              if (event is TextDeltaEvent) {
                return TextDeltaEvent('S1(${event.delta})');
              }
              return event;
            });
          },
        ),
        ChatMiddleware(
          wrapStream: (next, ctx) {
            final base = next(ctx);
            return base.map((event) {
              if (event is TextDeltaEvent) {
                return TextDeltaEvent('S2(${event.delta})');
              }
              return event;
            });
          },
        ),
      ]).buildWithMiddleware();

      final events =
          await provider.chatStream([ChatMessage.user('base')]).toList();

      expect(events.length, 1);
      final event = events.first as TextDeltaEvent;
      // 外层 S1 包在最外面：S1(S2(base))
      expect(event.delta, 'S1(S2(base))');
    });

    test('transform receives correct operationKind for stream', () async {
      final kinds = <ChatOperationKind>[];

      final provider = await ai()
          .provider('test-middleware-provider')
          .middlewares([
        ChatMiddleware(
          transform: (ctx) async {
            kinds.add(ctx.operationKind);
            return ctx;
          },
        ),
      ]).buildWithMiddleware();

      await provider.chat([ChatMessage.user('base')]);
      await provider.chatStream([ChatMessage.user('base')]).toList();

      expect(kinds, [ChatOperationKind.chat, ChatOperationKind.stream]);
    });
  });
}
