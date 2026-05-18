import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_json_support.dart';
import 'openai_non_text_model_support.dart';
import 'openai_options.dart';

ImageGenerationResult decodeOpenAIImageResponse({
  required Object? body,
  required String modelId,
  required Map<String, String> headers,
  required OpenAIImageResponseFormat? requestedResponseFormat,
}) {
  final json = decodeOpenAIJsonObject(
    body,
    responseName: 'image generation',
  );
  final data = json['data'];
  if (data is! List) {
    throw StateError(
      'Expected an OpenAI image generation response with a data list.',
    );
  }

  final outputFormat = openAIStringOrNull(json['output_format']);
  final revisedPrompts = <String>[];
  final images = <GeneratedImage>[];
  final imageMetadata = <Map<String, Object?>>[];
  final usage = decodeOpenAIImageUsage(json['usage']);
  final usageDetails = openAIImageUsageDetails(json['usage']);

  for (var index = 0; index < data.length; index += 1) {
    final item = data[index];
    if (item is! Map) {
      throw StateError(
        'Expected OpenAI image item $index to be a JSON object.',
      );
    }

    final map = Map<String, Object?>.from(item);
    final revisedPrompt = openAIStringOrNull(map['revised_prompt']);
    if (revisedPrompt != null && revisedPrompt.isNotEmpty) {
      revisedPrompts.add(revisedPrompt);
    }
    final metadata = openAIImageMetadata(
      json,
      item: map,
      outputFormat: outputFormat,
      tokenDetails: usageDetails,
      index: index,
      total: data.length,
    );
    imageMetadata.add(metadata);

    final b64Json = openAIStringOrNull(map['b64_json']);
    final url = openAIStringOrNull(map['url']);
    if (b64Json == null && url == null) {
      throw StateError(
        'Expected OpenAI image item $index to contain either b64_json or url.',
      );
    }

    images.add(
      GeneratedImage(
        uri: url == null ? null : Uri.tryParse(url),
        bytes: b64Json == null ? null : base64Decode(b64Json),
        mediaType: b64Json == null
            ? null
            : mediaTypeForOpenAIImageFormat(outputFormat),
        providerMetadata: ProviderMetadata.forNamespace('openai', metadata),
      ),
    );
  }

  if (images.isEmpty) {
    throw StateError('Expected OpenAI image generation to return images.');
  }

  return ImageGenerationResult(
    images: images,
    usage: usage,
    responseMetadata: ModelResponseMetadata(
      timestamp: DateTime.now().toUtc(),
      modelId: modelId,
      headers: headers,
    ),
    providerMetadata: ProviderMetadata.forNamespace(
      'openai',
      {
        'images': imageMetadata,
        if (json['created'] != null) 'created': json['created'],
        if (json['size'] != null) 'size': json['size'],
        if (json['quality'] != null) 'quality': json['quality'],
        if (json['background'] != null) 'background': json['background'],
        if (json['output_format'] != null)
          'outputFormat': json['output_format'],
        if (requestedResponseFormat != null)
          'responseFormat': requestedResponseFormat.value,
        if (revisedPrompts.isNotEmpty) 'revisedPrompts': revisedPrompts,
        if (json['usage'] != null) 'usage': json['usage'],
      },
    ),
  );
}

UsageStats? decodeOpenAIImageUsage(Object? value) {
  final map = asOpenAIImageMap(value);
  if (map == null) {
    return null;
  }

  final usage = UsageStats(
    inputTokens: openAIIntOrNull(map['input_tokens']),
    outputTokens: openAIIntOrNull(map['output_tokens']),
    totalTokens: openAIIntOrNull(map['total_tokens']),
  );

  return usage.isEmpty ? null : usage;
}

Map<String, Object?>? openAIImageUsageDetails(Object? value) {
  final map = asOpenAIImageMap(value);
  return asOpenAIImageMap(map?['input_tokens_details']);
}

Map<String, Object?> openAIImageMetadata(
  Map<String, Object?> response, {
  required Map<String, Object?> item,
  required String? outputFormat,
  required Map<String, Object?>? tokenDetails,
  required int index,
  required int total,
}) {
  return {
    if (openAIStringOrNull(item['revised_prompt']) case final revisedPrompt?
        when revisedPrompt.isNotEmpty)
      'revisedPrompt': revisedPrompt,
    if (response['created'] != null) 'created': response['created'],
    if (response['size'] != null) 'size': response['size'],
    if (response['quality'] != null) 'quality': response['quality'],
    if (response['background'] != null) 'background': response['background'],
    if (outputFormat != null) 'outputFormat': outputFormat,
    ...distributeOpenAIImageTokenDetails(
      tokenDetails,
      index: index,
      total: total,
    ),
  };
}

Map<String, Object?> distributeOpenAIImageTokenDetails(
  Map<String, Object?>? details, {
  required int index,
  required int total,
}) {
  if (details == null || total < 1) {
    return const {};
  }

  final result = <String, Object?>{};
  final imageTokens = openAIIntOrNull(details['image_tokens']);
  if (imageTokens != null) {
    result['imageTokens'] = distributedOpenAIImageTokenCount(
      imageTokens,
      index: index,
      total: total,
    );
  }

  final textTokens = openAIIntOrNull(details['text_tokens']);
  if (textTokens != null) {
    result['textTokens'] = distributedOpenAIImageTokenCount(
      textTokens,
      index: index,
      total: total,
    );
  }

  return result;
}

int distributedOpenAIImageTokenCount(
  int value, {
  required int index,
  required int total,
}) {
  final base = value ~/ total;
  final remainder = value - base * (total - 1);
  return index == total - 1 ? remainder : base;
}

Map<String, Object?>? asOpenAIImageMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }

  if (value is Map) {
    return Map<String, Object?>.from(value);
  }

  return null;
}

String mediaTypeForOpenAIImageFormat(String? outputFormat) {
  return switch (outputFormat) {
    'jpeg' => 'image/jpeg',
    'webp' => 'image/webp',
    _ => 'image/png',
  };
}
