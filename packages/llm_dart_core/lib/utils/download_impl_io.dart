library;

import 'dart:io';
import 'dart:typed_data';

import '../core/cancellation.dart';
import '../core/llm_error.dart';
import 'download.dart';

DownloadFn createDownload({required int maxBytes}) {
  if (maxBytes <= 0) {
    throw const InvalidRequestError('maxBytes must be > 0');
  }

  return ({
    required Uri url,
    CancelToken? cancelToken,
  }) async {
    if (cancelToken?.isCancelled == true) {
      throw CancelledError(cancelToken?.reason?.toString() ?? 'Cancelled');
    }

    final client = HttpClient();
    client.autoUncompress = true;

    HttpClientRequest? request;
    final dispose = cancelToken?.addListener((_) {
      try {
        request?.abort();
      } catch (_) {
        // Best-effort.
      }
    });

    try {
      request = await client.getUrl(url);
      final response = await request.close();

      if (cancelToken?.isCancelled == true) {
        throw CancelledError(cancelToken?.reason?.toString() ?? 'Cancelled');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpError(
          'Download failed with status ${response.statusCode} for $url',
        );
      }

      final contentLength = response.contentLength;
      if (contentLength >= 0 && contentLength > maxBytes) {
        throw InvalidRequestError(
          'Downloaded content exceeds maxBytes ($maxBytes bytes). '
          'Content-Length: $contentLength.',
        );
      }

      final bytes = BytesBuilder(copy: false);
      var total = 0;

      await for (final chunk in response) {
        if (cancelToken?.isCancelled == true) {
          throw CancelledError(cancelToken?.reason?.toString() ?? 'Cancelled');
        }

        total += chunk.length;
        if (total > maxBytes) {
          throw InvalidRequestError(
            'Downloaded content exceeds maxBytes ($maxBytes bytes).',
          );
        }
        bytes.add(chunk);
      }

      final contentType = response.headers.contentType?.mimeType;
      return DownloadResult(
        data: bytes.takeBytes(),
        mediaType: contentType,
      );
    } finally {
      dispose?.call();
      try {
        client.close(force: true);
      } catch (_) {
        // Best-effort.
      }
    }
  };
}
