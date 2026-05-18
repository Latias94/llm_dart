import 'dart:convert';
import 'dart:typed_data';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_shared.dart';

SpeechGenerationResult decodeGoogleSpeechResponse({
  required Object? body,
  required String modelId,
  required Map<String, String> headers,
  List<ModelWarning> warnings = const [],
}) {
  final json = decodeGoogleSpeechJsonObject(body);
  final candidates = asList(json['candidates']);
  if (candidates.isEmpty) {
    throw StateError(
      'Expected a Google speech response with at least one candidate.',
    );
  }

  final bytesBuilder = BytesBuilder(copy: false);
  final finishReasons = <String>[];
  String? mediaType;

  for (var index = 0; index < candidates.length; index += 1) {
    final candidate = asMap(candidates[index]);
    if (candidate == null) {
      throw StateError(
        'Expected Google speech candidate $index to be a JSON object.',
      );
    }

    final finishReason = asString(candidate['finishReason']);
    if (finishReason != null && finishReason.isNotEmpty) {
      finishReasons.add(finishReason);
    }

    final content = asMap(candidate['content']);
    final parts = asList(content?['parts']);
    for (final partValue in parts) {
      final part = asMap(partValue);
      final inlineData = asMap(part?['inlineData']);
      final bytes = decodeBase64(asString(inlineData?['data']));
      if (bytes == null || bytes.isEmpty) {
        continue;
      }

      bytesBuilder.add(bytes);
      mediaType ??= asString(inlineData?['mimeType']);
    }
  }

  final audioBytes = bytesBuilder.takeBytes();
  if (audioBytes.isEmpty) {
    throw StateError(
      'Expected Google speech generation to return audio bytes.',
    );
  }

  return SpeechGenerationResult(
    audioBytes: Uint8List.fromList(audioBytes),
    mediaType: mediaType ?? 'audio/pcm',
    warnings: warnings,
    responseMetadata: ModelResponseMetadata(
      timestamp: DateTime.now().toUtc(),
      modelId: modelId,
      headers: headers,
    ),
    providerMetadata: googleProviderMetadata(
      {
        'generationApi': 'generateContent',
        if (asString(json['modelVersion']) case final modelVersion?)
          'modelVersion': modelVersion,
        if (asMap(json['usageMetadata']) case final usageMetadata?)
          'usage': normalizeJsonValue(usageMetadata),
        if (finishReasons.isNotEmpty) 'finishReasons': finishReasons,
      },
    ),
  );
}

Map<String, Object?> decodeGoogleSpeechJsonObject(Object? body) {
  if (body is Map<String, Object?>) {
    return body;
  }

  if (body is Map) {
    return Map<String, Object?>.from(body);
  }

  if (body is String) {
    final decoded = jsonDecode(body);
    if (decoded is Map) {
      return Map<String, Object?>.from(decoded);
    }
  }

  throw StateError(
    'Expected a Google speech JSON object response but received ${body.runtimeType}.',
  );
}
