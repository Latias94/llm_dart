import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'anthropic_file_types.dart';

TransportMultipartBody buildAnthropicFileUploadBody(
  AnthropicFileUpload request,
) {
  validateAnthropicFileUpload(request);

  return buildTransportMultipartBody(
    fields: [
      TransportMultipartField.file(
        name: 'file',
        filename: request.filename,
        mediaType: request.mediaType,
        bytes: request.bytes,
      ),
    ],
  );
}

void validateAnthropicFileUpload(AnthropicFileUpload request) {
  if (request.bytes.isEmpty) {
    throw ArgumentError.value(
      request.bytes,
      'request.bytes',
      'Anthropic file uploads require non-empty bytes.',
    );
  }

  if (request.filename.trim().isEmpty) {
    throw ArgumentError.value(
      request.filename,
      'request.filename',
      'Anthropic file uploads require a non-empty filename.',
    );
  }

  if (request.mediaType.trim().isEmpty) {
    throw ArgumentError.value(
      request.mediaType,
      'request.mediaType',
      'Anthropic file uploads require a non-empty media type.',
    );
  }
}
