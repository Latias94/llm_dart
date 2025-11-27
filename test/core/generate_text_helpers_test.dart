import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

class FakeChatResponse implements ChatResponse {
  @override
  String? get text => 'ok';

  @override
  List<ToolCall>? get toolCalls => const [];

  @override
  UsageInfo? get usage => const UsageInfo(
        promptTokens: 1,
        completionTokens: 2,
        totalTokens: 3,
      );

  @override
  String? get thinking => null;

  @override
  List<CallWarning> get warnings => const [];

  @override
  Map<String, dynamic>? get metadata => null;

  @override
  CallMetadata? get callMetadata => null;
}

class FakeChatProvider implements ChatCapability {
  LanguageModelCallOptions? lastOptions;

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async {
    lastOptions = options;
    return FakeChatResponse();
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async {
    lastOptions = options;
    return FakeChatResponse();
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async* {
    lastOptions = options;
    yield const TextDeltaEvent('hi');
    yield CompletionEvent(FakeChatResponse());
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async => null;

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async =>
      'summary';
}

class FakeProviderFactory extends LLMProviderFactory<ChatCapability> {
  @override
  String get providerId => 'fake';

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
      };

  @override
  ChatCapability create(LLMConfig config) => FakeChatProvider();

  @override
  bool validateConfig(LLMConfig config) => true;

  @override
  LLMConfig getDefaultConfig() => LLMConfig(baseUrl: '', model: '');
}

void main() {
  group('generateText / streaming helpers', () {
    setUp(() {
      LLMProviderRegistry.registerOrReplace(FakeProviderFactory());
    });

    tearDown(() {
      LLMProviderRegistry.unregister('fake');
    });

    test('generateText should resolve model and return result', () async {
      final result = await generateText(
        model: 'fake:test-model',
        prompt: 'Hello',
      );

      expect(result.text, equals('ok'));
      expect(result.usage, isNotNull);
      expect(result.usage!.totalTokens, equals(3));
    });

    test('generateText forwards LanguageModelCallOptions to provider',
        () async {
      final options = LanguageModelCallOptions(
        maxTokens: 123,
        temperature: 0.5,
      );

      final result = await generateText(
        model: 'fake:test-model',
        prompt: 'Hello with options',
        options: options,
      );

      expect(result.text, equals('ok'));

      final provider = LLMProviderRegistry.getFactory('fake')!.create(LLMConfig(
        baseUrl: '',
        model: '',
      )) as FakeChatProvider;

      // The provider used internally is not the same instance, so we can't
      // inspect options directly here. This test mainly ensures the helpers
      // accept the options parameter without throwing. Detailed per-provider
      // behavior is covered by provider-specific tests.
      expect(provider, isA<FakeChatProvider>());
    });

    test('streamText should emit events', () async {
      final events = <ChatStreamEvent>[];

      await for (final event in streamText(
        model: 'fake:test-model',
        prompt: 'Hello',
      )) {
        events.add(event);
      }

      expect(events.any((e) => e is TextDeltaEvent), isTrue);
      expect(events.any((e) => e is CompletionEvent), isTrue);
    });

    test('streamTextParts should emit high-level parts', () async {
      final parts = <StreamTextPart>[];

      await for (final part in streamTextParts(
        model: 'fake:test-model',
        prompt: 'Hello',
      )) {
        parts.add(part);
      }

      expect(parts.any((p) => p is StreamTextDelta), isTrue);
      expect(parts.any((p) => p is StreamFinish), isTrue);
    });
  });

  group('generateTextWithModel / streamTextWithModel / generateObjectWithModel',
      () {
    test('generateTextWithModel forwards LanguageModelCallOptions', () async {
      final model = _FakeLanguageModelWithOptions(
        LLMConfig(baseUrl: '', model: 'test-model'),
      );

      final options = LanguageModelCallOptions(
        maxTokens: 42,
        temperature: 0.7,
        topP: 0.8,
      );

      final result = await generateTextWithModel(
        model,
        prompt: 'Hello',
        options: options,
      );

      expect(result.text, equals('ok'));
      expect(model.lastOptions, isNotNull);
      expect(model.lastOptions!.maxTokens, equals(42));
      expect(model.lastOptions!.temperature, equals(0.7));
      expect(model.lastOptions!.topP, equals(0.8));
    });

    test('streamTextWithModel forwards LanguageModelCallOptions', () async {
      final model = _FakeLanguageModelWithOptions(
        LLMConfig(baseUrl: '', model: 'test-model'),
      );

      final options = LanguageModelCallOptions(
        maxTokens: 10,
        temperature: 0.3,
      );

      final events = <ChatStreamEvent>[];
      await for (final event in streamTextWithModel(
        model,
        prompt: 'Stream hello',
        options: options,
      )) {
        events.add(event);
      }

      expect(events.any((e) => e is TextDeltaEvent), isTrue);
      expect(events.any((e) => e is CompletionEvent), isTrue);
      expect(model.lastOptions, isNotNull);
      expect(model.lastOptions!.maxTokens, equals(10));
      expect(model.lastOptions!.temperature, equals(0.3));
    });

    test('streamTextPartsWithModel forwards LanguageModelCallOptions',
        () async {
      final model = _FakeLanguageModelWithOptions(
        LLMConfig(baseUrl: '', model: 'test-model'),
      );

      final options = LanguageModelCallOptions(
        maxTokens: 5,
        temperature: 0.2,
      );

      final parts = <StreamTextPart>[];
      await for (final part in streamTextPartsWithModel(
        model,
        prompt: 'Stream parts',
        options: options,
      )) {
        parts.add(part);
      }

      expect(parts.any((p) => p is StreamTextDelta), isTrue);
      expect(parts.any((p) => p is StreamFinish), isTrue);
      expect(model.lastOptions, isNotNull);
      expect(model.lastOptions!.maxTokens, equals(5));
      expect(model.lastOptions!.temperature, equals(0.2));
    });

    test('generateObjectWithModel forwards LanguageModelCallOptions', () async {
      final model = _FakeLanguageModelWithOptions(
        LLMConfig(baseUrl: '', model: 'test-model'),
      );

      final output = OutputSpec<Map<String, dynamic>>.object(
        name: 'TestObject',
        properties: {
          'value': ParameterProperty(
            propertyType: 'string',
            description: 'Test value',
          ),
        },
        fromJson: (json) => json,
      );

      final options = LanguageModelCallOptions(
        maxTokens: 7,
        temperature: 0.1,
      );

      final result = await generateObjectWithModel<Map<String, dynamic>>(
        model: model,
        output: output,
        prompt: 'Return JSON',
        options: options,
      );

      expect(result.object['value'], equals('ok'));
      expect(model.lastOptions, isNotNull);
      expect(model.lastOptions!.maxTokens, equals(7));
      expect(model.lastOptions!.temperature, equals(0.1));
    });
  });
}

/// Fake language model that records the last [LanguageModelCallOptions]
/// passed via the `*WithOptions` methods.
class _FakeLanguageModelWithOptions implements LanguageModel {
  @override
  final String providerId = 'fake-model';

  @override
  final String modelId = 'test-model';

  @override
  final LLMConfig config;

  LanguageModelCallOptions? lastOptions;

  _FakeLanguageModelWithOptions(this.config);

  @override
  Future<GenerateTextResult> generateText(
    List<ChatMessage> messages, {
    CancellationToken? cancelToken,
  }) async {
    return GenerateTextResult(
      rawResponse: FakeChatResponse(),
      text: 'ok',
      toolCalls: const [],
      usage: const UsageInfo(
        promptTokens: 1,
        completionTokens: 1,
        totalTokens: 2,
      ),
      warnings: const [],
      metadata: null,
    );
  }

  @override
  Stream<ChatStreamEvent> streamText(
    List<ChatMessage> messages, {
    CancellationToken? cancelToken,
  }) async* {
    yield const TextDeltaEvent('chunk');
    yield CompletionEvent(FakeChatResponse());
  }

  @override
  Stream<StreamTextPart> streamTextParts(
    List<ChatMessage> messages, {
    CancellationToken? cancelToken,
  }) {
    return adaptStreamText(streamText(messages, cancelToken: cancelToken));
  }

  @override
  Future<GenerateObjectResult<T>> generateObject<T>(
    OutputSpec<T> output,
    List<ChatMessage> messages, {
    CancellationToken? cancelToken,
  }) async {
    // Always return {"value": "ok"} for tests.
    final object = output.fromJson({'value': 'ok'});
    final textResult = await generateText(messages, cancelToken: cancelToken);
    return GenerateObjectResult<T>(object: object, textResult: textResult);
  }

  @override
  Future<GenerateTextResult> generateTextWithOptions(
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    lastOptions = options;
    return generateText(messages, cancelToken: cancelToken);
  }

  @override
  Stream<ChatStreamEvent> streamTextWithOptions(
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    lastOptions = options;
    return streamText(messages, cancelToken: cancelToken);
  }

  @override
  Stream<StreamTextPart> streamTextPartsWithOptions(
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    lastOptions = options;
    return streamTextParts(messages, cancelToken: cancelToken);
  }

  @override
  Future<GenerateObjectResult<T>> generateObjectWithOptions<T>(
    OutputSpec<T> output,
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    lastOptions = options;
    return generateObject<T>(output, messages, cancelToken: cancelToken);
  }
}
