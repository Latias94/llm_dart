part of 'openai_image_model.dart';

extension _OpenAIImageResponseDecoder on OpenAIImageModel {
  ImageGenerationResult _decodeResponse(
    Object? body, {
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
          mediaType:
              b64Json == null ? null : _mediaTypeForOutputFormat(outputFormat),
        ),
      );
    }

    if (images.isEmpty) {
      throw StateError('Expected OpenAI image generation to return images.');
    }

    return ImageGenerationResult(
      images: images,
      providerMetadata: ProviderMetadata.forNamespace(
        'openai',
        {
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
}
