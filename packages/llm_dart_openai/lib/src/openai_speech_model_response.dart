import 'dart:typed_data';

import 'package:llm_dart_provider/llm_dart_provider.dart';

Uint8List decodeOpenAISpeechResponseBytes(Object? body) {
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
            'Expected speech byte value to be int, got ${value.runtimeType}.',
          );
        }

        return value;
      }).toList(),
    );
  }

  throw StateError(
    'Expected OpenAI speech response bytes but received ${body.runtimeType}.',
  );
}

SpeechGenerationResult decodeOpenAISpeechResponse({
  required Object? body,
  required String modelId,
  required Map<String, String> headers,
  required String outputFormat,
  List<ModelWarning> warnings = const [],
}) {
  final audioBytes = decodeOpenAISpeechResponseBytes(body);
  if (audioBytes.isEmpty) {
    throw StateError(
      'Expected OpenAI speech generation to return audio bytes.',
    );
  }

  return SpeechGenerationResult(
    audioBytes: audioBytes,
    mediaType: lookupOpenAISpeechHeader(headers, 'content-type') ??
        defaultOpenAISpeechMediaTypeForOutputFormat(outputFormat),
    warnings: warnings,
    responseMetadata: ModelResponseMetadata(
      timestamp: DateTime.now().toUtc(),
      modelId: modelId,
      headers: headers,
    ),
  );
}

String? lookupOpenAISpeechHeader(
  Map<String, String> headers,
  String name,
) {
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == name.toLowerCase()) {
      return entry.value;
    }
  }

  return null;
}

String defaultOpenAISpeechMediaTypeForOutputFormat(String? outputFormat) {
  return switch (outputFormat) {
    'wav' => 'audio/wav',
    'opus' => 'audio/opus',
    'aac' => 'audio/aac',
    'flac' => 'audio/flac',
    'pcm' => 'audio/pcm',
    _ => 'audio/mpeg',
  };
}
