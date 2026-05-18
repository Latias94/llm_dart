import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'google_image_model_transport.dart';
import 'google_shared.dart';

ImageGenerationResult decodeGoogleImageResponse({
  required Object? body,
  required String modelId,
  required GoogleImageRequestRoute route,
  required Map<String, String> headers,
}) {
  final json = decodeGoogleImageJsonObject(body);
  return switch (route) {
    GoogleImageRequestRoute.predict => decodeGoogleImagenResponse(
        json,
        modelId: modelId,
        headers: headers,
      ),
    GoogleImageRequestRoute.generateContent => decodeGoogleGeminiImageResponse(
        json,
        modelId: modelId,
        headers: headers,
      ),
  };
}

ImageGenerationResult decodeGoogleImagenResponse(
  Map<String, Object?> json, {
  required String modelId,
  required Map<String, String> headers,
}) {
  final predictions = asList(json['predictions']);
  if (predictions.isEmpty) {
    throw StateError(
      'Expected a Google Imagen response with at least one prediction.',
    );
  }

  final images = <GeneratedImage>[];
  for (var index = 0; index < predictions.length; index += 1) {
    final prediction = asMap(predictions[index]);
    final bytes = decodeBase64(asString(prediction?['bytesBase64Encoded']));
    if (bytes == null || bytes.isEmpty) {
      throw StateError(
        'Expected Google Imagen prediction $index to contain bytesBase64Encoded.',
      );
    }

    images.add(
      GeneratedImage(
        bytes: bytes,
        mediaType: 'image/png',
        providerMetadata: googleProviderMetadata({
          'generationApi': 'predict',
        }),
      ),
    );
  }

  return ImageGenerationResult(
    images: images,
    responseMetadata: ModelResponseMetadata(
      timestamp: DateTime.now().toUtc(),
      modelId: modelId,
      headers: headers,
    ),
    providerMetadata: googleProviderMetadata(
      {
        'generationApi': 'predict',
      },
    ),
  );
}

ImageGenerationResult decodeGoogleGeminiImageResponse(
  Map<String, Object?> json, {
  required String modelId,
  required Map<String, String> headers,
}) {
  final candidates = asList(json['candidates']);
  if (candidates.isEmpty) {
    throw StateError(
      'Expected a Google Gemini image response with at least one candidate.',
    );
  }

  final images = <GeneratedImage>[];
  final revisedPrompts = <String>[];
  final finishReasons = <String>[];
  final modelVersion = asString(json['modelVersion']);

  for (var index = 0; index < candidates.length; index += 1) {
    final candidate = asMap(candidates[index]);
    if (candidate == null) {
      throw StateError(
        'Expected Google Gemini image candidate $index to be a JSON object.',
      );
    }

    final finishReason = asString(candidate['finishReason']);
    if (finishReason != null && finishReason.isNotEmpty) {
      finishReasons.add(finishReason);
    }

    final content = asMap(candidate['content']);
    final parts = asList(content?['parts']);
    final textParts = <String>[];

    for (final partValue in parts) {
      final part = asMap(partValue);
      if (part == null) {
        continue;
      }

      final text = asString(part['text']);
      if (text != null && text.isNotEmpty) {
        textParts.add(text);
      }

      final inlineData = asMap(part['inlineData']);
      final bytes = decodeBase64(asString(inlineData?['data']));
      if (bytes == null || bytes.isEmpty) {
        continue;
      }

      images.add(
        GeneratedImage(
          bytes: bytes,
          mediaType: asString(inlineData?['mimeType']) ?? 'image/png',
          providerMetadata: googleProviderMetadata({
            'generationApi': 'generateContent',
            if (modelVersion != null) 'modelVersion': modelVersion,
            if (finishReason != null) 'finishReason': finishReason,
          }),
        ),
      );
    }

    if (textParts.isNotEmpty) {
      revisedPrompts.add(textParts.join('\n'));
    }
  }

  if (images.isEmpty) {
    throw StateError(
      'Expected Google Gemini image generation to return image bytes.',
    );
  }

  return ImageGenerationResult(
    images: images,
    usage: decodeGoogleUsage(asMap(json['usageMetadata'])),
    responseMetadata: ModelResponseMetadata(
      timestamp: DateTime.now().toUtc(),
      modelId: modelId,
      headers: headers,
    ),
    providerMetadata: googleProviderMetadata(
      {
        'generationApi': 'generateContent',
        if (modelVersion != null) 'modelVersion': modelVersion,
        if (asMap(json['promptFeedback']) case final promptFeedback?)
          'promptFeedback': normalizeJsonValue(promptFeedback),
        if (asMap(json['usageMetadata']) case final usageMetadata?)
          'usage': normalizeJsonValue(usageMetadata),
        if (revisedPrompts.isNotEmpty) 'revisedPrompts': revisedPrompts,
        if (finishReasons.isNotEmpty) 'finishReasons': finishReasons,
      },
    ),
  );
}

Map<String, Object?> decodeGoogleImageJsonObject(Object? body) {
  return JsonObjectResponseDecoder.decode(
    body,
    sourceName: 'Google image',
  );
}
