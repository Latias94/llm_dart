import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

// Mock ChatResponse implementation
class MockChatResponse implements ChatResponse {
  final String _text;

  MockChatResponse(this._text);

  @override
  String? get text => _text;

  @override
  List<ToolCall>? get toolCalls => null;

  @override
  String? get thinking => null;

  @override
  UsageInfo? get usage => null;

  @override
  List<CallWarning> get warnings => const [];

  @override
  Map<String, dynamic>? get metadata => null;
}

// Mock provider for testing
class MockProvider implements ChatCapability, ProviderCapabilities {
  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  }) async {
    return MockChatResponse('Mock response');
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    return chat(messages, cancelToken: cancelToken);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    yield TextDeltaEvent('Mock');
    yield TextDeltaEvent(' response');
    yield CompletionEvent(
      MockChatResponse('Mock response'),
    );
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async => null;

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async =>
      'Mock summary';

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
      };

  @override
  bool supports(LLMCapability capability) =>
      supportedCapabilities.contains(capability);
}

// Mock factory for testing
class MockProviderFactory implements LLMProviderFactory<ChatCapability> {
  @override
  String get providerId => 'mock';

  @override
  String get displayName => 'Mock Provider';

  @override
  String get description => 'A mock provider for testing';

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
      };

  @override
  ChatCapability create(LLMConfig config) => MockProvider();

  @override
  bool validateConfig(LLMConfig config) => config.model.isNotEmpty;

  @override
  LLMConfig getDefaultConfig() => LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.mock.com',
        model: 'mock-model',
      );

  Map<String, dynamic> getConfigSchema() => {
        'type': 'object',
        'properties': {
          'model': {'type': 'string'},
        },
        'required': ['model'],
      };

  LLMConfig transformConfig(LLMConfig config) => config;

  Map<String, dynamic> getProviderInfo() => {
        'id': providerId,
        'name': displayName,
        'description': description,
        'capabilities': supportedCapabilities.map((c) => c.toString()).toList(),
      };
}

void main() {
  group('Registry Tests', () {
    setUp(() {
      // Clear registry before each test
      LLMProviderRegistry.clear();
    });

    group('LLMProviderRegistry', () {
      test('should register and retrieve providers', () {
        final factory = MockProviderFactory();
        LLMProviderRegistry.register(factory);

        final registeredProviders =
            LLMProviderRegistry.getRegisteredProviders();
        expect(registeredProviders, contains('mock'));

        final retrievedFactory = LLMProviderRegistry.getFactory('mock');
        expect(retrievedFactory, isNotNull);
        expect(retrievedFactory!.providerId, equals('mock'));
      });

      test('should throw error when registering duplicate provider', () {
        final factory = MockProviderFactory();
        LLMProviderRegistry.register(factory);

        expect(
          () => LLMProviderRegistry.register(factory),
          throwsA(isA<InvalidRequestError>()),
        );
      });

      test('should allow replacing providers', () {
        final factory1 = MockProviderFactory();
        final factory2 = MockProviderFactory();

        LLMProviderRegistry.register(factory1);
        LLMProviderRegistry.registerOrReplace(factory2);

        final retrievedFactory = LLMProviderRegistry.getFactory('mock');
        expect(retrievedFactory, equals(factory2));
      });

      test('should check capability support', () {
        final factory = MockProviderFactory();
        LLMProviderRegistry.register(factory);

        expect(
          LLMProviderRegistry.supportsCapability('mock', LLMCapability.chat),
          isTrue,
        );
        expect(
          LLMProviderRegistry.supportsCapability(
              'mock', LLMCapability.embedding),
          isFalse,
        );
        expect(
          LLMProviderRegistry.supportsCapability(
              'nonexistent', LLMCapability.chat),
          isFalse,
        );
      });

      test('should create provider instances', () {
        final factory = MockProviderFactory();
        LLMProviderRegistry.register(factory);

        final config = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.test.com',
          model: 'test-model',
        );

        final provider = LLMProviderRegistry.createProvider('mock', config);
        expect(provider, isA<MockProvider>());
      });

      test('should throw error for unknown provider', () {
        final config = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.test.com',
          model: 'test-model',
        );

        expect(
          () => LLMProviderRegistry.createProvider('unknown', config),
          throwsA(isA<InvalidRequestError>()),
        );
      });

      test('should validate config before creating provider', () {
        final factory = MockProviderFactory();
        LLMProviderRegistry.register(factory);

        final invalidConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.test.com',
          model: '', // Empty model should fail validation
        );

        expect(
          () => LLMProviderRegistry.createProvider('mock', invalidConfig),
          throwsA(isA<InvalidRequestError>()),
        );
      });

      test('should get provider info', () {
        final factory = MockProviderFactory();
        LLMProviderRegistry.register(factory);

        final info = LLMProviderRegistry.getProviderInfo('mock');
        expect(info, isNotNull);
        expect(info!.id, equals('mock'));
        expect(info.displayName, equals('Mock Provider'));
        expect(info.description, equals('A mock provider for testing'));
        expect(info.supportedCapabilities, contains(LLMCapability.chat));
      });

      test('should get all provider info', () {
        final factory = MockProviderFactory();
        LLMProviderRegistry.register(factory);

        final providers = LLMProviderRegistry.getAllProviderInfo();
        expect(providers,
            hasLength(greaterThan(0))); // May include built-in providers

        final mockProvider = providers.firstWhere((p) => p.id == 'mock');
        expect(mockProvider.id, equals('mock'));
        expect(
            mockProvider.supportedCapabilities, contains(LLMCapability.chat));
      });

      test('should check capability support for providers', () {
        final factory = MockProviderFactory();
        LLMProviderRegistry.register(factory);

        // Get all providers and check their capabilities
        final providers = LLMProviderRegistry.getRegisteredProviders();
        expect(providers, contains('mock'));

        // Check if mock provider supports chat
        final chatSupported =
            LLMProviderRegistry.supportsCapability('mock', LLMCapability.chat);
        expect(chatSupported, isTrue);

        // Check if mock provider doesn't support embedding
        final embeddingSupported = LLMProviderRegistry.supportsCapability(
            'mock', LLMCapability.embedding);
        expect(embeddingSupported, isFalse);
      });

      test('should clear registry', () {
        final factory = MockProviderFactory();
        LLMProviderRegistry.register(factory);

        final beforeClear = LLMProviderRegistry.getRegisteredProviders();
        expect(beforeClear, contains('mock'));

        LLMProviderRegistry.clear();

        // After clear, built-in providers may be re-initialized
        // but our mock provider should be gone
        final afterClear = LLMProviderRegistry.getRegisteredProviders();
        expect(afterClear, isNot(contains('mock')));
      });
    });
  });
}
