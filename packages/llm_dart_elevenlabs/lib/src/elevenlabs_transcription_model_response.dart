import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'elevenlabs_shared.dart';

TranscriptionResult decodeElevenLabsTranscriptionResponse({
  required Object? body,
  required String modelId,
  required Map<String, String> headers,
}) {
  final json = decodeElevenLabsTranscriptionJsonObject(body);
  final text = asElevenLabsTranscriptionString(json['text']);
  if (text == null || text.isEmpty) {
    throw StateError(
      'Expected ElevenLabs transcription response to contain non-empty text.',
    );
  }

  final segments = decodeElevenLabsTranscriptionSegments(json['words']);
  final responseMetadata = elevenLabsResponseMetadata(headers);
  final bodyMetadata = ProviderMetadata.forNamespace(
    'elevenlabs',
    {
      if (json['language_code'] != null) 'languageCode': json['language_code'],
      if (json['language_probability'] != null)
        'languageProbability': json['language_probability'],
      if (json['transcription_id'] != null)
        'transcriptionId': json['transcription_id'],
      if (json['words'] != null) 'words': json['words'],
      if (json['additional_formats'] != null)
        'additionalFormats': json['additional_formats'],
    },
  );

  return TranscriptionResult(
    text: text,
    segments: segments,
    language: asElevenLabsTranscriptionString(json['language_code']),
    durationSeconds: segments.isEmpty ? null : segments.last.endSeconds,
    responseMetadata: ModelResponseMetadata(
      timestamp: DateTime.now().toUtc(),
      modelId: modelId,
      headers: headers,
    ),
    providerMetadata: ProviderMetadata.mergeNullable(
      responseMetadata,
      bodyMetadata,
    ),
  );
}

Map<String, Object?> decodeElevenLabsTranscriptionJsonObject(Object? body) {
  return decodeElevenLabsJsonObject(
    body,
    responseName: 'transcription',
  );
}

String? asElevenLabsTranscriptionString(Object? value) {
  return value is String ? value : null;
}

List<TranscriptionSegment> decodeElevenLabsTranscriptionSegments(
  Object? value,
) {
  if (value is! List || value.isEmpty) {
    return const [];
  }

  return value
      .whereType<Map>()
      .map(
        (item) => Map<String, Object?>.from(item),
      )
      .map(
        (item) => TranscriptionSegment(
          text: asElevenLabsTranscriptionString(item['text']) ?? '',
          startSeconds: asElevenLabsTranscriptionDouble(item['start']) ?? 0,
          endSeconds: asElevenLabsTranscriptionDouble(item['end']) ?? 0,
        ),
      )
      .toList(growable: false);
}

double? asElevenLabsTranscriptionDouble(Object? value) {
  return value is num ? value.toDouble() : null;
}
