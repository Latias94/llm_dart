import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

import '../utils/mock_provider_factory.dart';

class _ProbeChatProvider implements ChatCapability, ProviderCapabilities {
  final LLMConfig config;

  _ProbeChatProvider(this.config);

  @override
  Future<ChatResponse> chat(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async {
    final messagePart = messages
        .map((m) {
          final text = m.parts
              .whereType<TextContentPart>()
              .map((part) => part.text)
              .join();
          return '${m.role.name}:$text';
        })
        .toList()
        .join('|');

    final toolPart = tools == null || tools.isEmpty
        ? 'tools:[]'
        : 'tools:[${tools.map((t) => t.function.name).join(',')}]';

    return _ProbeChatResponse('$messagePart;$toolPart');
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async* {
    final response = await chat(
      messages,
      tools: tools,
      options: options,
      cancelToken: cancelToken,
    );
    yield CompletionEvent(response);
  }

  @override
  Set<LLMCapability> get supportedCapabilities =>
      {LLMCapability.chat, LLMCapability.streaming};

  @override
  bool supports(LLMCapability capability) =>
      supportedCapabilities.contains(capability);
}

class _ProbeChatResponse implements ChatResponse {
  final String _text;

  _ProbeChatResponse(this._text);

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

void main() {
  group('LLMBuilder middleware integration', () {
    setUp(() {
      LLMProviderRegistry.registerOrReplace(
        MockProviderFactory<ChatCapability>(
          providerId: 'middleware-probe',
          supportedCapabilities: {
            LLMCapability.chat,
            LLMCapability.streaming,
          },
          create: (config) => _ProbeChatProvider(config),
        ),
      );
    });

    tearDown(() {
      LLMProviderRegistry.unregister('middleware-probe');
    });

    test('LLMBuilder.generateText applies chat middlewares', () async {
      final tools = [
        Tool.function(
          name: 'test_tool',
          description: 'A test tool',
          parameters: ParametersSchema(
            schemaType: 'object',
            properties: {},
            required: const [],
          ),
        ),
      ];

      final middleware = createDefaultChatSettingsMiddleware(
        DefaultChatSettings(
          systemPrompt: 'SYS',
          defaultTools: tools,
        ),
      );

      final result = await ai()
          .provider('middleware-probe')
          .model('test-model')
          .middlewares([middleware]).generateText(prompt: 'Hello');

      expect(
          result.text, startsWith('system:SYS|user:Hello;tools:[test_tool]'));
    });

    test('LLMBuilder.streamText applies chat middlewares', () async {
      final middleware = createDefaultChatSettingsMiddleware(
        const DefaultChatSettings(
          systemPrompt: 'SYS',
        ),
      );

      final stream = ai()
          .provider('middleware-probe')
          .model('test-model')
          .middlewares([middleware]).streamText(prompt: 'Hello');

      final events = await stream.toList();
      final completion = events.whereType<CompletionEvent>().single;
      expect(completion.response.text, startsWith('system:SYS|user:Hello;'));
    });

    test('buildLanguageModel includes chat middlewares', () async {
      final middleware = createDefaultChatSettingsMiddleware(
        const DefaultChatSettings(
          systemPrompt: 'SYS',
        ),
      );

      final model = await ai()
          .provider('middleware-probe')
          .model('test-model')
          .middlewares([middleware]).buildLanguageModel();

      final result = await generateTextWithModel(
        model,
        promptMessages: [ModelMessage.userText('Hello')],
      );

      expect(result.text, startsWith('system:SYS|user:Hello;'));
    });

    test('LLMBuilder.generateText forwards FunctionCallToolSpec via callTools',
        () async {
      final tool = Tool.function(
        name: 'test_tool',
        description: 'A test tool',
        parameters: ParametersSchema(
          schemaType: 'object',
          properties: {},
          required: const [],
        ),
      );

      final result = await ai()
          .provider('middleware-probe')
          .model('test-model')
          .generateText(
            prompt: 'Hello',
            options: LanguageModelCallOptions(
              callTools: [FunctionCallToolSpec(tool)],
            ),
          );

      expect(result.text, endsWith('tools:[test_tool]'));
    });
  });
}
