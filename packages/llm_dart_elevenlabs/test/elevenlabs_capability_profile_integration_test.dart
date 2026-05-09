import 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:test/test.dart';

void main() {
  group('ElevenLabs capability profile integration', () {
    test('speech models expose capabilityProfile directly', () {
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

    test('transcription models expose capabilityProfile directly', () {
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
