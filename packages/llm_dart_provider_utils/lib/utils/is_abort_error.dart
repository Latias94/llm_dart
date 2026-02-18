import 'package:dio/dio.dart' as dio;
import 'package:llm_dart_core/llm_dart_core.dart';

/// Returns true if the error indicates a cancelled/aborted request.
///
/// This is a Dart counterpart to Vercel AI SDK's `isAbortError(...)`.
bool isAbortError(Object error) {
  if (error is CancelledError) return true;
  if (error is TimeoutError) return true;

  if (error is dio.DioException) {
    return switch (error.type) {
      dio.DioExceptionType.cancel => true,
      dio.DioExceptionType.connectionTimeout => true,
      dio.DioExceptionType.sendTimeout => true,
      dio.DioExceptionType.receiveTimeout => true,
      _ => false,
    };
  }

  return false;
}
