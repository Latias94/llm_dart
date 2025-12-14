import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

import '../utils/mock_provider_factory.dart';

class _RecordingChatProvider implements ChatCapability, ProviderCapabilities {
  final LLMConfig config;

  List<ModelMessage>? lastMessages;
  List<Tool>? lastTools;
  LanguageModelCallOptions? lastOptions;

  _RecordingChatProvider(this.config);

  @override
  Future<ChatResponse> chat(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async {
    lastMessages = messages;
    lastTools = tools;
    lastOptions = options;
    return const _TextChatResponse('ok');
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
    lastOptions = options;
    yield const CompletionEvent(_TextChatResponse('ok'));
  }

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
      };

  @override
  bool supports(LLMCapability capability) =>
      supportedCapabilities.contains(capability);
}

class _TextChatResponse implements ChatResponse {
  @override
  final String? text;

  const _TextChatResponse(this.text);

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
  group('DefaultLanguageModel tools forwarding', () {
    late _RecordingChatProvider provider;

    setUp(() {
      LLMProviderRegistry.registerOrReplace(
        MockProviderFactory<ChatCapability>(
          providerId: 'recording',
          supportedCapabilities: {
            LLMCapability.chat,
            LLMCapability.streaming,
          },
          create: (config) {
            provider = _RecordingChatProvider(config);
            return provider;
          },
        ),
      );
    });

    tearDown(() {
      LLMProviderRegistry.unregister('recording');
    });

    test('buildLanguageModel forwards tools to chat()', () async {
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

      final model = await ai()
          .provider('recording')
          .model('test-model')
          .buildLanguageModel();

      final result = await generateTextWithModel(
        model,
        promptMessages: [ModelMessage.userText('Hello')],
        options: LanguageModelCallOptions(tools: tools),
      );

      expect(result.text, equals('ok'));
      expect(provider.lastTools, equals(tools));
      expect(provider.lastMessages, isNotNull);
      expect(provider.lastMessages!.single.role, equals(ChatRole.user));
    });

    test('buildLanguageModel forwards tools to chatStream()', () async {
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

      final model = await ai()
          .provider('recording')
          .model('test-model')
          .buildLanguageModel();

      final events = <ChatStreamEvent>[];
      await for (final event in streamTextWithModel(
        model,
        promptMessages: [ModelMessage.userText('Hello')],
        options: LanguageModelCallOptions(tools: tools),
      )) {
        events.add(event);
      }

      expect(events.whereType<CompletionEvent>(), hasLength(1));
      expect(provider.lastTools, equals(tools));
    });

    test('buildLanguageModel forwards FunctionCallToolSpec via callTools',
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

      final model = await ai()
          .provider('recording')
          .model('test-model')
          .buildLanguageModel();

      final result = await generateTextWithModel(
        model,
        promptMessages: [ModelMessage.userText('Hello')],
        options: LanguageModelCallOptions(
          callTools: [FunctionCallToolSpec(tool)],
        ),
      );

      expect(result.text, equals('ok'));
      expect(provider.lastTools, equals([tool]));
    });
  });
}
