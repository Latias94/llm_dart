import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_google/llm_dart_google.dart';
import 'package:test/test.dart';

void main() {
  group('Google model describers', () {
    test('describeGoogleChatModel describes the Gemini language surface', () {
      final profile = describeGoogleChatModel(
        'gemini-3-pro-preview',
        settings: const GoogleChatModelSettings(
          tools: [
            GoogleSearchTool(),
          ],
          includeServerSideToolInvocations: true,
        ),
      );

      expect(profile.providerId, 'google');
      expect(profile.kind, ModelCapabilityKind.language);
      expect(
        profile.supports(ModelCapabilityFeatureIds.languageStreaming),
        isTrue,
      );
      expect(
        profile.supports(ModelCapabilityFeatureIds.languageImageInput),
        isTrue,
      );
      expect(
        profile.supports(ModelCapabilityFeatureIds.languageFileInput),
        isTrue,
      );
      expect(
        profile.supports(ModelCapabilityFeatureIds.languageStructuredOutput),
        isTrue,
      );
      expect(
        profile.supports(ModelCapabilityFeatureIds.languageReasoningOutput),
        isTrue,
      );
      expect(
        profile.supports(ModelCapabilityFeatureIds.languageSourceOutput),
        isTrue,
      );
      expect(
        profile.supports(ModelCapabilityFeatureIds.languageFileOutput),
        isTrue,
      );
      expect(
        profile.providerFeature('google', 'api.route')?.detail,
        'generateContent',
      );
      expect(
        profile.providerFeature('google', 'google.nativeTools')?.detail,
        {
          'builtInTools': ['google_search', 'code_execution'],
          'configuredTools': ['google_search'],
        },
      );
      expect(
        profile
            .providerFeature('google', 'google.serverSideToolInvocations')
            ?.detail,
        {
          'supported': true,
          'mixedFunctionTools': true,
          'defaultEnabled': true,
        },
      );
    });

    test('describeGoogleChatModel keeps non-Gemini language features inferred',
        () {
      final profile = describeGoogleChatModel('models/custom-language');

      expect(
        profile.supports(ModelCapabilityFeatureIds.languageStructuredOutput),
        isFalse,
      );
      expect(
        profile.supports(ModelCapabilityFeatureIds.languageReasoningOutput),
        isFalse,
      );
      expect(
        profile.providerFeature('google', 'google.serverSideToolInvocations'),
        isNull,
      );
      expect(
        profile.providerFeature('google', 'google.reasoning')?.confidence,
        CapabilityConfidence.inferred,
      );
    });

    test(
        'describeGoogleEmbeddingModel exposes batch and dimensionality support',
        () {
      final profile = describeGoogleEmbeddingModel('text-embedding-004');

      expect(profile.kind, ModelCapabilityKind.embedding);
      expect(
        profile.supports(ModelCapabilityFeatureIds.embeddingBatch),
        isTrue,
      );
      expect(
        profile.supports(ModelCapabilityFeatureIds.embeddingDimensions),
        isTrue,
      );
      expect(
        profile
            .providerFeature('google', 'google.embedding.providerOptions')
            ?.detail,
        {
          'supportedOptions': ['taskType', 'title'],
        },
      );
    });

    test(
        'describeGoogleImageModel distinguishes Imagen multi-output and Gemini editing',
        () {
      final imagen = describeGoogleImageModel('imagen-3.0-generate-002');
      final gemini = describeGoogleImageModel('gemini-2.5-flash-image');

      expect(imagen.kind, ModelCapabilityKind.image);
      expect(
        imagen.supports(ModelCapabilityFeatureIds.imageMultipleOutput),
        isTrue,
      );
      expect(
        imagen.supports(ModelCapabilityFeatureIds.imageEditing),
        isFalse,
      );
      expect(
        imagen.providerFeature('google', 'api.route')?.detail,
        'predict',
      );

      expect(
        gemini.supports(ModelCapabilityFeatureIds.imageEditing),
        isTrue,
      );
      expect(
        gemini.supports(ModelCapabilityFeatureIds.imageMultipleOutput),
        isFalse,
      );
      expect(
        gemini.providerFeature('google', 'api.route')?.detail,
        'generateContent',
      );
      expect(
        gemini.providerFeature('google', 'google.image.inlineEditing')?.detail,
        {
          'inputMediaFamilies': ['image/*'],
        },
      );
    });

    test('describeGoogleSpeechModel exposes speech option surface', () {
      final profile = describeGoogleSpeechModel(
        'gemini-2.5-flash-preview-tts',
        settings: const GoogleSpeechModelSettings(defaultVoice: 'Kore'),
      );

      expect(profile.kind, ModelCapabilityKind.speech);
      expect(
        profile.supports(ModelCapabilityFeatureIds.speechOutputFormat),
        isTrue,
      );
      expect(
        profile.supports(ModelCapabilityFeatureIds.speechVoiceSelection),
        isTrue,
      );
      expect(
        profile
            .providerFeature('google', 'google.speech.providerOptions')
            ?.detail,
        {
          'supportedOptions': [
            'speakers',
            'temperature',
            'topP',
            'topK',
            'maxOutputTokens',
            'stopSequences',
          ],
          'defaultVoice': 'Kore',
        },
      );
    });
  });
}
