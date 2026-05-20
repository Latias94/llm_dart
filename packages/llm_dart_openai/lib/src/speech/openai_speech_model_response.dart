import 'dart:typed_data';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../common/openai_json_value.dart';

Uint8List decodeOpenAISpeechResponseBytes(Object? body) {
  return openAIRequiredBytes(
    body,
    path: 'speech_response.body',
    sourceName: 'OpenAI speech response',
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
    mediaType: openAILookupHeader(headers, 'content-type') ??
        defaultOpenAISpeechMediaTypeForOutputFormat(outputFormat),
    warnings: warnings,
    responseMetadata: ModelResponseMetadata(
      timestamp: DateTime.now().toUtc(),
      modelId: modelId,
      headers: headers,
    ),
  );
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
