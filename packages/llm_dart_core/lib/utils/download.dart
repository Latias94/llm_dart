/// Experimental download utilities (AI SDK parity).
///
/// Vercel AI SDK exposes a `createDownload({ maxBytes })` helper that is used by
/// `transcribe()` and `experimental_generateVideo()` to download URL-based
/// inputs/outputs with size limits.
///
/// In Dart, we expose a lightweight, dependency-free downloader:
/// - IO platforms use `dart:io`'s `HttpClient`.
/// - Web platforms throw an [UnsupportedError] by default.
library;

import 'dart:typed_data';

import '../core/cancellation.dart';

import 'download_impl_stub.dart'
    if (dart.library.io) 'download_impl_io.dart'
    if (dart.library.html) 'download_impl_web.dart' as impl;

typedef DownloadFn = Future<DownloadResult> Function({
  required Uri url,
  CancelToken? cancelToken,
});

final class DownloadResult {
  final Uint8List data;
  final String? mediaType;

  const DownloadResult({
    required this.data,
    this.mediaType,
  });
}

/// Creates a download function with an optional [maxBytes] limit.
///
/// The returned function downloads the content at [url] and returns its bytes
/// plus the best-effort `Content-Type` header as [DownloadResult.mediaType].
///
/// Notes:
/// - Exceeding [maxBytes] throws an [InvalidRequestError].
/// - Cancellation is best-effort via [CancelToken].
DownloadFn createDownload({
  int maxBytes = 50 * 1024 * 1024,
}) =>
    impl.createDownload(maxBytes: maxBytes);
