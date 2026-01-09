import 'package:test/test.dart';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_azure/config.dart';
import 'package:llm_dart_azure/provider.dart';

void main() {
  group('Azure OpenAI capabilities', () {
    test('declares image + audio capabilities', () {
      final config = AzureOpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://example.openai.azure.com/openai/v1/',
        model: 'gpt-4o',
        apiVersion: '2024-10-01-preview',
      );

      final provider = AzureOpenAIProvider(config);

      expect(provider.supports(LLMCapability.imageGeneration), isTrue);
      expect(provider.supports(LLMCapability.textToSpeech), isTrue);
      expect(provider.supports(LLMCapability.speechToText), isTrue);
      expect(provider.supports(LLMCapability.audioTranslation), isTrue);
    });
  });
}

