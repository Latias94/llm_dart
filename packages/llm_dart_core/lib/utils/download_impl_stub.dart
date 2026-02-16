library;

import '../core/cancellation.dart';
import '../core/llm_error.dart';
import 'download.dart';

DownloadFn createDownload({required int maxBytes}) {
  return ({
    required Uri url,
    CancelToken? cancelToken,
  }) async {
    throw const InvalidRequestError(
      'createDownload() is not supported on this platform. '
      'Provide a custom download function or use an IO platform.',
    );
  };
}
