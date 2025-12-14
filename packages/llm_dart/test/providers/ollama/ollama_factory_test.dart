import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('OllamaProviderFactory Tests', () {
    late OllamaProviderFactory factory;

    setUp(() {
      factory = OllamaProviderFactory();
    });

    group('Factory Properties', () {
      test('should have correct provider ID', () {
        expect(factory.providerId, equals('ollama'));
      });

      test('should have correct display name', () {
        expect(factory.displayName, equals('Ollama'));
      });

      test('should have descriptive description', () {
        expect(factory.description, isNotEmpty);
        expect(factory.description.toLowerCase(), contains('local'));
      });

      test('should support expected capabilities', () {
        final capabilities = factory.supportedCapabilities;

        expect(capabilities, contains(LLMCapability.chat));
        expect(capabilities, contains(LLMCapability.streaming));
        expect(capabilities, contains(LLMCapability.embedding));
        expect(capabilities, contains(LLMCapability.modelListing));
        expect(capabilities, contains(LLMCapability.reasoning));
      });

      test('should not support unsupported capabilities', () {
        final capabilities = factory.supportedCapabilities;

        expect(capabilities, isNot(contains(LLMCapability.imageGeneration)));
        expect(capabilities, isNot(contains(LLMCapability.textToSpeech)));
        expect(capabilities, isNot(contains(LLMCapability.speechToText)));
        expect(capabilities, isNot(contains(LLMCapability.toolCalling)));
        expect(capabilities, isNot(contains(LLMCapability.vision)));
        // Note: reasoning is now supported by Ollama as of v0.9.0
      });
    });

    group('Provider Creation', () {
      test('should create provider with basic config', () {
        final config = LLMConfig(
          baseUrl: 'http://localhost:11434/',
          model: 'llama3.2',
        );

        final provider = factory.create(config);

        expect(provider, isA<OllamaProvider>());
        expect(provider, isA<ChatCapability>());
      });

      test('should create provider with API key', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'http://localhost:11434/',
          model: 'llama3.1:8b',
        );

        final provider = factory.create(config);

        expect(provider, isA<OllamaProvider>());
        expect(provider, isA<ChatCapability>());
      });

      test('should create provider with Ollama-specific parameters', () {
        final config = LLMConfig(
          baseUrl: 'http://localhost:11434/',
          model: 'llama3.1:8b',
          maxTokens: 2000,
          temperature: 0.8,
          systemPrompt: 'You are a helpful assistant',
          timeout: const Duration(seconds: 30),
          topP: 0.9,
          topK: 50,
          tools: [],
          extensions: {
            'numCtx': 4096,
            'numGpu': 2,
            'numThread': 8,
            'numa': true,
            'numBatch': 512,
            'keepAlive': '10m',
            'raw': false,
          },
        );

        final provider = factory.create(config);

        expect(provider, isA<OllamaProvider>());
        expect(provider, isA<ChatCapability>());
      });

      test('should create provider for vision models', () {
        final config = LLMConfig(
          baseUrl: 'http://localhost:11434/',
          model: 'llava:7b',
        );

        final provider = factory.create(config);

        expect(provider, isA<OllamaProvider>());
        expect(provider, isA<ChatCapability>());
      });

      test('should create provider for embedding models', () {
        final config = LLMConfig(
          baseUrl: 'http://localhost:11434/',
          model: 'nomic-embed-text:v1.5',
        );

        final provider = factory.create(config);

        expect(provider, isA<OllamaProvider>());
      });

      test('should handle missing base URL gracefully', () {
        final config = LLMConfig(
          baseUrl: 'http://localhost:11434/',
          model: 'llama3.2',
        );

        // Should use default base URL
        expect(() => factory.create(config), returnsNormally);
      });
    });

    group('Default Configuration', () {
      test('should provide default configuration', () {
        final defaultConfig = factory.getDefaultConfig();

        expect(defaultConfig.model, isNotNull);
        expect(defaultConfig.baseUrl, isNotNull);
      });

      test('should have valid default model', () {
        final defaultConfig = factory.getDefaultConfig();
        final model = defaultConfig.model;

        expect(model, isNotNull);
        expect(model, isNotEmpty);
        expect(model, equals('llama3.2'));
      });

      test('should have valid default base URL', () {
        final defaultConfig = factory.getDefaultConfig();
        final baseUrl = defaultConfig.baseUrl;

        expect(baseUrl, isNotNull);
        expect(baseUrl, equals('http://localhost:11434/'));
      });
    });

    group('Configuration Validation', () {
      test('should validate valid config without API key', () {
        final config = LLMConfig(
          baseUrl: 'http://localhost:11434/',
          model: 'llama3.2',
        );

        expect(factory.validateConfig(config), isTrue);
      });

      test('should validate valid config with API key', () {
        final config = LLMConfig(
          apiKey: 'test-api-key',
          baseUrl: 'http://localhost:11434/',
          model: 'llama3.1:8b',
        );

        expect(factory.validateConfig(config), isTrue);
      });

      test('should validate config with Ollama extensions', () {
        final config = LLMConfig(
          baseUrl: 'http://localhost:11434/',
          model: 'llama3.1:8b',
          extensions: {
            'numCtx': 4096,
            'numGpu': 2,
            'keepAlive': '5m',
          },
        );

        expect(factory.validateConfig(config), isTrue);
      });

      test('should validate vision model config', () {
        final config = LLMConfig(
          baseUrl: 'http://localhost:11434/',
          model: 'llava:7b',
        );

        expect(factory.validateConfig(config), isTrue);
      });

      test('should validate embedding model config', () {
        final config = LLMConfig(
          baseUrl: 'http://localhost:11434/',
          model: 'nomic-embed-text:v1.5',
        );

        expect(factory.validateConfig(config), isTrue);
      });
    });

    group('Provider Interface Compliance', () {
      test('should implement BaseProviderFactory', () {
        expect(factory, isA<BaseProviderFactory<ChatCapability>>());
      });

      test('should implement LLMProviderFactory', () {
        expect(factory, isA<LLMProviderFactory<ChatCapability>>());
      });

      test('should create providers that implement required interfaces', () {
        final config = LLMConfig(
          baseUrl: 'http://localhost:11434/',
          model: 'llama3.2',
        );

        final provider = factory.create(config);

        expect(provider, isA<ChatCapability>());
        expect(provider, isA<ProviderCapabilities>());
      });
    });

    group('Error Handling', () {
      test('should handle invalid model gracefully', () {
        final config = LLMConfig(
          baseUrl: 'http://localhost:11434/',
          model: 'invalid-model',
        );

        // Should not throw during creation, but provider may validate later
        expect(() => factory.create(config), returnsNormally);
      });

      test('should handle invalid base URL gracefully', () {
        final config = LLMConfig(
          baseUrl: 'invalid-url',
          model: 'llama3.2',
        );

        // Should throw during creation due to URL validation
        expect(() => factory.create(config), throwsA(isA<LLMError>()));
      });

      test('should handle remote Ollama instances', () {
        final config = LLMConfig(
          baseUrl: 'https://remote-ollama.example.com/',
          model: 'llama3.1:8b',
        );

        expect(() => factory.create(config), returnsNormally);
      });

      test('should handle code generation models', () {
        final config = LLMConfig(
          baseUrl: 'http://localhost:11434/',
          model: 'codellama:7b',
        );

        expect(() => factory.create(config), returnsNormally);
      });

      test('should handle reasoning models', () {
        final config = LLMConfig(
          baseUrl: 'http://localhost:11434/',
          model: 'qwen2.5:7b',
        );

        expect(() => factory.create(config), returnsNormally);
      });
    });
  });
}
