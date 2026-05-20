import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_image_editing.dart';
import 'openai_image_options.dart';
import 'openai_image_request_validation.dart';

TransportMultipartBody buildOpenAIImageEditRequestBody({
  required String modelId,
  required OpenAIImageEditRequest request,
  required OpenAIImageOptions? options,
}) {
  final outputCompression =
      request.outputCompression ?? options?.outputCompression;
  return buildTransportMultipartBody(
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
          filename: image.filename ?? buildOpenAIImageFilename(image.mediaType),
          mediaType: image.mediaType,
          bytes: image.bytes!,
        ),
      if (request.mask case final mask?)
        TransportMultipartField.file(
          name: 'mask',
          filename: mask.filename ?? 'mask.png',
          mediaType: mask.mediaType,
          bytes: mask.bytes!,
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
      if (outputCompression != null)
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
}
