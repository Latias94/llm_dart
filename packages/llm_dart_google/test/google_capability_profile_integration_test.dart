import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_google/llm_dart_google.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:test/test.dart';

void main() {
  group('Google capability profile integration', () {
    test('language models expose capabilityProfile directly', () {
      final model = Google(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).chatModel('gemini-3-pro-preview');

      expect(model, isA<CapabilityDescribedModel>());
      expect(model.capabilityProfile.providerId, 'google');
      expect(model.capabilityProfile.modelId, 'gemini-3-pro-preview');
      expect(model.capabilityProfile.kind, ModelCapabilityKind.language);
      expect(
        model.capabilityProfile.supports(
          ModelCapabilityFeatureIds.languageReasoningOutput,
        ),
        isTrue,
      );
      expect(
        model.capabilityProfile.providerFeature('google', 'api.route')?.detail,
        'generateContent',
      );
    });

    test('embedding models expose capabilityProfile directly', () {
      final model = Google(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).embeddingModel('text-embedding-004');

      expect(model, isA<CapabilityDescribedModel>());
      expect(model.capabilityProfile.kind, ModelCapabilityKind.embedding);
      expect(
        model.capabilityProfile.supports(
          ModelCapabilityFeatureIds.embeddingDimensions,
        ),
        isTrue,
      );
    });

    test('image models expose capabilityProfile directly', () {
      final model = Google(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).imageModel('gemini-2.5-flash-image');

      expect(model, isA<CapabilityDescribedModel>());
      expect(model.capabilityProfile.kind, ModelCapabilityKind.image);
      expect(
        model.capabilityProfile.supports(
          ModelCapabilityFeatureIds.imageEditing,
        ),
        isTrue,
      );
    });

    test('speech models expose capabilityProfile directly', () {
      final model = Google(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).speechModel('gemini-2.5-flash-preview-tts');

      expect(model, isA<CapabilityDescribedModel>());
      expect(model.capabilityProfile.kind, ModelCapabilityKind.speech);
      expect(
        model.capabilityProfile.supports(
          ModelCapabilityFeatureIds.speechVoiceSelection,
        ),
        isTrue,
      );
    });
  });
}

typedef _FakeTransportClient = FakeTransportClient;
