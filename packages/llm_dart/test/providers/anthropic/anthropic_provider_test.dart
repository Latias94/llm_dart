import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart' as anthropic;

void main() {
  group('AnthropicProvider Tests', () {
    late anthropic.AnthropicProvider provider;
    late anthropic.AnthropicConfig config;

    setUp(() {
      config = const anthropic.AnthropicConfig(
        apiKey: 'test-api-key',
        model: 'claude-sonnet-4-20250514',
        baseUrl: 'https://api.anthropic.com',
        maxTokens: 1000,
        temperature: 0.7,
      );
      provider = anthropic.AnthropicProvider(config);
    });

    group('Provider Initialization', () {
      test('should initialize with valid config', () {
        expect(provider, isNotNull);
        expect(provider.config, equals(config));
        expect(provider.providerName, equals('Anthropic'));
      });

      test('should validate thinking config on initialization', () {
        final reasoningConfig = const anthropic.AnthropicConfig(
          apiKey: 'test-api-key',
          model: 'claude-sonnet-4-20250514',
          reasoning: true,
          thinkingBudgetTokens: 5000,
        );

        expect(() => anthropic.AnthropicProvider(reasoningConfig),
            returnsNormally);
      });

      test('should warn about invalid thinking config', () {
        final invalidConfig = const anthropic.AnthropicConfig(
          apiKey: 'test-api-key',
          model: 'claude-3-haiku-20240307', // Doesn't support reasoning
          reasoning: true,
        );

        expect(
            () => anthropic.AnthropicProvider(invalidConfig), returnsNormally);
      });
    });

    group('Capability Support', () {
      test('should support core capabilities', () {
        expect(provider.supports(LLMCapability.chat), isTrue);
        expect(provider.supports(LLMCapability.streaming), isTrue);
        expect(provider.supports(LLMCapability.toolCalling), isTrue);
        expect(provider.supports(LLMCapability.modelListing), isTrue);
        expect(provider.supports(LLMCapability.fileManagement), isTrue);
      });

      test('should support vision for vision models', () {
        final visionConfig = config.copyWith(model: 'claude-sonnet-4-20250514');
        final visionProvider = anthropic.AnthropicProvider(visionConfig);

        expect(visionProvider.supports(LLMCapability.vision), isTrue);
      });

      test('should support reasoning for reasoning models', () {
        final reasoningConfig = config.copyWith(
          model: 'claude-sonnet-4-20250514',
          reasoning: true,
        );
        final reasoningProvider = anthropic.AnthropicProvider(reasoningConfig);

        expect(reasoningProvider.supports(LLMCapability.reasoning), isTrue);
      });

      test('should not support unsupported capabilities', () {
        expect(provider.supports(LLMCapability.embedding), isFalse);
        expect(provider.supports(LLMCapability.imageGeneration), isFalse);
        expect(provider.supports(LLMCapability.textToSpeech), isFalse);
      });

      test('should return correct supported capabilities set', () {
        final capabilities = provider.supportedCapabilities;

        expect(capabilities, contains(LLMCapability.chat));
        expect(capabilities, contains(LLMCapability.streaming));
        expect(capabilities, contains(LLMCapability.toolCalling));
        expect(capabilities, contains(LLMCapability.modelListing));
        expect(capabilities, contains(LLMCapability.fileManagement));
        expect(capabilities, contains(LLMCapability.vision));
      });
    });

    group('Interface Implementation', () {
      test('should implement ChatCapability', () {
        expect(provider, isA<ChatCapability>());
      });

      test('should implement ModelListingCapability', () {
        expect(provider, isA<ModelListingCapability>());
      });

      test('should implement FileManagementCapability', () {
        expect(provider, isA<FileManagementCapability>());
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

      test('should have countTokens method', () {
        expect(provider.countTokens, isA<Function>());
      });
    });

    group('File Management Methods', () {
      test('should have uploadFile method', () {
        expect(provider.uploadFile, isA<Function>());
      });

      test('should have listFiles method', () {
        expect(provider.listFiles, isA<Function>());
      });

      test('should have retrieveFile method', () {
        expect(provider.retrieveFile, isA<Function>());
      });

      test('should have deleteFile method', () {
        expect(provider.deleteFile, isA<Function>());
      });

      test('should have getFileContent method', () {
        expect(provider.getFileContent, isA<Function>());
      });

      test('should have uploadFileFromBytes method', () {
        expect(provider.uploadFileFromBytes, isA<Function>());
      });

      test('should have fileExists method', () {
        expect(provider.fileExists, isA<Function>());
      });
    });

    group('Model Listing Methods', () {
      test('should have models method', () {
        expect(provider.models, isA<Function>());
      });
    });
  });
}
