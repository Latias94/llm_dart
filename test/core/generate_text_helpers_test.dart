import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
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
  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  }) async {
    return FakeChatResponse();
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    return FakeChatResponse();
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
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
  group('generateText / streamText helpers', () {
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
  });
}
