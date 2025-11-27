import 'dart:convert';

import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

class FakeObjectChatResponse implements ChatResponse {
  @override
  String? get text => jsonEncode({'value': 42, 'label': 'answer'});

  @override
  List<ToolCall>? get toolCalls => const [];

  @override
  UsageInfo? get usage => const UsageInfo(
        promptTokens: 2,
        completionTokens: 3,
        totalTokens: 5,
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

class FakeObjectChatProvider implements ChatCapability {
  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async {
    return FakeObjectChatResponse();
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async {
    return FakeObjectChatResponse();
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async* {
    yield const TextDeltaEvent('{"value": 42, "label": "answer"}');
    yield CompletionEvent(FakeObjectChatResponse());
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async => null;

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async =>
      'summary';
}

class FakeObjectProviderFactory extends LLMProviderFactory<ChatCapability> {
  @override
  String get providerId => 'fake-object';

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
      };

  @override
  ChatCapability create(LLMConfig config) => FakeObjectChatProvider();

  @override
  bool validateConfig(LLMConfig config) => true;

  @override
  LLMConfig getDefaultConfig() => LLMConfig(baseUrl: '', model: '');
}

class TestObject {
  final int value;
  final String label;

  const TestObject(this.value, this.label);

  static TestObject fromJson(Map<String, dynamic> json) {
    return TestObject(
      json['value'] as int,
      json['label'] as String,
    );
  }
}

void main() {
  group('generateObject helper', () {
    setUp(() {
      LLMProviderRegistry.registerOrReplace(FakeObjectProviderFactory());
    });

    tearDown(() {
      LLMProviderRegistry.unregister('fake-object');
    });

    test('should parse structured JSON into typed object', () async {
      final output = OutputSpec<TestObject>.object(
        name: 'TestObject',
        properties: {
          'value': ParameterProperty(
            propertyType: 'integer',
            description: 'Value',
          ),
          'label': ParameterProperty(
            propertyType: 'string',
            description: 'Label',
          ),
        },
        fromJson: TestObject.fromJson,
      );

      final result = await generateObject<TestObject>(
        model: 'fake-object:test-model',
        output: output,
        prompt: 'Return a TestObject JSON',
      );

      expect(result.object.value, equals(42));
      expect(result.object.label, equals('answer'));
      expect(result.textResult.usage, isNotNull);
      expect(result.textResult.usage!.totalTokens, equals(5));
    });
  });
}
