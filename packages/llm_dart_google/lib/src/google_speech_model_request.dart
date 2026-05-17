import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_options.dart';

GoogleSpeechModelSettings resolveGoogleSpeechModelSettings(
  ProviderModelOptions settings,
) {
  return resolveProviderModelOptions<GoogleSpeechModelSettings>(
    settings,
    parameterName: 'settings',
    expectedTypeName: 'GoogleSpeechModelSettings',
    usageContext: 'Google speech models',
  );
}

GoogleSpeechOptions? resolveGoogleSpeechProviderOptions(
  CallOptions callOptions,
) {
  return resolveProviderInvocationOptions<GoogleSpeechOptions>(
    callOptions.providerOptions,
    parameterName: 'request.callOptions.providerOptions',
    expectedTypeName: 'GoogleSpeechOptions',
    usageContext: 'Google speech models',
  );
}

void validateGoogleSpeechRequest(
  SpeechGenerationRequest request,
  GoogleSpeechOptions? options,
) {
  if (request.voice != null &&
      options != null &&
      options.speakers.isNotEmpty) {
    throw ArgumentError(
      'Google speech models do not allow request.voice together with GoogleSpeechOptions.speakers.',
    );
  }

  if ((request.voice == null || request.voice!.isEmpty) &&
      options != null &&
      options.speakers
          .any((speaker) => speaker.speaker.isEmpty || speaker.voice.isEmpty)) {
    throw ArgumentError(
      'GoogleSpeechOptions.speakers requires non-empty speaker and voice values.',
    );
  }
}

Map<String, Object?> buildGoogleSpeechRequestBody(
  SpeechGenerationRequest request, {
  required GoogleSpeechModelSettings settings,
  required GoogleSpeechOptions? options,
}) {
  return {
    'contents': [
      {
        'parts': [
          {
            'text': request.text,
          },
        ],
      },
    ],
    'generationConfig': {
      'responseModalities': ['AUDIO'],
      'speechConfig': buildGoogleSpeechConfig(
        request,
        settings: settings,
        options: options,
      ),
      if (options?.temperature case final temperature?)
        'temperature': temperature,
      if (options?.topP case final topP?) 'topP': topP,
      if (options?.topK case final topK?) 'topK': topK,
      if (options?.maxOutputTokens case final maxOutputTokens?)
        'maxOutputTokens': maxOutputTokens,
      if (options != null && options.stopSequences.isNotEmpty)
        'stopSequences': options.stopSequences,
    },
  };
}

Map<String, Object?> buildGoogleSpeechConfig(
  SpeechGenerationRequest request, {
  required GoogleSpeechModelSettings settings,
  required GoogleSpeechOptions? options,
}) {
  if (options != null && options.speakers.isNotEmpty) {
    return {
      'multiSpeakerVoiceConfig': {
        'speakerVoiceConfigs': [
          for (final speaker in options.speakers)
            {
              'speaker': speaker.speaker,
              'voiceConfig': {
                'prebuiltVoiceConfig': {
                  'voiceName': speaker.voice,
                },
              },
            },
        ],
      },
    };
  }

  final voice = request.voice == null || request.voice!.isEmpty
      ? settings.defaultVoice
      : request.voice!;

  return {
    'voiceConfig': {
      'prebuiltVoiceConfig': {
        'voiceName': voice,
      },
    },
  };
}
