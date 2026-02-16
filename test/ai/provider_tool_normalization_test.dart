import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

class _FakeModel
    implements
        ChatCapability,
        ChatStreamPartsCapability,
        ModelIdentityCapability,
        ProviderCapabilities {
  @override
  final String providerId;

  @override
  final String modelId;

  List<ProviderTool>? lastProviderTools;

  _FakeModel({
    required this.providerId,
    required this.modelId,
  });

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) =>
      throw UnsupportedError('not used');

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) =>
      throw UnsupportedError('not used');

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    lastProviderTools = providerTools;
    yield const LLMTextDeltaPart('ok');
    yield const LLMFinishPart(_FakeChatResponse(text: 'ok'));
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async => null;

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) =>
      throw UnsupportedError('not used');

  @override
  Set<LLMCapability> get supportedCapabilities => const {
        LLMCapability.chat,
        LLMCapability.streaming,
      };

  @override
  bool supports(LLMCapability capability) =>
      supportedCapabilities.contains(capability);
}

class _FakeChatResponse implements ChatResponse {
  @override
  final String? text;

  const _FakeChatResponse({this.text});

  @override
  String? get thinking => null;

  @override
  List<ToolCall>? get toolCalls => null;

  @override
  UsageInfo? get usage => null;

  @override
  Map<String, dynamic>? get providerMetadata => null;
}

void main() {
  group('provider tool normalization', () {
    test('filters groq.browser_search when model is unsupported', () async {
      final model = _FakeModel(
        providerId: 'groq',
        modelId: 'qwen/qwen3-32b',
      );

      final parts = await streamChatParts(
        model: model,
        messages: [ChatMessage.user('hi')],
        providerTools: const [
          ProviderTool(
            id: 'groq.browser_search',
            name: 'browser_search',
          ),
        ],
      ).toList();

      final start = parts.first as LLMStreamStartPart;
      expect(start.warnings, isNotEmpty);
      expect(
        (start.warnings.first as LLMUnsupportedWarning).feature,
        equals('provider-defined tool groq.browser_search'),
      );

      expect(model.lastProviderTools, isNotNull);
      expect(model.lastProviderTools, isEmpty);
    });

    test('keeps groq.browser_search when model is supported', () async {
      final model = _FakeModel(
        providerId: 'groq',
        modelId: 'openai/gpt-oss-20b',
      );

      final parts = await streamChatParts(
        model: model,
        messages: [ChatMessage.user('hi')],
        providerTools: const [
          ProviderTool(
            id: 'groq.browser_search',
            name: 'browser_search',
          ),
        ],
      ).toList();

      final start = parts.first as LLMStreamStartPart;
      expect(start.warnings, isEmpty);

      expect(model.lastProviderTools, isNotNull);
      expect(model.lastProviderTools, hasLength(1));
      expect(model.lastProviderTools!.single.id, equals('groq.browser_search'));
    });

    test('filters unknown anthropic provider tool ids', () async {
      final model = _FakeModel(
        providerId: 'anthropic',
        modelId: 'claude-3-7-sonnet-latest',
      );

      final parts = await streamChatParts(
        model: model,
        messages: [ChatMessage.user('hi')],
        providerTools: const [
          ProviderTool(id: 'anthropic.unknown_tool_20250101'),
        ],
      ).toList();

      final start = parts.first as LLMStreamStartPart;
      expect(start.warnings, isNotEmpty);
      expect(
        (start.warnings.first as LLMUnsupportedWarning).feature,
        equals('provider-defined tool anthropic.unknown_tool_20250101'),
      );

      expect(model.lastProviderTools, isNotNull);
      expect(model.lastProviderTools, isEmpty);
    });

    test('fills anthropic web_search name and supportsDeferredResults',
        () async {
      final model = _FakeModel(
        providerId: 'minimax',
        modelId: 'minimax-test-model',
      );

      final parts = await streamChatParts(
        model: model,
        messages: [ChatMessage.user('hi')],
        providerTools: const [
          ProviderTool(id: 'anthropic.web_search_20250305'),
        ],
      ).toList();

      final start = parts.first as LLMStreamStartPart;
      expect(start.warnings, isEmpty);

      expect(model.lastProviderTools, isNotNull);
      expect(model.lastProviderTools, hasLength(1));

      final tool = model.lastProviderTools!.single;
      expect(tool.id, equals('anthropic.web_search_20250305'));
      expect(tool.name, equals('web_search'));
      expect(tool.supportsDeferredResults, isTrue);
    });
  });
}
