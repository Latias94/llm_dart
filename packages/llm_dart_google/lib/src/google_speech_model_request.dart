import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_model_settings.dart';
import 'google_speech_options.dart';

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
  if (request.voice != null && options != null && options.speakers.isNotEmpty) {
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

List<ModelWarning> buildGoogleSpeechRequestWarnings(
  SpeechGenerationRequest request,
) {
  final outputFormat = request.outputFormat;
  final instructions = request.instructions;
  final speed = request.speed;
  final language = request.language;

  return [
    if (outputFormat != null)
      ModelWarning(
        type: ModelWarningType.unsupported,
        feature: 'outputFormat',
        message:
            'Google speech models do not support selecting an output format through the shared request field. outputFormat "$outputFormat" was ignored.',
      ),
    if (instructions != null)
      ModelWarning(
        type: ModelWarningType.unsupported,
        feature: 'instructions',
        message:
            'Google speech models do not support speech instructions. instructions was ignored.',
      ),
    if (speed != null)
      ModelWarning(
        type: ModelWarningType.unsupported,
        feature: 'speed',
        message:
            'Google speech models do not support speech speed selection. speed $speed was ignored.',
      ),
    if (language != null)
      ModelWarning(
        type: ModelWarningType.unsupported,
        feature: 'language',
        message:
            'Google speech models do not support language selection through the shared request field. language "$language" was ignored.',
      ),
  ];
}
