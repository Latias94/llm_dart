import 'dart:convert';

import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';
import '../utils/mock_provider_factory.dart';

class FakeObjectChatResponse implements ChatResponse {
  final String _text;

  FakeObjectChatResponse(this._text);

  @override
  String? get text => _text;

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
  final String responseText;

  FakeObjectChatProvider({required this.responseText});

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async {
    return FakeObjectChatResponse(responseText);
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async {
    return FakeObjectChatResponse(responseText);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async* {
    yield TextDeltaEvent(responseText);
    yield CompletionEvent(FakeObjectChatResponse(responseText));
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async => null;

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async =>
      'summary';
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
    late FakeObjectChatProvider provider;

    setUp(() {
      provider = FakeObjectChatProvider(
        responseText: jsonEncode({'value': 42, 'label': 'answer'}),
      );

      LLMProviderRegistry.registerOrReplace(
        MockProviderFactory<ChatCapability>(
          providerId: 'fake-object',
          supportedCapabilities: {
            LLMCapability.chat,
            LLMCapability.streaming,
          },
          create: (_) => provider,
        ),
      );
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

    test('throws ResponseFormatError for invalid JSON', () async {
      provider = FakeObjectChatProvider(responseText: '{ invalid json');

      LLMProviderRegistry.registerOrReplace(
        MockProviderFactory<ChatCapability>(
          providerId: 'fake-object',
          supportedCapabilities: {
            LLMCapability.chat,
            LLMCapability.streaming,
          },
          create: (_) => provider,
        ),
      );

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

      expect(
        () => generateObject<TestObject>(
          model: 'fake-object:test-model',
          output: output,
          prompt: 'Return a TestObject JSON',
        ),
        throwsA(isA<ResponseFormatError>()),
      );
    });

    test('throws ResponseFormatError when top-level JSON is not an object',
        () async {
      provider =
          FakeObjectChatProvider(responseText: '["not", "an", "object"]');

      LLMProviderRegistry.registerOrReplace(
        MockProviderFactory<ChatCapability>(
          providerId: 'fake-object',
          supportedCapabilities: {
            LLMCapability.chat,
            LLMCapability.streaming,
          },
          create: (_) => provider,
        ),
      );

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

      expect(
        () => generateObject<TestObject>(
          model: 'fake-object:test-model',
          output: output,
          prompt: 'Return a TestObject JSON',
        ),
        throwsA(isA<ResponseFormatError>()),
      );
    });

    test('throws StructuredOutputError when object does not match schema',
        () async {
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
        fromJson: (json) => TestObject(
          json['value'] as int,
          json['label'] as String,
        ),
      );

      // Provider returns JSON with wrong types for the schema:
      // value is a string, label is a number.
      provider = FakeObjectChatProvider(
        responseText: jsonEncode({'value': 'not-int', 'label': 123}),
      );

      LLMProviderRegistry.registerOrReplace(
        MockProviderFactory<ChatCapability>(
          providerId: 'fake-object',
          supportedCapabilities: {
            LLMCapability.chat,
            LLMCapability.streaming,
          },
          create: (_) => provider,
        ),
      );

      expect(
        () => generateObject<TestObject>(
          model: 'fake-object:test-model',
          output: output,
          prompt: 'Return a TestObject JSON',
        ),
        throwsA(isA<StructuredOutputError>()),
      );
    });

    test('propagates usage and warnings from provider response', () async {
      final warnings = [
        const CallWarning(
          code: 'TEST_WARNING',
          message: 'Test warning message',
        ),
      ];

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

      // Provider that returns a response with custom usage and warnings.
      LLMProviderRegistry.registerOrReplace(
        MockProviderFactory<ChatCapability>(
          providerId: 'fake-object-warn',
          supportedCapabilities: {
            LLMCapability.chat,
          },
          create: (_) => _WarningObjectChatProvider(warnings: warnings),
        ),
      );

      final result = await generateObject<TestObject>(
        model: 'fake-object-warn:test-model',
        output: output,
        prompt: 'Return a TestObject JSON with warnings',
      );

      expect(result.object.value, equals(1));
      expect(result.object.label, equals('warn'));

      final usage = result.textResult.usage;
      expect(usage, isNotNull);
      expect(usage!.promptTokens, equals(10));
      expect(usage.completionTokens, equals(5));
      expect(usage.totalTokens, equals(15));

      final resultWarnings = result.textResult.warnings;
      expect(resultWarnings, equals(warnings));

      LLMProviderRegistry.unregister('fake-object-warn');
    });
  });
}

class _WarningObjectChatResponse implements ChatResponse {
  @override
  final String? text;

  @override
  final List<CallWarning> warnings;

  const _WarningObjectChatResponse({
    required this.text,
    required this.warnings,
  });

  @override
  List<ToolCall>? get toolCalls => const [];

  @override
  UsageInfo? get usage => const UsageInfo(
        promptTokens: 10,
        completionTokens: 5,
        totalTokens: 15,
      );

  @override
  String? get thinking => null;

  @override
  Map<String, dynamic>? get metadata => null;

  @override
  CallMetadata? get callMetadata => null;
}

class _WarningObjectChatProvider implements ChatCapability {
  final List<CallWarning> warnings;

  _WarningObjectChatProvider({required this.warnings});

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async {
    return _WarningObjectChatResponse(
      text: '{"value":1,"label":"warn"}',
      warnings: warnings,
    );
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async {
    return chat(messages, options: options, cancelToken: cancelToken);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async* {
    yield TextDeltaEvent('{"value":1,"label":"warn"}');
    yield CompletionEvent(
      _WarningObjectChatResponse(
        text: '{"value":1,"label":"warn"}',
        warnings: warnings,
      ),
    );
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async => null;

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async =>
      'summary';
}
