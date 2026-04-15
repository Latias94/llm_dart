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
    final multipart = buildOpenAIMultipartBody(
      fields: [
        OpenAIMultipartField.text(
          name: 'model',
          value: modelId,
        ),
        OpenAIMultipartField.text(
          name: 'prompt',
          value: request.prompt,
        ),
        for (final image in request.images)
          OpenAIMultipartField.file(
            name: 'image',
            filename: image.filename ?? _buildImageFilename(image.mediaType),
            mediaType: image.mediaType,
            bytes: image.bytes,
          ),
        if (request.mask case final mask?)
          OpenAIMultipartField.file(
            name: 'mask',
            filename: mask.filename ?? 'mask.png',
            mediaType: mask.mediaType,
            bytes: mask.bytes,
          ),
        OpenAIMultipartField.text(
          name: 'n',
          value: request.count.toString(),
        ),
        if (request.size case final size?)
          OpenAIMultipartField.text(
            name: 'size',
            value: size,
          ),
        if (options?.background case final background?)
          OpenAIMultipartField.text(
            name: 'background',
            value: background.value,
          ),
        if (request.inputFidelity case final inputFidelity?)
          OpenAIMultipartField.text(
            name: 'input_fidelity',
            value: inputFidelity.value,
          ),
        if (request.partialImages case final partialImages?)
          OpenAIMultipartField.text(
            name: 'partial_images',
            value: partialImages.toString(),
          ),
        if (options?.quality case final quality?)
          OpenAIMultipartField.text(
            name: 'quality',
            value: quality.value,
          ),
        if (request.outputCompression case final outputCompression?)
          OpenAIMultipartField.text(
            name: 'output_compression',
            value: outputCompression.toString(),
          ),
        if (options?.outputFormat case final outputFormat?)
          OpenAIMultipartField.text(
            name: 'output_format',
            value: outputFormat.value,
          ),
        if (options?.responseFormat case final responseFormat?)
          OpenAIMultipartField.text(
            name: 'response_format',
            value: responseFormat.value,
          ),
        if (options?.user case final user?)
          OpenAIMultipartField.text(
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
