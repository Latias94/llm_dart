import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'elevenlabs_api_options.dart';
import 'elevenlabs_value.dart';

String normalizeElevenLabsBaseUrl(String? baseUrl) {
  final normalized =
      (baseUrl == null || baseUrl.isEmpty) ? elevenLabsDefaultBaseUrl : baseUrl;
  return normalized.endsWith('/')
      ? normalized.substring(0, normalized.length - 1)
      : normalized;
}

Map<String, Object?> decodeElevenLabsJsonObject(
  Object? body, {
  required String responseName,
}) {
  return JsonObjectResponseDecoder.decode(
    body,
    sourceName: 'ElevenLabs $responseName',
  );
}

ProviderMetadata? elevenLabsResponseMetadata(Map<String, String> headers) {
  return ProviderMetadata.forNamespace(
    'elevenlabs',
    {
      if (elevenLabsLookupHeader(headers, 'x-request-id') case final requestId?)
        'requestId': requestId,
      if (elevenLabsLookupHeader(headers, 'history-item-id')
          case final historyItemId?)
        'historyItemId': historyItemId,
      if (_tryParseInt(elevenLabsLookupHeader(headers, 'character-cost'))
          case final characterCost?)
        'characterCost': characterCost,
    },
  );
}

String buildAudioFilename(String mediaType) {
  final normalized = mediaType.split(';').first.trim().toLowerCase();
  final extension = switch (normalized) {
    'audio/mpeg' || 'audio/mp3' => 'mp3',
    'audio/wav' || 'audio/x-wav' => 'wav',
    'audio/webm' => 'webm',
    'audio/mp4' => 'mp4',
    'audio/m4a' => 'm4a',
    'audio/ogg' => 'ogg',
    'audio/flac' => 'flac',
    'audio/pcm' => 'pcm',
    _ => 'bin',
  };

  return 'audio.$extension';
}

int? _tryParseInt(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }

  return int.tryParse(value);
}
