import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'elevenlabs_options.dart';
import 'elevenlabs_shared.dart';

ElevenLabsTranscriptionModelSettings
    resolveElevenLabsTranscriptionModelSettings(
  ProviderModelOptions settings,
) {
  return resolveProviderModelOptions<ElevenLabsTranscriptionModelSettings>(
    settings,
    parameterName: 'settings',
    expectedTypeName: 'ElevenLabsTranscriptionModelSettings',
    usageContext: 'ElevenLabs transcription models',
  );
}

ElevenLabsTranscriptionOptions? resolveElevenLabsTranscriptionProviderOptions(
  CallOptions callOptions,
) {
  return resolveProviderInvocationOptions<ElevenLabsTranscriptionOptions>(
    callOptions.providerOptions,
    parameterName: 'request.callOptions.providerOptions',
    expectedTypeName: 'ElevenLabsTranscriptionOptions',
    usageContext: 'ElevenLabs transcription models',
  );
}

void validateElevenLabsTranscriptionOptions(
  ElevenLabsTranscriptionOptions? options,
) {
  if (options == null) {
    return;
  }

  if (options.numSpeakers != null &&
      (options.numSpeakers! < 1 || options.numSpeakers! > 32)) {
    throw ArgumentError.value(
      options.numSpeakers,
      'providerOptions.numSpeakers',
      'ElevenLabs transcription numSpeakers must be between 1 and 32.',
    );
  }
}

TransportMultipartBody buildElevenLabsTranscriptionMultipartBody(
  TranscriptionRequest request, {
  required String modelId,
  required ElevenLabsTranscriptionOptions? options,
}) {
  return buildTransportMultipartBody(
    fields: [
      TransportMultipartField.file(
        name: 'file',
        filename: buildAudioFilename(request.mediaType),
        mediaType: request.mediaType,
        bytes: request.audioBytes,
      ),
      TransportMultipartField.text(
        name: 'model_id',
        value: modelId,
      ),
      if (options?.languageCode case final languageCode?)
        TransportMultipartField.text(
          name: 'language_code',
          value: languageCode,
        ),
      if (options?.tagAudioEvents case final tagAudioEvents?)
        TransportMultipartField.text(
          name: 'tag_audio_events',
          value: '$tagAudioEvents',
        ),
      if (options?.numSpeakers case final numSpeakers?)
        TransportMultipartField.text(
          name: 'num_speakers',
          value: '$numSpeakers',
        ),
      if (options?.timestampGranularity case final timestampGranularity?)
        TransportMultipartField.text(
          name: 'timestamps_granularity',
          value: timestampGranularity.name,
        ),
      if (options?.diarize case final diarize?)
        TransportMultipartField.text(
          name: 'diarize',
          value: '$diarize',
        ),
      if (options?.fileFormat case final fileFormat?)
        TransportMultipartField.text(
          name: 'file_format',
          value: fileFormat.value,
        ),
    ],
  );
}
