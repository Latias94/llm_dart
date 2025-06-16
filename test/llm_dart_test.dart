import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('LLM Dart Library Entry Point', () {
    test('ai() creates a new LLMBuilder instance', () {
      final builder = ai();
      expect(builder, isA<LLMBuilder>());
    });

    test('ai() creates different instances each time', () {
      final builder1 = ai();
      final builder2 = ai();
      expect(identical(builder1, builder2), isFalse);
    });

    group('createProvider function', () {
      test('throws error with invalid provider ID', () async {
        expect(
          () => createProvider(
            providerId: 'invalid_provider',
            apiKey: 'test-key',
            model: 'test-model',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('creates provider with minimal required parameters', () async {
        // Test that provider can be created without throwing during construction
        final provider = await createProvider(
          providerId: 'openai',
          apiKey: 'test-key',
          model: 'gpt-3.5-turbo',
        );

        expect(provider, isNotNull);
        expect(provider.toString(), contains('OpenAIProvider'));
      });

      test('creates provider with all optional parameters', () async {
        final provider = await createProvider(
          providerId: 'openai',
          apiKey: 'test-key',
          model: 'gpt-4',
          baseUrl: 'https://api.openai.com/v1',
          temperature: 0.7,
          maxTokens: 1000,
          systemPrompt: 'You are a helpful assistant',
          timeout: Duration(seconds: 30),
          stream: true,
          topP: 0.9,
          topK: 50,
          extensions: {'custom': 'value'},
        );

        expect(provider, isNotNull);
        expect(provider.toString(), contains('OpenAIProvider'));
        expect(provider.toString(), contains('gpt-4'));
      });

      test('handles null optional parameters correctly', () async {
        final provider = await createProvider(
          providerId: 'openai',
          apiKey: 'test-key',
          model: 'gpt-3.5-turbo',
          baseUrl: null,
          temperature: null,
          maxTokens: null,
          systemPrompt: null,
          timeout: null,
          topP: null,
          topK: null,
          extensions: null,
        );

        expect(provider, isNotNull);
        expect(provider.toString(), contains('OpenAIProvider'));
      });

      test('handles empty extensions map', () async {
        final provider = await createProvider(
          providerId: 'openai',
          apiKey: 'test-key',
          model: 'gpt-3.5-turbo',
          extensions: {},
        );

        expect(provider, isNotNull);
        expect(provider.toString(), contains('OpenAIProvider'));
      });

      test('handles multiple extensions', () async {
        final provider = await createProvider(
          providerId: 'openai',
          apiKey: 'test-key',
          model: 'gpt-3.5-turbo',
          extensions: {
            'ext1': 'value1',
            'ext2': 'value2',
            'ext3': {'nested': 'value'},
          },
        );

        expect(provider, isNotNull);
        expect(provider.toString(), contains('OpenAIProvider'));
      });
    });

    group('Library exports', () {
      test('core exports are available', () {
        // Test that core classes can be referenced
        expect(LLMConfig, isA<Type>());
        expect(LLMProviderRegistry, isA<Type>());
      });

      test('model exports are available', () {
        // Test that model classes can be referenced
        expect(ChatMessage, isA<Type>());
        expect(ToolCall, isA<Type>());
      });

      test('builder exports are available', () {
        // Test that builder classes can be instantiated
        expect(() => LLMBuilder(), returnsNormally);
        expect(() => HttpConfig(), returnsNormally);
      });
    });
  });
}
