import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'elevenlabs_model_settings.dart';
import 'elevenlabs_speech_options.dart';

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
