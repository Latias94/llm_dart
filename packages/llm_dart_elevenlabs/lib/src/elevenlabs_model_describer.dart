import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'elevenlabs_model_settings.dart';
import 'elevenlabs_speech_options.dart';

const List<String> _elevenLabsSpeechOptions = [
  'outputFormat',
  'languageCode',
  'speed',
  'pronunciationDictionaryLocators',
  'seed',
  'previousText',
  'nextText',
  'previousRequestIds',
  'nextRequestIds',
  'textNormalization',
  'applyLanguageTextNormalization',
  'enableLogging',
  'optimizeStreamingLatency',
  'stability',
  'similarityBoost',
  'style',
  'useSpeakerBoost',
];

const List<String> _elevenLabsTranscriptionOptions = [
  'languageCode',
  'tagAudioEvents',
  'numSpeakers',
  'timestampGranularity',
  'diarize',
  'fileFormat',
  'enableLogging',
];

ModelCapabilityProfile describeElevenLabsSpeechModel(
  String modelId, {
  ElevenLabsSpeechModelSettings settings =
      const ElevenLabsSpeechModelSettings(),
}) {
  return ModelCapabilityProfile(
    providerId: 'elevenlabs',
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
        providerId: 'elevenlabs',
        featureId: 'api.route',
        detail: 'text_to_speech',
      ),
      ProviderFeatureDescriptor(
        providerId: 'elevenlabs',
        featureId: 'elevenlabs.speech.providerOptions',
        detail: {
          'supportedOptions': _elevenLabsSpeechOptions,
          'defaultVoiceId': settings.defaultVoiceId ?? elevenLabsDefaultVoiceId,
        },
      ),
      const ProviderFeatureDescriptor(
        providerId: 'elevenlabs',
        featureId: 'elevenlabs.speech.pronunciationDictionaries',
        detail: {
          'supported': true,
          'maxLocators': 3,
        },
      ),
      const ProviderFeatureDescriptor(
        providerId: 'elevenlabs',
        featureId: 'elevenlabs.speech.requestContinuity',
        detail: {
          'previousText': true,
          'nextText': true,
          'previousRequestIds': true,
          'nextRequestIds': true,
        },
      ),
    ],
  );
}

ModelCapabilityProfile describeElevenLabsTranscriptionModel(String modelId) {
  return ModelCapabilityProfile(
    providerId: 'elevenlabs',
    modelId: modelId,
    kind: ModelCapabilityKind.transcription,
    sharedFeatures: const [
      CapabilityDescriptor(
        id: ModelCapabilityFeatureIds.transcriptionLanguageHints,
      ),
      CapabilityDescriptor(
        id: ModelCapabilityFeatureIds.transcriptionTimestamps,
      ),
    ],
    providerFeatures: const [
      ProviderFeatureDescriptor(
        providerId: 'elevenlabs',
        featureId: 'api.route',
        detail: 'speech_to_text',
      ),
      ProviderFeatureDescriptor(
        providerId: 'elevenlabs',
        featureId: 'elevenlabs.transcription.providerOptions',
        detail: {
          'supportedOptions': _elevenLabsTranscriptionOptions,
        },
      ),
      ProviderFeatureDescriptor(
        providerId: 'elevenlabs',
        featureId: 'elevenlabs.transcription.diarization',
        detail: {
          'supported': true,
          'speakerRange': [1, 32],
        },
      ),
    ],
  );
}
