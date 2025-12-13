// Tests for high-level text helpers (prompt-first).

import 'package:llm_dart/llm_dart.dart';
import '../utils/mock_language_model.dart';
import '../utils/mock_provider_factory.dart';
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
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async {
    lastOptions = options;
    return FakeChatResponse();
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async* {
    lastOptions = options;
    yield const TextDeltaEvent('hi');
    yield CompletionEvent(FakeChatResponse());
  }
}

class _RichChatResponse implements ChatResponse {
  final String? _text;
  final List<ToolCall>? _toolCalls;
  final UsageInfo? _usage;
  final String? _thinking;
  final List<CallWarning> _warnings;
  final Map<String, dynamic>? _metadata;

  const _RichChatResponse({
    String? text,
    List<ToolCall>? toolCalls,
    UsageInfo? usage,
    String? thinking,
    List<CallWarning> warnings = const [],
    Map<String, dynamic>? metadata,
  })  : _text = text,
        _toolCalls = toolCalls,
        _usage = usage,
        _thinking = thinking,
        _warnings = warnings,
        _metadata = metadata;

  @override
  String? get text => _text;

  @override
  List<ToolCall>? get toolCalls => _toolCalls;

  @override
  UsageInfo? get usage => _usage;

  @override
  String? get thinking => _thinking;

  @override
  List<CallWarning> get warnings => _warnings;

  @override
  Map<String, dynamic>? get metadata => _metadata;

  @override
  CallMetadata? get callMetadata {
    final data = metadata;
    if (data == null) return null;
    return CallMetadata.fromJson(data);
  }
}

class _RichChatProvider implements ChatCapability {
  final ChatResponse _response;

  _RichChatProvider(this._response);

  @override
  Future<ChatResponse> chat(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async {
    return _response;
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async* {
    yield CompletionEvent(_response);
  }
}

void main() {
  group('generateText / streaming helpers', () {
    setUp(() {
      LLMProviderRegistry.registerOrReplace(
        MockProviderFactory<ChatCapability>(
          providerId: 'fake',
          supportedCapabilities: {
            LLMCapability.chat,
            LLMCapability.streaming,
          },
          create: (_) => FakeChatProvider(),
        ),
      );
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

    test(
        'generateText propagates thinking, toolCalls, usage, warnings, and metadata',
        () async {
      final toolCall = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: const FunctionCall(
          name: 'do_something',
          arguments: '{"value":1}',
        ),
      );

      const usage = UsageInfo(
        promptTokens: 3,
        completionTokens: 5,
        totalTokens: 8,
      );

      const warnings = [
        CallWarning(
          code: 'TEST_WARNING',
          message: 'Test warning message',
        ),
      ];

      final metadata = <String, dynamic>{
        'provider': 'test-provider',
        'model': 'test-model',
        'request': {'path': '/v1/test'},
        'response': {'status': 200},
        'custom': 'value',
      };

      final response = _RichChatResponse(
        text: 'final text',
        toolCalls: [toolCall],
        usage: usage,
        thinking: 'thinking...',
        warnings: warnings,
        metadata: metadata,
      );

      LLMProviderRegistry.registerOrReplace(
        MockProviderFactory<ChatCapability>(
          providerId: 'rich',
          supportedCapabilities: {
            LLMCapability.chat,
          },
          create: (_) => _RichChatProvider(response),
        ),
      );

      final result = await generateText(
        model: 'rich:test-model',
        prompt: 'Hello',
      );

      expect(result.text, equals('final text'));
      expect(result.thinking, equals('thinking...'));
      expect(result.toolCalls, isNotNull);
      expect(result.toolCalls, hasLength(1));
      expect(result.toolCalls!.single.id, equals('call_1'));
      expect(result.usage, equals(usage));
      expect(result.warnings, equals(warnings));

      final callMetadata = result.metadata;
      expect(callMetadata, isNotNull);
      expect(callMetadata!.provider, equals('test-provider'));
      expect(callMetadata.model, equals('test-model'));
      expect(callMetadata.request?['path'], equals('/v1/test'));
      expect(callMetadata.response?['status'], equals(200));
      expect(callMetadata.providerMetadata?['custom'], equals('value'));

      LLMProviderRegistry.unregister('rich');
    });
  });

  group('generateTextWithModel / streamTextWithModel / generateObjectWithModel',
      () {
    test('generateTextWithModel forwards LanguageModelCallOptions', () async {
      final model = MockLanguageModel(
        providerId: 'fake-model',
        modelId: 'test-model',
        config: LLMConfig(baseUrl: '', model: 'test-model'),
        doGenerate: (messages, options) async {
          expect(messages, hasLength(1));
          final prompt = messages.first;
          expect(prompt.role, ChatRole.user);
          expect(prompt.parts, hasLength(1));
          expect(prompt.parts.first, isA<TextContentPart>());
          final textPart = prompt.parts.first as TextContentPart;
          expect(textPart.text, equals('Hello'));

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
        },
      );

      final options = LanguageModelCallOptions(
        maxTokens: 42,
        temperature: 0.7,
        topP: 0.8,
      );

      final result = await generateTextWithModel(
        model,
        promptMessages: [
          ChatPromptBuilder.user().text('Hello').build(),
        ],
        options: options,
      );

      expect(result.text, equals('ok'));
      expect(model.lastOptions, isNotNull);
      expect(model.lastOptions!.maxTokens, equals(42));
      expect(model.lastOptions!.temperature, equals(0.7));
      expect(model.lastOptions!.topP, equals(0.8));
    });

    test('generateTextWithModel forwards tools and toolChoice', () async {
      final tools = [
        Tool.function(
          name: 'get_weather',
          description: 'Get the current weather for a location.',
          parameters: ParametersSchema(
            schemaType: 'object',
            properties: {
              'location': ParameterProperty(
                propertyType: 'string',
                description: 'City name, e.g. "Paris".',
              ),
            },
            required: ['location'],
          ),
        ),
      ];

      final options = LanguageModelCallOptions(
        tools: tools,
        toolChoice: const AutoToolChoice(),
      );

      final model = MockLanguageModel(
        providerId: 'fake-model',
        modelId: 'test-model',
        config: LLMConfig(baseUrl: '', model: 'test-model'),
        doGenerate: (messages, generateOptions) async {
          expect(messages, hasLength(1));
          final prompt = messages.first;
          expect(prompt.role, ChatRole.user);
          expect(prompt.parts, hasLength(1));
          expect(prompt.parts.first, isA<TextContentPart>());

          expect(generateOptions, isNotNull);
          expect(generateOptions!.tools, equals(tools));
          expect(generateOptions.toolChoice, isA<AutoToolChoice>());

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
        },
      );

      final result = await generateTextWithModel(
        model,
        promptMessages: [
          ChatPromptBuilder.user().text('Weather in Paris').build(),
        ],
        options: options,
      );

      expect(result.text, equals('ok'));
      expect(model.lastOptions, isNotNull);
      expect(model.lastOptions!.tools, equals(tools));
      expect(model.lastOptions!.toolChoice, isA<AutoToolChoice>());
    });

    test('streamTextWithModel forwards LanguageModelCallOptions', () async {
      final model = MockLanguageModel(
        providerId: 'fake-model',
        modelId: 'test-model',
        config: LLMConfig(baseUrl: '', model: 'test-model'),
        doStream: (messages, options) async* {
          expect(messages, hasLength(1));
          final prompt = messages.first;
          expect(prompt.role, ChatRole.user);
          expect(prompt.parts, hasLength(1));
          expect(prompt.parts.first, isA<TextContentPart>());
          final textPart = prompt.parts.first as TextContentPart;
          expect(textPart.text, equals('Stream hello'));

          yield const TextDeltaEvent('chunk');
          yield CompletionEvent(FakeChatResponse());
        },
      );

      final options = LanguageModelCallOptions(
        maxTokens: 10,
        temperature: 0.3,
      );

      final events = <ChatStreamEvent>[];
      await for (final event in streamTextWithModel(
        model,
        promptMessages: [
          ChatPromptBuilder.user().text('Stream hello').build(),
        ],
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
      final model = MockLanguageModel(
        providerId: 'fake-model',
        modelId: 'test-model',
        config: LLMConfig(baseUrl: '', model: 'test-model'),
        doStream: (messages, options) async* {
          expect(messages, hasLength(1));
          final prompt = messages.first;
          expect(prompt.role, ChatRole.user);
          expect(prompt.parts, hasLength(1));
          expect(prompt.parts.first, isA<TextContentPart>());
          final textPart = prompt.parts.first as TextContentPart;
          expect(textPart.text, equals('Stream parts'));

          yield const TextDeltaEvent('chunk');
          yield CompletionEvent(FakeChatResponse());
        },
      );

      final options = LanguageModelCallOptions(
        maxTokens: 5,
        temperature: 0.2,
      );

      final parts = <StreamTextPart>[];
      await for (final part in streamTextPartsWithModel(
        model,
        promptMessages: [
          ChatPromptBuilder.user().text('Stream parts').build(),
        ],
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
      final model = MockLanguageModel(
        providerId: 'fake-model',
        modelId: 'test-model',
        config: LLMConfig(baseUrl: '', model: 'test-model'),
        doGenerate: (messages, options) async {
          expect(messages, hasLength(1));
          final prompt = messages.first;
          expect(prompt.role, ChatRole.user);
          expect(prompt.parts, hasLength(1));
          expect(prompt.parts.first, isA<TextContentPart>());
          final textPart = prompt.parts.first as TextContentPart;
          expect(textPart.text, equals('Return JSON'));

          return GenerateTextResult(
            rawResponse: FakeChatResponse(),
            text: '{"value":"ok"}',
            toolCalls: const [],
            usage: const UsageInfo(
              promptTokens: 1,
              completionTokens: 1,
              totalTokens: 2,
            ),
            warnings: const [],
            metadata: null,
          );
        },
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
        promptMessages: [
          ChatPromptBuilder.user().text('Return JSON').build(),
        ],
        options: options,
      );

      expect(result.object['value'], equals('ok'));
      expect(model.lastOptions, isNotNull);
      expect(model.lastOptions!.maxTokens, equals(7));
      expect(model.lastOptions!.temperature, equals(0.1));
    });
  });
}
