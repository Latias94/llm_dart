import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

class _TestEmbeddingProvider
    implements ChatCapability, EmbeddingCapability, ProviderCapabilities {
  final LLMConfig config;
  List<String> lastInput = [];

  _TestEmbeddingProvider(this.config);

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async {
    // Minimal implementation for factory compatibility; not used in tests.
    return const _DummyChatResponse();
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) =>
      chat(
        messages,
        options: options,
        cancelToken: cancelToken,
      );

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async* {
    yield const TextDeltaEvent('unused');
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async => null;

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async =>
      'summary';

  @override
  Future<List<List<double>>> embed(
    List<String> input, {
    CancellationToken? cancelToken,
  }) async {
    lastInput = List<String>.from(input);
    // Simple embedding: each text length as a single-dimension vector.
    return input.map((s) => <double>[s.length.toDouble()]).toList();
  }

  @override
  Set<LLMCapability> get supportedCapabilities =>
      {LLMCapability.chat, LLMCapability.embedding};

  @override
  bool supports(LLMCapability capability) =>
      supportedCapabilities.contains(capability);
}

class _TestEmbeddingProviderFactory extends LLMProviderFactory<ChatCapability> {
  @override
  String get providerId => 'test-embedding-provider';

  @override
  Set<LLMCapability> get supportedCapabilities =>
      {LLMCapability.chat, LLMCapability.embedding};

  @override
  ChatCapability create(LLMConfig config) => _TestEmbeddingProvider(config);

  @override
  bool validateConfig(LLMConfig config) => true;

  @override
  LLMConfig getDefaultConfig() =>
      LLMConfig(baseUrl: 'http://localhost', model: 'test-embed-model');
}

class _DummyChatResponse implements ChatResponse {
  const _DummyChatResponse();

  @override
  String? get text => '';

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

void main() {
  group('EmbeddingMiddleware', () {
    setUp(() {
      LLMProviderRegistry.registerOrReplace(_TestEmbeddingProviderFactory());
    });

    test('transform chain is applied in order for embed', () async {
      final transforms = <String>[];

      final builder = ai().provider('test-embedding-provider');

      final embedProvider = await builder.embeddingMiddlewares([
        EmbeddingMiddleware(
          transform: (ctx) async {
            transforms.add('t1');
            final updatedInput =
                ctx.input.map((s) => '$s:t1').toList(growable: false);
            return ctx.copyWith(input: updatedInput);
          },
        ),
        EmbeddingMiddleware(
          transform: (ctx) async {
            transforms.add('t2');
            final updatedInput =
                ctx.input.map((s) => '$s:t2').toList(growable: false);
            return ctx.copyWith(input: updatedInput);
          },
        ),
      ]).buildEmbeddingWithMiddleware();

      // We can't downcast to the internal wrapper type, but we can
      // retrieve the underlying test provider via the global registry.
      await embedProvider.embed(['a', 'bb']);

      // We can only assert the transform call order, which guarantees that
      // the chaining execution order is correct.
      expect(transforms, ['t1', 't2']);
    });

    test('wrapEmbed middlewares wrap in correct order', () async {
      final builder = ai().provider('test-embedding-provider');

      final embedProvider = await builder.embeddingMiddlewares([
        // Outer wrapper multiplies by 10
        EmbeddingMiddleware(
          wrapEmbed: (next, ctx) async {
            final base = await next(ctx);
            return base.map((v) => v.map((x) => x * 10).toList()).toList();
          },
        ),
        // Inner wrapper adds 1
        EmbeddingMiddleware(
          wrapEmbed: (next, ctx) async {
            final base = await next(ctx);
            return base.map((v) => v.map((x) => x + 1).toList()).toList();
          },
        ),
      ]).buildEmbeddingWithMiddleware();

      final result = await embedProvider.embed(['x']);

      // base length = 1, inner +1 => 2, outer *10 => 20
      expect(result.length, 1);
      expect(result.first.length, 1);
      expect(result.first.first, 20.0);
    });

    test('EmbeddingCallContext contains providerId, model and config',
        () async {
      EmbeddingCallContext? seenContext;

      final builder = ai().provider('test-embedding-provider').model('m-test');

      final embedProvider = await builder.embeddingMiddlewares([
        EmbeddingMiddleware(
          transform: (ctx) async {
            seenContext = ctx;
            return ctx;
          },
        ),
      ]).buildEmbeddingWithMiddleware();

      await embedProvider.embed(['hello']);

      expect(seenContext, isNotNull);
      expect(seenContext!.providerId, 'test-embedding-provider');
      expect(seenContext!.model, 'm-test');
      expect(seenContext!.config.model, 'm-test');
      expect(seenContext!.input, ['hello']);
    });
  });
}
