import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('LLM Dart Library Entry Point', () {
    test('exports the stable AI facade from the root library', () {
      final model = AI.openai(apiKey: 'test-key').chatModel('gpt-5-mini');
      final shortcutModel = openai(apiKey: 'test-key').chatModel('gpt-5-mini');

      expect(model.providerId, 'openai');
      expect(shortcutModel.providerId, model.providerId);
      expect(shortcutModel.modelId, model.modelId);
      expect(() => AI.deepSeek(apiKey: 'test-key'), returnsNormally);
      expect(() => AI.groq(apiKey: 'test-key'), returnsNormally);
      expect(() => deepSeek(apiKey: 'test-key'), returnsNormally);
      expect(() => groq(apiKey: 'test-key'), returnsNormally);
    });

    group('Library exports', () {
      test('shared core exports are available', () {
        expect(UserPromptMessage, isA<Type>());
        expect(GenerateTextOptions, isA<Type>());
        expect(CallOptions, isA<Type>());
        expect(JsonSchema, isA<Type>());
      });

      test('provider-owned typed option exports are available', () {
        expect(OpenAIGenerateTextOptions, isA<Type>());
        expect(OpenAIWebSearchTool, isA<Type>());
        expect(GoogleGenerateTextOptions, isA<Type>());
        expect(AnthropicGenerateTextOptions, isA<Type>());
      });

      test('transport exports are available', () {
        expect(TransportClient, isA<Type>());
        expect(TransportRequest, isA<Type>());
        expect(TransportException, isA<Type>());
      });
    });
  });
}
