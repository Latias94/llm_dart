import 'package:llm_dart_core/llm_dart_core.dart';

/// Mirrors Vercel AI SDK's `DownloadError`.
///
/// Used by download/read helpers to convert potential OOM scenarios into a
/// catchable error.
class DownloadError extends LLMError {
  final Uri url;
  final int? statusCode;
  final String? statusText;
  final Object? cause;

  DownloadError({
    required this.url,
    this.statusCode,
    this.statusText,
    this.cause,
    String? message,
  }) : super(
          message ??
              (cause == null
                  ? 'Failed to download $url: ${statusCode ?? ''} ${statusText ?? ''}'
                      .trim()
                  : 'Failed to download $url: $cause'),
        );

  static bool isInstance(Object error) => error is DownloadError;
}
