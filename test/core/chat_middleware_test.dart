// Chat middleware tests (prompt-first) validate logging, defaults, and other
// cross-cutting behavior.

import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';
import '../utils/mock_provider_factory.dart';

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

  @override
  CallMetadata? get callMetadata => null;
}

class _TestChatProvider implements ChatCapability, ProviderCapabilities {
  final LLMConfig config;
  List<ModelMessage> lastMessages = [];
  List<Tool>? lastTools;

  _TestChatProvider(this.config);

  @override
  Future<ChatResponse> chat(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async {
    lastMessages = messages;
    lastTools = tools;
    final text = messages
        .map(
          (message) => message.parts
              .whereType<TextContentPart>()
              .map((part) => part.text)
              .join(),
        )
        .join('|');
    return _TestChatResponse(text);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async* {
    lastMessages = messages;
    lastTools = tools;
    yield const TextDeltaEvent('base');
  }

  @override
  Set<LLMCapability> get supportedCapabilities =>
      {LLMCapability.chat, LLMCapability.streaming};

  @override
  bool supports(LLMCapability capability) =>
      supportedCapabilities.contains(capability);
}

void main() {
  group('ChatMiddleware', () {
    setUp(() {
      // Ensure the test provider factory is registered.
      LLMProviderRegistry.registerOrReplace(
        MockProviderFactory<ChatCapability>(
          providerId: 'test-middleware-provider',
          supportedCapabilities: {
            LLMCapability.chat,
            LLMCapability.streaming,
          },
          create: (config) => _TestChatProvider(config),
        ),
      );
    });

    test('transform chain is applied in order for chat', () async {
      final transforms = <String>[];

      final provider =
          await ai().provider('test-middleware-provider').middlewares([
        ChatMiddleware(
          transform: (ctx) async {
            expect(ctx.operationKind, ChatOperationKind.chat);
            transforms.add('t1');
            final updatedMessages = [
              ...ctx.messages,
              ModelMessage.userText('t1'),
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
              ModelMessage.userText('t2'),
            ];
            return ctx.copyWith(messages: updatedMessages);
          },
        ),
      ]).buildWithMiddleware();

      final response =
          await provider.chat([ModelMessage.userText('base')]) as _TestChatResponse;

      expect(transforms, ['t1', 't2']);
      expect(response.text, 'base|t1|t2');
    });

    test('wrapChat middlewares wrap in correct order', () async {
      final provider =
          await ai().provider('test-middleware-provider').middlewares([
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
          await provider.chat([ModelMessage.userText('base')]) as _TestChatResponse;

      // The outer middleware appears earlier in the list, so the final result
      // should be M1(M2(base)).
      expect(response.text, 'M1(M2(base))');
    });

    test('wrapStream middlewares wrap in correct order', () async {
      final provider =
          await ai().provider('test-middleware-provider').middlewares([
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
          await provider.chatStream([ModelMessage.userText('base')]).toList();

      expect(events.length, 1);
      final event = events.first as TextDeltaEvent;
      // The outer S1 wrapper should be applied last: S1(S2(base)).
      expect(event.delta, 'S1(S2(base))');
    });

    test('transform receives correct operationKind for stream', () async {
      final kinds = <ChatOperationKind>[];

      final provider =
          await ai().provider('test-middleware-provider').middlewares([
        ChatMiddleware(
          transform: (ctx) async {
            kinds.add(ctx.operationKind);
            return ctx;
          },
        ),
      ]).buildWithMiddleware();

      await provider.chat([ModelMessage.userText('base')]);
      await provider.chatStream([ModelMessage.userText('base')]).toList();

      expect(kinds, [ChatOperationKind.chat, ChatOperationKind.stream]);
    });
  });
}
