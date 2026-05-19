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

String resolveElevenLabsSpeechVoiceId({
  required String? requestVoice,
  required ElevenLabsSpeechModelSettings settings,
}) {
  if (requestVoice != null && requestVoice.isNotEmpty) {
    return requestVoice;
  }

  final defaultVoiceId = settings.defaultVoiceId;
  if (defaultVoiceId != null && defaultVoiceId.isNotEmpty) {
    return defaultVoiceId;
  }

  return elevenLabsDefaultVoiceId;
}

Map<String, Object?> buildElevenLabsSpeechRequestBody(
  SpeechGenerationRequest request, {
  required String modelId,
  required ElevenLabsSpeechModelSettings settings,
  required ElevenLabsSpeechOptions? options,
}) {
  final languageCode = request.language ?? options?.languageCode;
  final speed = request.speed ?? options?.speed;

  final body = <String, Object?>{
    'text': request.text,
    'model_id': modelId,
  };

  final voiceSettings = <String, Object?>{
    if (_resolveRatio(settings.stability, options?.stability)
        case final stability?)
      'stability': stability,
    if (_resolveRatio(
      settings.similarityBoost,
      options?.similarityBoost,
    )
        case final similarityBoost?)
      'similarity_boost': similarityBoost,
    if (_resolveRatio(settings.style, options?.style) case final style?)
      'style': style,
    if (speed != null) 'speed': speed,
    if (_resolveBool(
      settings.useSpeakerBoost,
      options?.useSpeakerBoost,
    )
        case final useSpeakerBoost?)
      'use_speaker_boost': useSpeakerBoost,
  };

  if (voiceSettings.isNotEmpty) {
    body['voice_settings'] = voiceSettings;
  }

  if (languageCode != null) {
    body['language_code'] = languageCode;
  }

  if (options != null && options.pronunciationDictionaryLocators.isNotEmpty) {
    body['pronunciation_dictionary_locators'] =
        options.pronunciationDictionaryLocators
            .map(
              (locator) => {
                'pronunciation_dictionary_id':
                    locator.pronunciationDictionaryId,
                if (locator.versionId != null) 'version_id': locator.versionId,
              },
            )
            .toList(growable: false);
  }

  if (options?.seed case final seed?) {
    body['seed'] = seed;
  }

  if (options?.previousText case final previousText?) {
    body['previous_text'] = previousText;
  }

  if (options?.nextText case final nextText?) {
    body['next_text'] = nextText;
  }

  if (options != null && options.previousRequestIds.isNotEmpty) {
    body['previous_request_ids'] = options.previousRequestIds;
  }

  if (options != null && options.nextRequestIds.isNotEmpty) {
    body['next_request_ids'] = options.nextRequestIds;
  }

  if (options?.textNormalization case final textNormalization?) {
    body['apply_text_normalization'] = textNormalization.name;
  }

  if (options?.applyLanguageTextNormalization
      case final applyLanguageTextNormalization?) {
    body['apply_language_text_normalization'] = applyLanguageTextNormalization;
  }

  return body;
}

String resolveElevenLabsSpeechOutputFormat(String? outputFormat) {
  return switch (outputFormat) {
    null || '' => 'mp3_44100_128',
    'mp3' || 'mp3_128' => 'mp3_44100_128',
    'mp3_32' => 'mp3_44100_32',
    'mp3_64' => 'mp3_44100_64',
    'mp3_96' => 'mp3_44100_96',
    'mp3_192' => 'mp3_44100_192',
    'pcm' => 'pcm_44100',
    'ulaw' => 'ulaw_8000',
    _ => outputFormat,
  };
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

double? _resolveRatio(
  double? modelValue,
  double? invocationValue,
) {
  return invocationValue ?? modelValue;
}

bool? _resolveBool(
  bool? modelValue,
  bool? invocationValue,
) {
  return invocationValue ?? modelValue;
}
