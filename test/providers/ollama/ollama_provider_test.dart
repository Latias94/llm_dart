import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('OllamaProvider Tests', () {
    late OllamaProvider provider;
    late OllamaConfig config;

    setUp(() {
      config = const OllamaConfig(
        baseUrl: 'http://localhost:11434/',
        model: 'llama3.1:8b',
        maxTokens: 1000,
        temperature: 0.7,
        numCtx: 4096,
        numGpu: 1,
      );
      provider = OllamaProvider(config);
    });

    group('Provider Initialization', () {
      test('should initialize with valid config', () {
        expect(provider, isNotNull);
        expect(provider.config, equals(config));
        expect(provider.providerName, equals('Ollama'));
      });

      test('should have provider name', () {
        expect(provider.providerName, equals('Ollama'));
      });
    });

    group('Capability Support', () {
      test('should support core capabilities', () {
        expect(provider.supports(LLMCapability.chat), isTrue);
        expect(provider.supports(LLMCapability.streaming), isTrue);
        expect(provider.supports(LLMCapability.completion), isTrue);
        expect(provider.supports(LLMCapability.embedding), isTrue);
        expect(provider.supports(LLMCapability.modelListing), isTrue);
      });

      test('should support tool calling for compatible models', () {
        final toolConfig = config.copyWith(model: 'llama3.1:8b');
        final toolProvider = OllamaProvider(toolConfig);

        expect(toolProvider.supports(LLMCapability.toolCalling), isTrue);
      });

      test('should support vision for vision models', () {
        final visionConfig = config.copyWith(model: 'llava:7b');
        final visionProvider = OllamaProvider(visionConfig);

        expect(visionProvider.supports(LLMCapability.vision), isTrue);
      });

      test('should support reasoning for reasoning models', () {
        final reasoningConfig = config.copyWith(model: 'qwen2.5:7b');
        final reasoningProvider = OllamaProvider(reasoningConfig);

        expect(reasoningProvider.supports(LLMCapability.reasoning), isTrue);
      });

      test('should not support unsupported capabilities', () {
        expect(provider.supports(LLMCapability.imageGeneration), isFalse);
        expect(provider.supports(LLMCapability.textToSpeech), isFalse);
        expect(provider.supports(LLMCapability.speechToText), isFalse);
      });

      test('should return correct supported capabilities set', () {
        final capabilities = provider.supportedCapabilities;

        expect(capabilities, contains(LLMCapability.chat));
        expect(capabilities, contains(LLMCapability.streaming));
        expect(capabilities, contains(LLMCapability.completion));
        expect(capabilities, contains(LLMCapability.embedding));
        expect(capabilities, contains(LLMCapability.modelListing));
        expect(capabilities,
            contains(LLMCapability.toolCalling)); // llama3.1 supports tools
      });
    });

    group('Interface Implementation', () {
      test('should implement ChatCapability', () {
        expect(provider, isA<ChatCapability>());
      });

      test('should implement CompletionCapability', () {
        expect(provider, isA<CompletionCapability>());
      });

      test('should implement EmbeddingCapability', () {
        expect(provider, isA<EmbeddingCapability>());
      });

      test('should implement ModelListingCapability', () {
        expect(provider, isA<ModelListingCapability>());
      });

      test('should implement ProviderCapabilities', () {
        expect(provider, isA<ProviderCapabilities>());
      });
    });

    group('Chat Methods', () {
      test('should have chat method', () {
        expect(provider.chat, isA<Function>());
      });

      test('should have chatStream method', () {
        expect(provider.chatStream, isA<Function>());
      });
    });

    group('Completion Methods', () {
      test('should have complete method', () {
        expect(provider.complete, isA<Function>());
      });
    });

    group('Embedding Methods', () {
      test('should have embed method', () {
        expect(provider.embed, isA<Function>());
      });
    });

    group('Model Listing Methods', () {
      test('should have models method', () {
        expect(provider.models, isA<Function>());
      });
    });

    group('Provider Properties', () {
      test('should return correct model family', () {
        expect(provider.modelFamily, equals('Llama'));
      });

      test('should return correct model family for Mistral', () {
        final mistralConfig = config.copyWith(model: 'mistral:7b');
        final mistralProvider = OllamaProvider(mistralConfig);

        expect(mistralProvider.modelFamily, equals('Mistral'));
      });

      test('should return correct model family for Qwen', () {
        final qwenConfig = config.copyWith(model: 'qwen2:7b');
        final qwenProvider = OllamaProvider(qwenConfig);

        expect(qwenProvider.modelFamily, equals('Qwen'));
      });

      test('should return correct model family for Phi', () {
        final phiConfig = config.copyWith(model: 'phi3:3.8b');
        final phiProvider = OllamaProvider(phiConfig);

        expect(phiProvider.modelFamily, equals('Phi'));
      });

      test('should return correct model family for Gemma', () {
        final gemmaConfig = config.copyWith(model: 'gemma2:9b');
        final gemmaProvider = OllamaProvider(gemmaConfig);

        expect(gemmaProvider.modelFamily, equals('Gemma'));
      });

      test('should return correct model family for Code Llama', () {
        final codeConfig = config.copyWith(model: 'codellama:7b');
        final codeProvider = OllamaProvider(codeConfig);

        expect(codeProvider.modelFamily, equals('Code Llama'));
      });

      test('should return correct model family for LLaVA', () {
        final llavaConfig = config.copyWith(model: 'llava:7b');
        final llavaProvider = OllamaProvider(llavaConfig);

        expect(llavaProvider.modelFamily, equals('LLaVA'));
      });

      test('should detect local deployment', () {
        expect(provider.isLocal, isTrue);
      });

      test('should detect remote deployment', () {
        final remoteConfig = config.copyWith(baseUrl: 'https://api.ollama.com');
        final remoteProvider = OllamaProvider(remoteConfig);

        expect(remoteProvider.isLocal, isFalse);
      });

      test('should detect embeddings support for embedding models', () {
        final embedConfig = config.copyWith(model: 'nomic-embed-text:v1.5');
        final embedProvider = OllamaProvider(embedConfig);

        expect(embedProvider.supportsEmbeddings, isTrue);
      });

      test('should not detect embeddings support for chat models', () {
        expect(provider.supportsEmbeddings, isFalse);
      });
    });

    group('Model-Specific Behavior', () {
      test('should handle vision models correctly', () {
        final visionConfig = config.copyWith(model: 'llava:7b');
        final visionProvider = OllamaProvider(visionConfig);

        expect(visionProvider.config.supportsVision, isTrue);
        expect(visionProvider.supports(LLMCapability.vision), isTrue);
        expect(visionProvider.modelFamily, equals('LLaVA'));
      });

      test('should handle embedding models correctly', () {
        final embedConfig = config.copyWith(model: 'nomic-embed-text:v1.5');
        final embedProvider = OllamaProvider(embedConfig);

        expect(embedProvider.config.supportsEmbeddings, isTrue);
        expect(embedProvider.supportsEmbeddings, isTrue);
        expect(embedProvider.supports(LLMCapability.embedding), isTrue);
      });

      test('should handle code generation models correctly', () {
        final codeConfig = config.copyWith(model: 'codellama:7b');
        final codeProvider = OllamaProvider(codeConfig);

        expect(codeProvider.config.supportsCodeGeneration, isTrue);
        expect(codeProvider.modelFamily, equals('Code Llama'));
      });

      test('should handle reasoning models correctly', () {
        final reasoningConfig = config.copyWith(model: 'qwen2.5:7b');
        final reasoningProvider = OllamaProvider(reasoningConfig);

        expect(reasoningProvider.config.supportsReasoning, isTrue);
        expect(reasoningProvider.supports(LLMCapability.reasoning), isTrue);
      });
    });

    group('Configuration Integration', () {
      test('should use config properties correctly', () {
        expect(provider.config.baseUrl, equals('http://localhost:11434/'));
        expect(provider.config.model, equals('llama3.1:8b'));
        expect(provider.config.maxTokens, equals(1000));
        expect(provider.config.temperature, equals(0.7));
        expect(provider.config.numCtx, equals(4096));
        expect(provider.config.numGpu, equals(1));
      });

      test('should handle Ollama-specific parameters', () {
        final ollamaConfig = config.copyWith(
          numCtx: 8192,
          numGpu: 2,
          numThread: 16,
          numa: true,
          numBatch: 1024,
          keepAlive: '10m',
          raw: false,
        );
        final ollamaProvider = OllamaProvider(ollamaConfig);

        expect(ollamaProvider.config.numCtx, equals(8192));
        expect(ollamaProvider.config.numGpu, equals(2));
        expect(ollamaProvider.config.numThread, equals(16));
        expect(ollamaProvider.config.numa, isTrue);
        expect(ollamaProvider.config.numBatch, equals(1024));
        expect(ollamaProvider.config.keepAlive, equals('10m'));
        expect(ollamaProvider.config.raw, isFalse);
      });
    });

    group('Error Handling', () {
      test('should handle invalid model gracefully during initialization', () {
        final invalidConfig = config.copyWith(model: 'invalid-model');

        // Should not throw during initialization
        expect(() => OllamaProvider(invalidConfig), returnsNormally);
      });

      test('should handle empty model gracefully', () {
        final emptyModelConfig = config.copyWith(model: '');

        // Should not throw during initialization
        expect(() => OllamaProvider(emptyModelConfig), returnsNormally);
      });

      test('should handle missing API key gracefully', () {
        final noKeyConfig = config.copyWith(apiKey: null);

        // Should not throw during initialization (API key is optional for Ollama)
        expect(() => OllamaProvider(noKeyConfig), returnsNormally);
      });
    });
  });
}
