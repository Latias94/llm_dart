import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_model_settings.dart';

ModelCapabilityProfile describeGoogleSpeechModel(
  String modelId, {
  GoogleSpeechModelSettings settings = const GoogleSpeechModelSettings(),
}) {
  return ModelCapabilityProfile(
    providerId: 'google',
    modelId: modelId,
    kind: ModelCapabilityKind.speech,
    sharedFeatures: const [
      CapabilityDescriptor(
        id: ModelCapabilityFeatureIds.speechOutputFormat,
      ),
      CapabilityDescriptor(
        id: ModelCapabilityFeatureIds.speechVoiceSelection,
      ),
    ],
    providerFeatures: [
      const ProviderFeatureDescriptor(
        providerId: 'google',
        featureId: 'api.route',
        detail: 'generateContent',
      ),
      ProviderFeatureDescriptor(
        providerId: 'google',
        featureId: 'google.speech.providerOptions',
        detail: {
          'supportedOptions': [
            'speakers',
            'temperature',
            'topP',
            'topK',
            'maxOutputTokens',
            'stopSequences',
          ],
          'defaultVoice': settings.defaultVoice,
        },
      ),
      const ProviderFeatureDescriptor(
        providerId: 'google',
        featureId: 'google.speech.multiSpeaker',
        detail: {
          'supported': true,
        },
      ),
    ],
  );
}
