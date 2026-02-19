import 'dart:typed_data';

import 'package:llm_dart_core/llm_dart_core.dart';

import 'download_error.dart';

/// Default maximum download size: 2 GiB.
///
/// This mirrors Vercel AI SDK's provider-utils `DEFAULT_MAX_DOWNLOAD_SIZE`.
const int DEFAULT_MAX_DOWNLOAD_SIZE = 2 * 1024 * 1024 * 1024;

/// Reads a byte stream with a size limit to prevent memory exhaustion.
///
/// - If [contentLength] is provided and exceeds [maxBytes], throws [DownloadError]
///   early.
/// - Otherwise reads [body] incrementally and throws [DownloadError] once the
///   limit is exceeded.
Future<Uint8List> readResponseWithSizeLimit({
  required Stream<List<int>> body,
  required Uri url,
  int maxBytes = DEFAULT_MAX_DOWNLOAD_SIZE,
  int? contentLength,
  CancelToken? cancelToken,
}) async {
  if (maxBytes <= 0) {
    throw const InvalidRequestError('maxBytes must be > 0');
  }

  if (contentLength != null && contentLength > maxBytes) {
    throw DownloadError(
      url: url,
      message: 'Download of $url exceeded maximum size of $maxBytes bytes '
          '(Content-Length: $contentLength).',
    );
  }

  final bytes = BytesBuilder(copy: false);
  var totalBytes = 0;

  await for (final chunk in body) {
    if (cancelToken?.isCancelled == true) {
      throw CancelledError(cancelToken?.reason?.toString() ?? 'Cancelled');
    }

    totalBytes += chunk.length;
    if (totalBytes > maxBytes) {
      throw DownloadError(
        url: url,
        message: 'Download of $url exceeded maximum size of $maxBytes bytes.',
      );
    }
    bytes.add(chunk);
  }

  return bytes.takeBytes();
}
