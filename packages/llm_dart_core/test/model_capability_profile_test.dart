import 'package:llm_dart_core/model.dart';
import 'package:test/test.dart';

void main() {
  group('ModelCapabilityProfile', () {
    test('describes shared and provider-owned model features', () {
      final profile = ModelCapabilityProfile(
        providerId: 'openai',
        modelId: 'gpt-test',
        kind: ModelCapabilityKind.language,
        sharedFeatures: const [
          CapabilityDescriptor(
            id: ModelCapabilityFeatureIds.languageStreaming,
          ),
          CapabilityDescriptor(
            id: ModelCapabilityFeatureIds.languageImageInput,
            confidence: CapabilityConfidence.inferred,
          ),
        ],
        providerFeatures: const [
          ProviderFeatureDescriptor(
            providerId: 'openai',
            featureId: 'responses',
          ),
          ProviderFeatureDescriptor(
            providerId: 'openai',
            featureId: 'reasoningEffort',
            detail: {
              'values': ['low', 'medium', 'high']
            },
          ),
        ],
      );

      expect(profile.providerId, 'openai');
      expect(profile.modelId, 'gpt-test');
      expect(profile.kind, ModelCapabilityKind.language);
      expect(
        profile.supports(ModelCapabilityFeatureIds.languageStreaming),
        isTrue,
      );
      expect(
        profile
            .sharedFeature(ModelCapabilityFeatureIds.languageImageInput)
            ?.confidence,
        CapabilityConfidence.inferred,
      );
      expect(
        profile.providerFeature('openai', 'responses'),
        const ProviderFeatureDescriptor(
          providerId: 'openai',
          featureId: 'responses',
        ),
      );
      expect(
        profile.providerFeaturesFor('openai').map((feature) {
          return feature.featureId;
        }),
        ['responses', 'reasoningEffort'],
      );
    });

    test('checks all or any shared feature requirements', () {
      final profile = ModelCapabilityProfile(
        providerId: 'google',
        modelId: 'gemini-test',
        kind: ModelCapabilityKind.language,
        sharedFeatures: const [
          CapabilityDescriptor(
            id: ModelCapabilityFeatureIds.languageTextInput,
          ),
          CapabilityDescriptor(
            id: ModelCapabilityFeatureIds.languageFunctionTools,
          ),
        ],
      );

      expect(
        profile.supportsAll([
          ModelCapabilityFeatureIds.languageTextInput,
          ModelCapabilityFeatureIds.languageFunctionTools,
        ]),
        isTrue,
      );
      expect(
        profile.supportsAll([
          ModelCapabilityFeatureIds.languageTextInput,
          ModelCapabilityFeatureIds.languageImageInput,
        ]),
        isFalse,
      );
      expect(
        profile.supportsAny([
          ModelCapabilityFeatureIds.languageImageInput,
          ModelCapabilityFeatureIds.languageFunctionTools,
        ]),
        isTrue,
      );
    });

    test('keeps feature collections immutable', () {
      final profile = ModelCapabilityProfile(
        providerId: 'anthropic',
        modelId: 'claude-test',
        kind: ModelCapabilityKind.language,
        sharedFeatures: const [
          CapabilityDescriptor(
            id: ModelCapabilityFeatureIds.languageReasoningOutput,
          ),
        ],
      );

      expect(
        () => profile.sharedFeatures.add(
          const CapabilityDescriptor(
            id: ModelCapabilityFeatureIds.languageFileInput,
          ),
        ),
        throwsUnsupportedError,
      );
      expect(
        () => profile.providerFeatures.add(
          const ProviderFeatureDescriptor(
            providerId: 'anthropic',
            featureId: 'mcp',
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('can be exposed through the optional model marker', () {
      final model = _CapabilityAwareModel();

      expect(model.capabilityProfile.providerId, 'test');
      expect(
        model.capabilityProfile.supports(
          ModelCapabilityFeatureIds.languageStreaming,
        ),
        isTrue,
      );
    });
  });
}

final class _CapabilityAwareModel implements CapabilityDescribedModel {
  @override
  ModelCapabilityProfile get capabilityProfile {
    return ModelCapabilityProfile(
      providerId: 'test',
      modelId: 'capability-aware',
      kind: ModelCapabilityKind.language,
      sharedFeatures: const [
        CapabilityDescriptor(
          id: ModelCapabilityFeatureIds.languageStreaming,
        ),
      ],
    );
  }
}
