import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Provider capability consistency guard', () {
    setUp(() {
      // Keep this test isolated from other suites.
      LLMProviderRegistry.clear();
      ai(); // triggers BuiltinProviderRegistry.ensureRegistered()
    });

    test('factory capabilities map to implemented interfaces', () {
      final factories = LLMProviderRegistry.getAllFactories();
      expect(factories, isNotEmpty);

      for (final entry in factories.entries) {
        final providerId = entry.key;
        final factory = entry.value;

        var config = factory.getDefaultConfig();
        if (!factory.validateConfig(config)) {
          config = config.copyWith(apiKey: 'test-key');
        }
        if (!factory.validateConfig(config)) {
          config = config.copyWith(
            apiKey: 'test-key',
            baseUrl: config.baseUrl.isEmpty ? 'https://example.com/' : null,
            model: config.model.isEmpty ? 'test-model' : null,
          );
        }

        expect(
          factory.validateConfig(config),
          isTrue,
          reason: 'Factory $providerId should accept a valid default config',
        );

        final provider =
            LLMProviderRegistry.createAnyProvider(providerId, config);

        final caps = factory.supportedCapabilities;
        if (caps.contains(LLMCapability.chat) ||
            caps.contains(LLMCapability.streaming) ||
            caps.contains(LLMCapability.toolCalling) ||
            caps.contains(LLMCapability.reasoning) ||
            caps.contains(LLMCapability.vision)) {
          expect(
            provider,
            isA<ChatCapability>(),
            reason: '$providerId advertises chat-like capabilities',
          );
        }

        if (caps.contains(LLMCapability.embedding)) {
          expect(
            provider,
            isA<EmbeddingCapability>(),
            reason: '$providerId advertises embeddings',
          );
        }

        if (caps.contains(LLMCapability.rerank)) {
          expect(
            provider,
            isA<RerankCapability>(),
            reason: '$providerId advertises rerank',
          );
        }

        if (caps.contains(LLMCapability.textToSpeech)) {
          expect(
            provider,
            isA<TextToSpeechCapability>(),
            reason: '$providerId advertises text-to-speech',
          );
        }

        if (caps.contains(LLMCapability.streamingTextToSpeech)) {
          expect(
            provider,
            isA<StreamingTextToSpeechCapability>(),
            reason: '$providerId advertises streaming text-to-speech',
          );
        }

        if (caps.contains(LLMCapability.speechToText)) {
          expect(
            provider,
            isA<SpeechToTextCapability>(),
            reason: '$providerId advertises speech-to-text',
          );
        }

        if (caps.contains(LLMCapability.audioTranslation)) {
          expect(
            provider,
            isA<AudioTranslationCapability>(),
            reason: '$providerId advertises audio translation',
          );
        }

        if (caps.contains(LLMCapability.realtimeAudio)) {
          expect(
            provider,
            isA<RealtimeAudioCapability>(),
            reason: '$providerId advertises realtime audio',
          );
        }

        if (caps.contains(LLMCapability.imageGeneration)) {
          expect(
            provider,
            isA<ImageGenerationCapability>(),
            reason: '$providerId advertises image generation',
          );
        }

        // Best-effort capability that is gated behind provider-specific settings.
        if (caps.contains(LLMCapability.openaiResponses) &&
            (providerId == 'openai' || providerId == 'azure')) {
          final enabledConfig =
              config.withProviderOption(providerId, 'useResponsesAPI', true);
          final enabledProvider =
              LLMProviderRegistry.createAnyProvider(providerId, enabledConfig);

          expect(enabledProvider, isA<ProviderCapabilities>());

          final supported =
              (enabledProvider as ProviderCapabilities).supportedCapabilities;
          expect(
            supported,
            contains(LLMCapability.openaiResponses),
            reason: '$providerId should expose openaiResponses when enabled',
          );
        }
      }
    });
  });
}
