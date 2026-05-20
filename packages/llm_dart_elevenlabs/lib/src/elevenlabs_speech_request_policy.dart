import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'elevenlabs_model_settings.dart';
import 'elevenlabs_speech_options.dart';

ElevenLabsSpeechModelSettings resolveElevenLabsSpeechModelSettings(
  ProviderModelOptions settings,
) {
  return resolveProviderModelOptions<ElevenLabsSpeechModelSettings>(
    settings,
    parameterName: 'settings',
    expectedTypeName: 'ElevenLabsSpeechModelSettings',
    usageContext: 'ElevenLabs speech models',
  );
}

ElevenLabsSpeechOptions? resolveElevenLabsSpeechProviderOptions(
  CallOptions callOptions,
) {
  return resolveProviderInvocationOptions<ElevenLabsSpeechOptions>(
    callOptions.providerOptions,
    parameterName: 'request.callOptions.providerOptions',
    expectedTypeName: 'ElevenLabsSpeechOptions',
    usageContext: 'ElevenLabs speech models',
  );
}

void validateElevenLabsSpeechOptions(ElevenLabsSpeechOptions? options) {
  if (options == null) {
    return;
  }

  _validateRatio(options.stability, 'providerOptions.stability');
  _validateRatio(
    options.similarityBoost,
    'providerOptions.similarityBoost',
  );
  _validateRatio(options.style, 'providerOptions.style');

  if (options.seed != null &&
      (options.seed! < 0 || options.seed! > 4294967295)) {
    throw ArgumentError.value(
      options.seed,
      'providerOptions.seed',
      'ElevenLabs speech seed must be between 0 and 4294967295.',
    );
  }

  _validateIdList(
    options.previousRequestIds,
    'providerOptions.previousRequestIds',
  );
  _validateIdList(
    options.nextRequestIds,
    'providerOptions.nextRequestIds',
  );

  if (options.pronunciationDictionaryLocators.length > 3) {
    throw ArgumentError.value(
      options.pronunciationDictionaryLocators,
      'providerOptions.pronunciationDictionaryLocators',
      'ElevenLabs supports at most 3 pronunciation dictionary locators.',
    );
  }

  for (final locator in options.pronunciationDictionaryLocators) {
    if (locator.pronunciationDictionaryId.isEmpty) {
      throw ArgumentError.value(
        locator.pronunciationDictionaryId,
        'providerOptions.pronunciationDictionaryLocators',
        'Pronunciation dictionary IDs must not be empty.',
      );
    }
  }
}

void validateElevenLabsSpeechRequest(
  SpeechGenerationRequest request,
  ElevenLabsSpeechOptions? options,
) {
  validateElevenLabsSpeechOptions(options);
}

void warnElevenLabsSpeechUnsupportedRequestFields(
  SpeechGenerationRequest request,
  List<ModelWarning> warnings,
) {
  final instructions = request.instructions;
  if (instructions != null) {
    warnings.add(
      ModelWarning(
        type: ModelWarningType.unsupported,
        feature: 'instructions',
        message:
            'ElevenLabs speech models do not support instructions. Instructions parameter "$instructions" was ignored.',
      ),
    );
  }
}

void _validateRatio(
  double? value,
  String field,
) {
  if (value == null) {
    return;
  }

  if (value < 0 || value > 1) {
    throw ArgumentError.value(
      value,
      field,
      'ElevenLabs voice-setting values must be between 0 and 1.',
    );
  }
}

void _validateIdList(
  List<String> values,
  String field,
) {
  if (values.length > 3) {
    throw ArgumentError.value(
      values,
      field,
      'ElevenLabs supports at most 3 request IDs per continuity field.',
    );
  }

  if (values.any((value) => value.isEmpty)) {
    throw ArgumentError.value(
      values,
      field,
      'ElevenLabs request IDs must not be empty.',
    );
  }
}
