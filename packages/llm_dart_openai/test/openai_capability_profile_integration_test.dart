import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI capability profile integration', () {
    test('language models expose capabilityProfile directly', () {
      final model = OpenAI(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).chatModel('gpt-5.4');

      expect(model, isA<CapabilityDescribedModel>());
      expect(model.capabilityProfile.providerId, 'openai');
      expect(model.capabilityProfile.modelId, 'gpt-5.4');
      expect(model.capabilityProfile.kind, ModelCapabilityKind.language);
      expect(
        model.capabilityProfile.supports(
          ModelCapabilityFeatureIds.languageReasoningOutput,
        ),
        isTrue,
      );
      expect(
        model.capabilityProfile.providerFeature('openai', 'api.route')?.detail,
        'responses',
      );
    });

    test('language models preserve profile-specific capability routing', () {
      final model = OpenAI(
        apiKey: 'test-key',
        profile: const OpenRouterProfile(),
        transport: const _FakeTransportClient(),
      ).chatModel(
        'openai/gpt-4o-mini',
        settings: const OpenRouterChatModelSettings(
          search: OpenRouterSearchOptions.onlineModel(),
        ),
      );

      expect(model.capabilityProfile.providerId, 'openrouter');
      expect(
        model.capabilityProfile
            .providerFeature('openrouter', 'api.route')
            ?.detail,
        'chat_completions',
      );
      expect(
        model.capabilityProfile
            .providerFeature('openrouter', 'openrouter.onlineModelRouting')
            ?.detail,
        {'mode': 'onlineModel'},
      );
    });

    test('embedding models expose capabilityProfile directly', () {
      final model = OpenAI(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).embeddingModel('text-embedding-3-large');

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
      final model = OpenAI(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).imageModel('gpt-image-1');

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
      final model = OpenAI(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).speechModel('gpt-4o-mini-tts');

      expect(model, isA<CapabilityDescribedModel>());
      expect(model.capabilityProfile.kind, ModelCapabilityKind.speech);
      expect(
        model.capabilityProfile.supports(
          ModelCapabilityFeatureIds.speechVoiceSelection,
        ),
        isTrue,
      );
    });

    test('transcription models expose capabilityProfile directly', () {
      final model = OpenAI(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).transcriptionModel('gpt-4o-mini-transcribe');

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
