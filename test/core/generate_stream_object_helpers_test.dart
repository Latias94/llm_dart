import 'dart:async';

import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

class FakeStreamChatResponse implements ChatResponse {
  final String _text;

  FakeStreamChatResponse(this._text);

  @override
  String? get text => _text;

  @override
  List<ToolCall>? get toolCalls => const [];

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

class FakeStreamProvider implements ChatCapability {
  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    CancellationToken? cancelToken,
  }) async {
    return FakeStreamChatResponse('{"value":42}');
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancellationToken? cancelToken,
  }) async {
    return chat(messages, cancelToken: cancelToken);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancellationToken? cancelToken,
  }) async* {
    // Stream JSON in two chunks to exercise buffering logic.
    yield const TextDeltaEvent('{"value":');
    yield const TextDeltaEvent('42}');
    yield CompletionEvent(FakeStreamChatResponse('{"value":42}'));
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async => null;

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async =>
      'summary';
}

class FakeStreamFactory extends LLMProviderFactory<ChatCapability> {
  @override
  String get providerId => 'fake-stream';

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
      };

  @override
  ChatCapability create(LLMConfig config) => FakeStreamProvider();

  @override
  bool validateConfig(LLMConfig config) => true;

  @override
  LLMConfig getDefaultConfig() => LLMConfig(baseUrl: '', model: '');
}

void main() {
  group('streamObject helper', () {
    setUp(() {
      LLMProviderRegistry.registerOrReplace(FakeStreamFactory());
    });

    tearDown(() {
      LLMProviderRegistry.unregister('fake-stream');
    });

    test('should stream events and parse structured JSON', () async {
      final output = OutputSpec<int>.object(
        name: 'IntValue',
        properties: {
          'value': ParameterProperty(
            propertyType: 'integer',
            description: 'Integer value',
          ),
        },
        fromJson: (json) => json['value'] as int,
      );

      final result = streamObject<int>(
        model: 'fake-stream:test-model',
        output: output,
        prompt: 'Return a JSON object with value 42',
      );

      final events = <ChatStreamEvent>[];
      await result.events.forEach(events.add);

      expect(events.whereType<TextDeltaEvent>().isNotEmpty, isTrue);
      expect(events.whereType<CompletionEvent>().isNotEmpty, isTrue);

      final objectResult = await result.asObject;
      expect(objectResult.object, equals(42));
    });
  });
}
