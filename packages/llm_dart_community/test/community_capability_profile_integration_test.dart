import 'package:llm_dart_community/llm_dart_community.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:test/test.dart';

void main() {
  group('Community capability profile integration', () {
    test('Ollama language models expose capabilityProfile directly', () {
      final model = Ollama(
        transport: const _FakeTransportClient(),
      ).chatModel('llama3.2-vision');

      expect(model, isA<CapabilityDescribedModel>());
      expect(model.capabilityProfile.providerId, 'ollama');
      expect(model.capabilityProfile.kind, ModelCapabilityKind.language);
      expect(
        model.capabilityProfile.supports(
          ModelCapabilityFeatureIds.languageImageInput,
        ),
        isTrue,
      );
    });

    test('Ollama embedding models expose capabilityProfile directly', () {
      final model = Ollama(
        transport: const _FakeTransportClient(),
      ).embeddingModel('nomic-embed-text');

      expect(model, isA<CapabilityDescribedModel>());
      expect(model.capabilityProfile.kind, ModelCapabilityKind.embedding);
      expect(
        model.capabilityProfile.supports(
          ModelCapabilityFeatureIds.embeddingBatch,
        ),
        isTrue,
      );
    });

    test('ElevenLabs speech models expose capabilityProfile directly', () {
      final model = ElevenLabs(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).speechModel('eleven_multilingual_v2');

      expect(model, isA<CapabilityDescribedModel>());
      expect(model.capabilityProfile.providerId, 'elevenlabs');
      expect(model.capabilityProfile.kind, ModelCapabilityKind.speech);
      expect(
        model.capabilityProfile.supports(
          ModelCapabilityFeatureIds.speechVoiceSelection,
        ),
        isTrue,
      );
    });

    test('ElevenLabs transcription models expose capabilityProfile directly',
        () {
      final model = ElevenLabs(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).transcriptionModel('scribe_v1_experimental');

      expect(model, isA<CapabilityDescribedModel>());
      expect(model.capabilityProfile.kind, ModelCapabilityKind.transcription);
      expect(
        model.capabilityProfile.supports(
          ModelCapabilityFeatureIds.transcriptionLanguageHints,
        ),
        isTrue,
      );
    });
  });
}

typedef _FakeTransportClient = FakeTransportClient;
