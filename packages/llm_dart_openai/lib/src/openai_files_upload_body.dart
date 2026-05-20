import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_files_options.dart';

TransportMultipartBody buildOpenAIFileUploadBody(OpenAIFileUpload request) {
  validateOpenAIFileUpload(request);

  return buildTransportMultipartBody(
    fields: [
      TransportMultipartField.file(
        name: 'file',
        filename: request.filename,
        mediaType: request.mediaType,
        bytes: request.bytes,
      ),
      TransportMultipartField.text(
        name: 'purpose',
        value: request.purpose,
      ),
      if (request.expiresAfter != null)
        TransportMultipartField.text(
          name: 'expires_after',
          value: '${request.expiresAfter}',
        ),
    ],
  );
}

void validateOpenAIFileUpload(OpenAIFileUpload request) {
  if (request.bytes.isEmpty) {
    throw ArgumentError.value(
      request.bytes,
      'request.bytes',
      'OpenAI file uploads require non-empty bytes.',
    );
  }

  if (request.filename.trim().isEmpty) {
    throw ArgumentError.value(
      request.filename,
      'request.filename',
      'OpenAI file uploads require a non-empty filename.',
    );
  }

  if (request.purpose.trim().isEmpty) {
    throw ArgumentError.value(
      request.purpose,
      'request.purpose',
      'OpenAI file uploads require a non-empty purpose.',
    );
  }

  if (request.mediaType.trim().isEmpty) {
    throw ArgumentError.value(
      request.mediaType,
      'request.mediaType',
      'OpenAI file uploads require a non-empty media type.',
    );
  }

  if (request.expiresAfter != null && request.expiresAfter! < 1) {
    throw ArgumentError.value(
      request.expiresAfter,
      'request.expiresAfter',
      'OpenAI file upload expiresAfter must be >= 1.',
    );
  }
}
