import 'package:llm_dart_community/llm_dart_community.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('Ollama model describers', () {
    test('describeOllamaChatModel exposes a conservative chat surface', () {
      final profile = describeOllamaChatModel('llama3.1:8b');

      expect(profile.providerId, 'ollama');
      expect(profile.kind, ModelCapabilityKind.language);
      expect(
        profile.supports(ModelCapabilityFeatureIds.languageStreaming),
        isTrue,
      );
      expect(
        profile.supports(ModelCapabilityFeatureIds.languageTextInput),
        isTrue,
      );
      expect(
        profile.supports(ModelCapabilityFeatureIds.languageStructuredOutput),
        isTrue,
      );
      expect(
        profile.supports(ModelCapabilityFeatureIds.languageImageInput),
        isFalse,
      );
      expect(
        profile.supports(ModelCapabilityFeatureIds.languageToolChoice),
        isFalse,
      );
      expect(
        profile.providerFeature('ollama', 'api.route')?.detail,
        'chat',
      );
      expect(
        profile.providerFeature('ollama', 'ollama.toolSelection')?.detail,
        {
          'automaticOnly': true,
          'explicitChoice': false,
        },
      );
    });

    test('describeOllamaChatModel marks vision and thinking hints as inferred',
        () {
      final profile = describeOllamaChatModel('llama3.2-vision-r1');

      expect(
        profile.supports(ModelCapabilityFeatureIds.languageImageInput),
        isTrue,
      );
      expect(
        profile
            .sharedFeature(ModelCapabilityFeatureIds.languageImageInput)
            ?.confidence,
        CapabilityConfidence.inferred,
      );
      expect(
        profile.supports(ModelCapabilityFeatureIds.languageReasoningOutput),
        isTrue,
      );
      expect(
        profile
            .sharedFeature(ModelCapabilityFeatureIds.languageReasoningOutput)
            ?.confidence,
        CapabilityConfidence.inferred,
      );
      expect(
        profile.providerFeature('ollama', 'ollama.imageInputs')?.detail,
        {
          'inputMediaFamilies': ['image/*'],
          'sharedFileInput': false,
        },
      );
      expect(
        profile.providerFeature('ollama', 'ollama.thinking')?.detail,
        {
          'toggle': 'providerOptions.reasoning',
          'resultSurface': 'reasoning',
        },
      );
    });

    test('describeOllamaEmbeddingModel exposes the batch embedding surface',
        () {
      final profile = describeOllamaEmbeddingModel('nomic-embed-text');

      expect(profile.providerId, 'ollama');
      expect(profile.kind, ModelCapabilityKind.embedding);
      expect(
        profile.supports(ModelCapabilityFeatureIds.embeddingBatch),
        isTrue,
      );
      expect(
        profile.supports(ModelCapabilityFeatureIds.embeddingDimensions),
        isFalse,
      );
      expect(
        profile.providerFeature('ollama', 'api.route')?.detail,
        'embed',
      );
    });
  });
}
