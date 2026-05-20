import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_transcription_options.dart';

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
