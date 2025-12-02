import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('PhindProvider Tests', () {
    late PhindProvider provider;
    late PhindConfig config;

    setUp(() {
      config = const PhindConfig(
        apiKey: 'test-api-key',
        baseUrl: 'https://api.phind.com/v1/',
        model: 'Phind-70B',
        maxTokens: 1000,
        temperature: 0.7,
      );
      provider = PhindProvider(config);
    });

    group('Provider Initialization', () {
      test('should initialize with valid config', () {
        expect(provider, isNotNull);
        expect(provider.config, equals(config));
        expect(provider.providerName, equals('Phind'));
      });

      test('should initialize client', () {
        expect(provider.client, isNotNull);
      });
    });

    group('Capability Support', () {
      test('should support core capabilities through config', () {
        expect(provider.info['supportsChat'], isTrue);
        expect(provider.info['supportsStreaming'], isTrue);
        expect(provider.info['supportsReasoning'], isTrue);
      });

      test('should not support tool calling', () {
        expect(provider.config.supportsToolCalling, isFalse);
      });

      test('should not support vision', () {
        expect(provider.config.supportsVision, isFalse);
      });

      test('should support code generation', () {
        expect(provider.config.supportsCodeGeneration, isTrue);
      });
    });

    group('Interface Implementation', () {
      test('should implement ChatCapability', () {
        expect(provider, isA<ChatCapability>());
      });
    });

    group('Chat Methods', () {
      test('should have chat method', () {
        expect(provider.chat, isA<Function>());
      });

      test('should have chatWithTools method', () {
        expect(provider.chatWithTools, isA<Function>());
      });

      test('should have chatStream method', () {
        expect(provider.chatStream, isA<Function>());
      });

      test('should have memoryContents method', () {
        expect(provider.memoryContents, isA<Function>());
      });

      test('should have summarizeHistory method', () {
        expect(provider.summarizeHistory, isA<Function>());
      });
    });

    group('Provider Properties', () {
      test('should return correct model family', () {
        expect(provider.config.modelFamily, equals('Phind'));
      });

      test('should support code generation', () {
        expect(provider.config.supportsCodeGeneration, isTrue);
      });

      test('should support reasoning', () {
        expect(provider.config.supportsReasoning, isTrue);
      });
    });

    group('Coding-Specific Features', () {
      test('should be optimized for coding tasks', () {
        expect(provider.config.supportsCodeGeneration, isTrue);
        expect(provider.config.supportsReasoning, isTrue);
        expect(provider.config.modelFamily, equals('Phind'));
      });

      test('should handle coding-focused models', () {
        final codingConfig = config.copyWith(
          model: 'Phind-34B',
          systemPrompt: 'You are an expert programmer.',
        );
        final codingProvider = PhindProvider(codingConfig);

        expect(codingProvider.config.supportsCodeGeneration, isTrue);
        expect(codingProvider.config.systemPrompt, contains('programmer'));
      });
    });

    group('Configuration Integration', () {
      test('should use config properties correctly', () {
        expect(provider.config.apiKey, equals('test-api-key'));
        expect(provider.config.model, equals('Phind-70B'));
        expect(provider.config.maxTokens, equals(1000));
        expect(provider.config.temperature, equals(0.7));
      });

      test('should handle different Phind models', () {
        final phind34Config = config.copyWith(model: 'Phind-34B');
        final phind34Provider = PhindProvider(phind34Config);

        expect(phind34Provider.config.model, equals('Phind-34B'));
        expect(phind34Provider.config.modelFamily, equals('Phind'));
      });
    });

    group('Error Handling', () {
      test('should handle invalid model gracefully during initialization', () {
        final invalidConfig = config.copyWith(model: 'invalid-model');

        // Should not throw during initialization
        expect(() => PhindProvider(invalidConfig), returnsNormally);
      });

      test('should handle empty model gracefully', () {
        final emptyModelConfig = config.copyWith(model: '');

        // Should not throw during initialization
        expect(() => PhindProvider(emptyModelConfig), returnsNormally);
      });
    });

    group('Tool Calling Limitations', () {
      test('should not support tool calling in config', () {
        expect(provider.config.supportsToolCalling, isFalse);
      });

      test('should not support tool calling in config', () {
        expect(provider.config.supportsToolCalling, isFalse);
      });

      test('should handle tool requests gracefully', () {
        // Even though tools aren't supported, the method should exist
        expect(provider.chatWithTools, isA<Function>());
      });
    });

    group('Vision Limitations', () {
      test('should not support vision in config', () {
        expect(provider.config.supportsVision, isFalse);
      });

      test('should not support vision in config', () {
        expect(provider.config.supportsVision, isFalse);
      });
    });
  });
}
