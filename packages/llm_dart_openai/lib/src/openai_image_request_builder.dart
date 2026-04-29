part of 'openai_image_model.dart';

extension _OpenAIImageRequestBuilder on OpenAIImageModel {
  TransportRequest _buildGenerationTransportRequest(
    ImageGenerationRequest request, {
    required OpenAIImageOptions? options,
  }) {
    return TransportRequest(
      uri: imageGenerationUri,
      method: TransportMethod.post,
      headers: {
        ...defaultHeaders,
        'content-type': 'application/json',
        'accept': 'application/json',
        if (request.callOptions.headers case final headers?) ...headers,
      },
      body: {
        'model': modelId,
        'prompt': request.prompt,
        'n': request.count,
        if (request.size != null) 'size': request.size,
        if (options?.style case final style?) 'style': style.value,
        if (options?.quality case final quality?) 'quality': quality.value,
        if (options?.background case final background?)
          'background': background.value,
        if (options?.outputFormat case final outputFormat?)
          'output_format': outputFormat.value,
        if (options?.user case final user?) 'user': user,
        if (_shouldIncludeResponseFormat(modelId))
          'response_format':
              (options?.responseFormat ?? OpenAIImageResponseFormat.base64Json)
                  .value,
      },
      timeout: request.callOptions.timeout,
      cancellation: request.callOptions.cancellation,
      responseType: TransportResponseType.json,
    );
  }

  TransportRequest _buildEditTransportRequest(
    OpenAIImageEditRequest request, {
    required OpenAIImageOptions? options,
  }) {
    final multipart = buildTransportMultipartBody(
      fields: [
        TransportMultipartField.text(
          name: 'model',
          value: modelId,
        ),
        TransportMultipartField.text(
          name: 'prompt',
          value: request.prompt,
        ),
        for (final image in request.images)
          TransportMultipartField.file(
            name: 'image',
            filename: image.filename ?? _buildImageFilename(image.mediaType),
            mediaType: image.mediaType,
            bytes: image.bytes,
          ),
        if (request.mask case final mask?)
          TransportMultipartField.file(
            name: 'mask',
            filename: mask.filename ?? 'mask.png',
            mediaType: mask.mediaType,
            bytes: mask.bytes,
          ),
        TransportMultipartField.text(
          name: 'n',
          value: request.count.toString(),
        ),
        if (request.size case final size?)
          TransportMultipartField.text(
            name: 'size',
            value: size,
          ),
        if (options?.background case final background?)
          TransportMultipartField.text(
            name: 'background',
            value: background.value,
          ),
        if (request.inputFidelity case final inputFidelity?)
          TransportMultipartField.text(
            name: 'input_fidelity',
            value: inputFidelity.value,
          ),
        if (request.partialImages case final partialImages?)
          TransportMultipartField.text(
            name: 'partial_images',
            value: partialImages.toString(),
          ),
        if (options?.quality case final quality?)
          TransportMultipartField.text(
            name: 'quality',
            value: quality.value,
          ),
        if (request.outputCompression case final outputCompression?)
          TransportMultipartField.text(
            name: 'output_compression',
            value: outputCompression.toString(),
          ),
        if (options?.outputFormat case final outputFormat?)
          TransportMultipartField.text(
            name: 'output_format',
            value: outputFormat.value,
          ),
        if (options?.responseFormat case final responseFormat?)
          TransportMultipartField.text(
            name: 'response_format',
            value: responseFormat.value,
          ),
        if (options?.user case final user?)
          TransportMultipartField.text(
            name: 'user',
            value: user,
          ),
      ],
    );

    return TransportRequest(
      uri: imageEditUri,
      method: TransportMethod.post,
      headers: {
        ...defaultHeaders,
        'content-type': multipart.contentType,
        'accept': 'application/json',
        if (request.callOptions.headers case final headers?) ...headers,
      },
      body: multipart.bytes,
      timeout: request.callOptions.timeout,
      cancellation: request.callOptions.cancellation,
      responseType: TransportResponseType.json,
    );
  }
}
