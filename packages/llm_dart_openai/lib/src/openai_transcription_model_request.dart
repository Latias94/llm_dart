import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_model_settings.dart';
import 'openai_non_text_model_support.dart';
import 'openai_transcription_options.dart';

OpenAITranscriptionModelSettings resolveOpenAITranscriptionModelSettings(
  ProviderModelOptions settings,
) {
  return resolveOpenAIModelSettings<OpenAITranscriptionModelSettings>(
    settings,
    parameterName: 'settings',
    expectedTypeName:
        'OpenAITranscriptionModelSettings for OpenAI-family transcription models',
  );
}

OpenAITranscriptionOptions? resolveOpenAITranscriptionProviderOptions(
  CallOptions callOptions,
) {
  return resolveOpenAIProviderOptions<OpenAITranscriptionOptions>(
    callOptions,
    parameterName: 'request.callOptions.providerOptions',
    expectedTypeName:
        'OpenAITranscriptionOptions for OpenAI-family transcription models',
  );
}

void validateOpenAITranscriptionOptions(
  OpenAITranscriptionOptions? options,
) {
  if (options == null || options.temperature == null) {
    return;
  }

  final temperature = options.temperature!;
  if (temperature < 0 || temperature > 1) {
    throw ArgumentError.value(
      temperature,
      'providerOptions.temperature',
      'OpenAI transcription temperature must be between 0 and 1.',
    );
  }
}

OpenAITranscriptionResponseFormat resolveOpenAITranscriptionResponseFormat({
  required String modelId,
  required OpenAITranscriptionOptions? options,
}) {
  if (options?.responseFormat case final responseFormat?) {
    return responseFormat;
  }

  if (options == null || options.timestampGranularities.isEmpty) {
    return OpenAITranscriptionResponseFormat.json;
  }

  if (usesOpenAIJsonTimestampTranscriptionFormat(modelId)) {
    return OpenAITranscriptionResponseFormat.json;
  }

  return OpenAITranscriptionResponseFormat.verboseJson;
}

void validateOpenAITranscriptionTimestampResponseFormat({
  required String modelId,
  required OpenAITranscriptionResponseFormat responseFormat,
  required OpenAITranscriptionOptions? options,
}) {
  if (options == null || options.timestampGranularities.isEmpty) {
    return;
  }

  if (responseFormat == OpenAITranscriptionResponseFormat.verboseJson) {
    return;
  }

  if (usesOpenAIJsonTimestampTranscriptionFormat(modelId) &&
      responseFormat == OpenAITranscriptionResponseFormat.json) {
    return;
  }

  final expected = usesOpenAIJsonTimestampTranscriptionFormat(modelId)
      ? 'json or verboseJson'
      : 'verboseJson';
  throw ArgumentError(
    'OpenAITranscriptionOptions.timestampGranularities require responseFormat=$expected for $modelId.',
  );
}

TransportMultipartBody buildOpenAITranscriptionMultipartBody({
  required String modelId,
  required TranscriptionRequest request,
  required OpenAITranscriptionOptions? options,
  required OpenAITranscriptionResponseFormat responseFormat,
}) {
  return buildTransportMultipartBody(
    fields: [
      TransportMultipartField.file(
        name: 'file',
        filename: buildOpenAITranscriptionFilename(request.mediaType),
        mediaType: request.mediaType,
        bytes: request.audioBytes,
      ),
      TransportMultipartField.text(
        name: 'model',
        value: modelId,
      ),
      for (final include in options?.include ?? const <String>[])
        TransportMultipartField.text(
          name: 'include[]',
          value: include,
        ),
      if (options?.language case final language?)
        TransportMultipartField.text(
          name: 'language',
          value: language,
        ),
      if (options?.prompt case final prompt?)
        TransportMultipartField.text(
          name: 'prompt',
          value: prompt,
        ),
      if (options != null)
        TransportMultipartField.text(
          name: 'temperature',
          value: (options.temperature ?? 0).toString(),
        ),
      TransportMultipartField.text(
        name: 'response_format',
        value: responseFormat.value,
      ),
      for (final granularity in options?.timestampGranularities ?? const [])
        TransportMultipartField.text(
          name: 'timestamp_granularities[]',
          value: granularity.value,
        ),
    ],
  );
}

bool usesOpenAIJsonTimestampTranscriptionFormat(String modelId) {
  return modelId == 'gpt-4o-transcribe' || modelId == 'gpt-4o-mini-transcribe';
}

String buildOpenAITranscriptionFilename(String mediaType) {
  final normalized = mediaType.split(';').first.trim().toLowerCase();
  final extension = switch (normalized) {
    'audio/mpeg' || 'audio/mp3' => 'mp3',
    'audio/wav' => 'wav',
    'audio/x-wav' => 'wav',
    'audio/webm' => 'webm',
    'audio/mp4' => 'mp4',
    'audio/m4a' => 'm4a',
    'audio/ogg' => 'ogg',
    'audio/flac' => 'flac',
    _ => 'bin',
  };

  return 'audio.$extension';
}
