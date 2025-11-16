import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

class _DefaultSettingsChatProvider
    implements ChatCapability, ProviderCapabilities {
  final LLMConfig config;

  _DefaultSettingsChatProvider(this.config);

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
    // Encode messages and tools into the response text so tests can
    // verify that the middleware modified them correctly.
    final messagePart = messages
        .map((m) => '${m.role.name}:${m.content}')
        .toList()
        .join('|');
    final toolPart = tools == null || tools.isEmpty
        ? 'tools:[]'
        : 'tools:[${tools.map((t) => t.function.name).join(',')}]';
    return _DefaultSettingsChatResponse('$messagePart;$toolPart');
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    final response = await chatWithTools(
      messages,
      tools,
      cancelToken: cancelToken,
    );
    yield CompletionEvent(response);
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

class _DefaultSettingsChatResponse implements ChatResponse {
  final String _text;

  const _DefaultSettingsChatResponse(this._text);

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

class _DefaultSettingsProviderFactory
    extends LLMProviderFactory<ChatCapability> {
  @override
  String get providerId => 'test-default-settings-provider';

  @override
  Set<LLMCapability> get supportedCapabilities =>
      {LLMCapability.chat, LLMCapability.streaming};

  @override
  ChatCapability create(LLMConfig config) =>
      _DefaultSettingsChatProvider(config);

  @override
  bool validateConfig(LLMConfig config) => true;

  @override
  LLMConfig getDefaultConfig() =>
      LLMConfig(baseUrl: 'http://localhost', model: 'test-model');
}

void main() {
  group('DefaultChatSettingsMiddleware', () {
    setUp(() {
      LLMProviderRegistry.registerOrReplace(_DefaultSettingsProviderFactory());
    });

    test('injects system prompt when none present', () async {
      final settings = DefaultChatSettings(systemPrompt: 'You are helpful.');
      final middleware = createDefaultChatSettingsMiddleware(settings);

      final provider = await ai()
          .provider('test-default-settings-provider')
          .middlewares([middleware])
          .buildWithMiddleware();

      final response = await provider.chat([
        ChatMessage.user('Hello'),
      ]) as _DefaultSettingsChatResponse;

      // Expect system message to be injected at the beginning.
      expect(
        response.text,
        startsWith('system:You are helpful.|user:Hello;'),
      );
    });

    test(
        'does not inject system prompt when one exists and onlyWhenNoSystemMessage is true',
        () async {
      final settings = DefaultChatSettings(systemPrompt: 'You are helpful.');
      final middleware = createDefaultChatSettingsMiddleware(settings);

      final provider = await ai()
          .provider('test-default-settings-provider')
          .middlewares([middleware])
          .buildWithMiddleware();

      final response = await provider.chat([
        ChatMessage.system('Existing system'),
        ChatMessage.user('Hello'),
      ]) as _DefaultSettingsChatResponse;

      // Expect original system message to remain first, without duplication.
      expect(
        response.text,
        startsWith('system:Existing system|user:Hello;'),
      );
    });

    test('injects default tools when none provided', () async {
      final tools = [
        Tool.function(
          name: 'test_tool',
          description: 'A test tool',
          parameters: ParametersSchema(
            schemaType: 'object',
            properties: {},
            required: [],
          ),
        ),
      ];

      final settings = DefaultChatSettings(defaultTools: tools);
      final middleware = createDefaultChatSettingsMiddleware(settings);

      final provider = await ai()
          .provider('test-default-settings-provider')
          .middlewares([middleware])
          .buildWithMiddleware();

      final response = await provider.chat([
        ChatMessage.user('Hello'),
      ]) as _DefaultSettingsChatResponse;

      expect(response.text, endsWith('tools:[test_tool]'));
    });
  });
}

