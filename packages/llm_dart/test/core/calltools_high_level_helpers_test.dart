// Tests for high-level helpers (streamTextParts / streamObject) when
// LanguageModelCallOptions.callTools is used. These tests ensure that
// the helpers route calls through the LanguageModel-based path so that
// provider-defined tools are visible at the provider layer.

import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('High-level callTools integration', () {
    test('streamTextParts forwards callTools via LanguageModel path', () async {
      final factory = _TestChatProviderFactory();
      LLMProviderRegistry.registerOrReplace(factory);

      // Without callTools: options are applied at the config layer but
      // are not visible in ChatCapability.chatStream when using the
      // legacy builder.streamTextParts path.
      final optionsNoTools = const LanguageModelCallOptions(
        maxTokens: 16,
      );

      await streamTextParts(
        model: 'test-provider:dummy-model',
        prompt: 'hello',
        options: optionsNoTools,
      ).drain<void>();

      final providerWithoutTools = factory.lastProvider;
      expect(providerWithoutTools, isNotNull);
      expect(providerWithoutTools!.chatStreamCalls, equals(1));
      expect(providerWithoutTools.lastStreamOptions, isNotNull);
      expect(providerWithoutTools.lastStreamOptions!.maxTokens, equals(16));
      expect(providerWithoutTools.lastStreamOptions!.callTools, isNull);

      // With callTools: high-level helper should build a LanguageModel
      // and route the call through streamTextPartsWithModel so that
      // callTools survive down to ChatCapability.chatStream.
      final optionsWithTools = LanguageModelCallOptions(
        callTools: const [
          ProviderDefinedToolSpec(
            id: 'test.tool',
          ),
        ],
      );

      await streamTextParts(
        model: 'test-provider:dummy-model',
        prompt: 'hello with tools',
        options: optionsWithTools,
      ).drain<void>();

      final providerWithTools = factory.lastProvider;
      expect(providerWithTools, isNotNull);
      expect(providerWithTools!.chatStreamCalls, equals(1));

      final lastOptions = providerWithTools.lastStreamOptions;
      expect(lastOptions, isNotNull);
      expect(lastOptions!.callTools, isNotNull);
      expect(lastOptions.callTools, isNotEmpty);

      final firstSpec = lastOptions.callTools!.first;
      expect(
        firstSpec,
        isA<ProviderDefinedToolSpec>().having(
          (s) => s.id,
          'id',
          'test.tool',
        ),
      );
    });

    test('streamObject forwards callTools via LanguageModel path', () async {
      final factory = _StructuredTestChatProviderFactory();
      LLMProviderRegistry.registerOrReplace(factory);

      final optionsWithTools = LanguageModelCallOptions(
        callTools: const [
          ProviderDefinedToolSpec(
            id: 'test.tool',
          ),
        ],
      );

      // Simple structured output spec expecting {"value": integer}.
      final outputSpec = OutputSpec.intValue(
        name: 'IntValue',
        fieldName: 'value',
      );

      final result = streamObject<int>(
        model: 'structured-test-provider:dummy-model',
        output: outputSpec,
        prompt: 'return a number as JSON',
        options: optionsWithTools,
      );

      final objectResult = await result.asObject;
      expect(objectResult.object, equals(123));

      final provider = factory.lastProvider;
      expect(provider, isNotNull);
      expect(provider!.chatStreamCalls, equals(1));

      final lastOptions = provider.lastStreamOptions;
      expect(lastOptions, isNotNull);
      expect(lastOptions!.callTools, isNotNull);
      expect(lastOptions.callTools, isNotEmpty);

      final firstSpec = lastOptions.callTools!.first;
      expect(
        firstSpec,
        isA<ProviderDefinedToolSpec>().having(
          (s) => s.id,
          'id',
          'test.tool',
        ),
      );
    });
  });
}

/// Minimal ChatResponse implementation used by test providers.
class _TestChatResponse implements ChatResponse {
  final String? _text;

  _TestChatResponse(this._text);

  @override
  String? get text => _text;

  @override
  List<ToolCall>? get toolCalls => const [];

  @override
  String? get thinking => null;

  @override
  UsageInfo? get usage => null;

  @override
  List<CallWarning> get warnings => const [];

  @override
  Map<String, dynamic>? get metadata => null;

  @override
  CallMetadata? get callMetadata => null;
}

/// ChatCapability implementation that records chatStream invocations.
class _TestChatProvider extends ChatCapability {
  int chatStreamCalls = 0;
  LanguageModelCallOptions? lastStreamOptions;

  @override
  Future<ChatResponse> chat(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async {
    return _TestChatResponse('ok');
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async* {
    chatStreamCalls++;
    lastStreamOptions = options;

    // Emit a minimal completion so high-level helpers can complete.
    yield CompletionEvent(_TestChatResponse('ok'));
  }
}

/// ChatCapability for structured output tests: streams a JSON object.
class _StructuredTestChatProvider extends ChatCapability {
  int chatStreamCalls = 0;
  LanguageModelCallOptions? lastStreamOptions;

  @override
  Future<ChatResponse> chat(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async {
    return _TestChatResponse('{"value": 123}');
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async* {
    chatStreamCalls++;
    lastStreamOptions = options;

    const jsonText = '{"value": 123}';
    yield TextDeltaEvent(jsonText);
    yield CompletionEvent(_TestChatResponse(jsonText));
  }
}

/// Provider factory for _TestChatProvider used in streamTextParts test.
class _TestChatProviderFactory implements LLMProviderFactory<ChatCapability> {
  _TestChatProvider? lastProvider;

  @override
  String get providerId => 'test-provider';

  @override
  Set<LLMCapability> get supportedCapabilities =>
      {LLMCapability.chat, LLMCapability.streaming};

  @override
  ChatCapability create(LLMConfig config) {
    final provider = _TestChatProvider();
    lastProvider = provider;
    return provider;
  }

  @override
  bool validateConfig(LLMConfig config) {
    // Accept any config for test purposes.
    return true;
  }

  @override
  LLMConfig getDefaultConfig() =>
      const LLMConfig(baseUrl: 'https://test/', model: 'test-model');

  @override
  String get displayName => 'Test Provider';

  @override
  String get description => 'Test provider for callTools streamTextParts tests';
}

/// Provider factory for _StructuredTestChatProvider used in streamObject test.
class _StructuredTestChatProviderFactory
    implements LLMProviderFactory<ChatCapability> {
  _StructuredTestChatProvider? lastProvider;

  @override
  String get providerId => 'structured-test-provider';

  @override
  Set<LLMCapability> get supportedCapabilities =>
      {LLMCapability.chat, LLMCapability.streaming};

  @override
  ChatCapability create(LLMConfig config) {
    final provider = _StructuredTestChatProvider();
    lastProvider = provider;
    return provider;
  }

  @override
  bool validateConfig(LLMConfig config) {
    return true;
  }

  @override
  LLMConfig getDefaultConfig() => const LLMConfig(
        baseUrl: 'https://structured-test/',
        model: 'structured-model',
      );

  @override
  String get displayName => 'Structured Test Provider';

  @override
  String get description =>
      'Test provider for callTools streamObject structured output tests';
}
