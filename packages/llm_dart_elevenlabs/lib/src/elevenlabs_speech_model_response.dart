import 'dart:typed_data';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'elevenlabs_shared.dart';

SpeechGenerationResult decodeElevenLabsSpeechResponse({
  required Object? body,
  required String modelId,
  required Map<String, String> headers,
  required String outputFormat,
}) {
  final audioBytes = decodeElevenLabsSpeechBytes(body);
  if (audioBytes.isEmpty) {
    throw StateError(
      'Expected ElevenLabs speech generation to return audio bytes.',
    );
  }

  return SpeechGenerationResult(
    audioBytes: audioBytes,
    mediaType: lookupHeader(headers, 'content-type') ??
        defaultElevenLabsSpeechMediaTypeForOutputFormat(outputFormat),
    responseMetadata: ModelResponseMetadata(
      timestamp: DateTime.now().toUtc(),
      modelId: modelId,
      headers: headers,
    ),
    providerMetadata: elevenLabsResponseMetadata(headers),
  );
}

Uint8List decodeElevenLabsSpeechBytes(Object? body) {
  if (body is Uint8List) {
    return body;
  }

  if (body is List<int>) {
    return Uint8List.fromList(body);
  }

  if (body is List) {
    return Uint8List.fromList(
      body.map((value) {
        if (value is! int) {
          throw StateError(
            'Expected ElevenLabs speech byte value to be int, got ${value.runtimeType}.',
          );
        }

        return value;
      }).toList(),
    );
  }

  throw StateError(
    'Expected ElevenLabs speech response bytes but received ${body.runtimeType}.',
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
