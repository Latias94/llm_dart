import 'dart:typed_data';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'elevenlabs_value.dart';
import 'elevenlabs_shared.dart';

SpeechGenerationResult decodeElevenLabsSpeechResponse({
  required Object? body,
  required String modelId,
  required Map<String, String> headers,
  required String outputFormat,
  List<ModelWarning> warnings = const [],
}) {
  final audioBytes = decodeElevenLabsSpeechBytes(body);
  if (audioBytes.isEmpty) {
    throw StateError(
      'Expected ElevenLabs speech generation to return audio bytes.',
    );
  }

  return SpeechGenerationResult(
    audioBytes: audioBytes,
    mediaType: elevenLabsLookupHeader(headers, 'content-type') ??
        defaultElevenLabsSpeechMediaTypeForOutputFormat(outputFormat),
    warnings: warnings,
    responseMetadata: ModelResponseMetadata(
      timestamp: DateTime.now().toUtc(),
      modelId: modelId,
      headers: headers,
    ),
    providerMetadata: elevenLabsResponseMetadata(headers),
  );
}

Uint8List decodeElevenLabsSpeechBytes(Object? body) {
  return elevenLabsRequiredBytes(
    body,
    path: 'speech_response.body',
    sourceName: 'ElevenLabs speech response',
  );
}

String defaultElevenLabsSpeechMediaTypeForOutputFormat(String outputFormat) {
  if (outputFormat.startsWith('pcm_')) {
    return 'audio/pcm';
  }

  if (outputFormat.startsWith('ulaw_')) {
    return 'audio/basic';
  }

  return 'audio/mpeg';
}
