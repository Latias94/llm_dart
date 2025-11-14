import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

// Mock ChatResponse implementation
class MockChatResponse implements ChatResponse {
  final String _text;
  final List<ToolCall>? _toolCalls;
  final String? _thinking;
  final UsageInfo? _usage;

  MockChatResponse({
    required String text,
    List<ToolCall>? toolCalls,
    String? thinking,
    UsageInfo? usage,
  })  : _text = text,
        _toolCalls = toolCalls,
        _thinking = thinking,
        _usage = usage;

  @override
  String? get text => _text;

  @override
  List<ToolCall>? get toolCalls => _toolCalls;

  @override
  String? get thinking => _thinking;

  @override
  UsageInfo? get usage => _usage;

  @override
  List<CallWarning> get warnings => const [];

  @override
  Map<String, dynamic>? get metadata => null;
}

// Mock factory for testing base functionality
class MockBaseFactory extends BaseProviderFactory<ChatCapability> {
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
  ChatCapability create(LLMConfig config) {
    return MockProvider();
  }

  @override
  Map<String, dynamic> getProviderDefaults() => {
        'model': 'mock-model',
        'baseUrl': 'https://api.mock.com',
        'temperature': 0.7,
      };
}

// Mock provider implementation
class MockProvider implements ChatCapability, ProviderCapabilities {
  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  }) async {
    return MockChatResponse(text: 'Mock response');
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
    yield TextDeltaEvent('Mock response');
    yield CompletionEvent(MockChatResponse(text: 'Mock response'));
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

// Mock local provider factory (no API key required)
class MockLocalFactory extends LocalProviderFactory<ChatCapability> {
  @override
  String get providerId => 'mock-local';

  @override
  String get displayName => 'Mock Local Provider';

  @override
  String get description => 'A mock local provider for testing';

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
      };

  @override
  ChatCapability create(LLMConfig config) {
    return MockProvider();
  }

  @override
  Map<String, dynamic> getProviderDefaults() => {
        'model': 'local-model',
        'baseUrl': 'http://localhost:8080',
      };
}

// Mock audio provider factory
class MockAudioFactory extends AudioProviderFactory<ChatCapability> {
  @override
  String get providerId => 'mock-audio';

  @override
  String get displayName => 'Mock Audio Provider';

  @override
  String get description => 'A mock audio provider for testing';

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.textToSpeech,
        LLMCapability.speechToText,
      };

  @override
  ChatCapability create(LLMConfig config) {
    return MockProvider();
  }

  @override
  Map<String, dynamic> getProviderDefaults() => {
        'model': 'audio-model',
        'baseUrl': 'https://api.audio.com',
      };
}

void main() {
  group('Base Factory Tests', () {
    group('BaseProviderFactory', () {
      late MockBaseFactory factory;

      setUp(() {
        factory = MockBaseFactory();
      });

      test('should have correct provider info', () {
        expect(factory.providerId, equals('mock'));
        expect(factory.displayName, equals('Mock Provider'));
        expect(factory.description, equals('A mock provider for testing'));
        expect(factory.supportedCapabilities, contains(LLMCapability.chat));
      });

      test('should validate config with API key', () {
        final validConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.test.com',
          model: 'test-model',
        );

        expect(factory.validateConfig(validConfig), isTrue);
      });

      test('should reject config without API key', () {
        final invalidConfig = LLMConfig(
          baseUrl: 'https://api.test.com',
          model: 'test-model',
        );

        expect(factory.validateConfig(invalidConfig), isFalse);
      });

      test('should reject config without model', () {
        final invalidConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.test.com',
          model: '',
        );

        // The base validateConfig only checks API key, not model
        // Model validation happens in validateConfigWithDetails
        expect(factory.validateConfig(invalidConfig), isTrue);
        expect(() => factory.validateConfigWithDetails(invalidConfig),
            throwsA(isA<InvalidRequestError>()));
      });

      test('should get base config map', () {
        final config = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.test.com',
          model: 'test-model',
          temperature: 0.8,
          maxTokens: 1000,
        );

        final baseConfig = factory.getBaseConfigMap(config);
        expect(baseConfig['apiKey'], equals('test-key'));
        expect(baseConfig['baseUrl'], equals('https://api.test.com'));
        expect(baseConfig['model'], equals('test-model'));
        expect(baseConfig['temperature'], equals(0.8));
        expect(baseConfig['maxTokens'], equals(1000));
      });

      test('should get provider defaults', () {
        final defaults = factory.getProviderDefaults();
        expect(defaults['model'], equals('mock-model'));
        expect(defaults['baseUrl'], equals('https://api.mock.com'));
        expect(defaults['temperature'], equals(0.7));
      });

      test('should create provider safely', () {
        final config = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.test.com',
          model: 'test-model',
        );

        final provider = factory.createProviderSafely<LLMConfig>(
          config,
          () => config,
          (config) => MockProvider(),
        );

        expect(provider, isA<MockProvider>());
      });

      test('should handle creation errors gracefully', () {
        final config = LLMConfig(
          baseUrl: 'https://api.test.com',
          model: 'test-model',
          // Missing API key
        );

        // When validateConfigWithDetails fails, it throws InvalidRequestError
        // which is an LLMError, so it gets rethrown as-is
        expect(
          () => factory.createProviderSafely<LLMConfig>(
            config,
            () => config,
            (config) => MockProvider(),
          ),
          throwsA(isA<InvalidRequestError>()),
        );
      });

      test('should wrap non-LLM errors in GenericError', () {
        final config = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.test.com',
          model: 'test-model',
        );

        // When configFactory throws a non-LLMError, it gets wrapped in GenericError
        expect(
          () => factory.createProviderSafely<LLMConfig>(
            config,
            () => throw Exception('Config error'),
            (config) => MockProvider(),
          ),
          throwsA(isA<GenericError>()),
        );
      });
    });

    group('LocalProviderFactory', () {
      late MockLocalFactory factory;

      setUp(() {
        factory = MockLocalFactory();
      });

      test('should not require API key', () {
        expect(factory.requiresApiKey, isFalse);
      });

      test('should validate config without API key', () {
        final config = LLMConfig(
          baseUrl: 'http://localhost:8080',
          model: 'local-model',
        );

        expect(factory.validateConfig(config), isTrue);
      });

      test('should reject config without model', () {
        final config = LLMConfig(
          baseUrl: 'http://localhost:8080',
          model: '',
        );

        expect(factory.validateConfig(config), isFalse);
      });
    });

    group('AudioProviderFactory', () {
      late MockAudioFactory factory;

      setUp(() {
        factory = MockAudioFactory();
      });

      test('should have audio capabilities', () {
        final capabilities = factory.supportedCapabilities;
        expect(capabilities, contains(LLMCapability.textToSpeech));
        expect(capabilities, contains(LLMCapability.speechToText));
      });

      test('should require API key', () {
        expect(factory.requiresApiKey, isTrue);
      });

      test('should validate config with API key', () {
        final config = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.audio.com',
          model: 'audio-model',
        );

        expect(factory.validateConfig(config), isTrue);
      });
    });

    group('Factory Validation', () {
      late MockBaseFactory factory;

      setUp(() {
        factory = MockBaseFactory();
      });

      test('should validate config with API key', () {
        final validConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.test.com',
          model: 'test-model',
        );
        expect(factory.validateApiKey(validConfig), isTrue);
      });

      test('should reject config without API key', () {
        final invalidConfig = LLMConfig(
          baseUrl: 'https://api.test.com',
          model: 'test-model',
        );
        expect(factory.validateApiKey(invalidConfig), isFalse);
      });

      test('should validate model only for local providers', () {
        final validConfig = LLMConfig(
          baseUrl: 'http://localhost:8080',
          model: 'local-model',
        );
        expect(factory.validateModelOnly(validConfig), isTrue);

        final invalidConfig = LLMConfig(
          baseUrl: 'http://localhost:8080',
          model: '',
        );
        expect(factory.validateModelOnly(invalidConfig), isFalse);
      });
    });
  });
}
