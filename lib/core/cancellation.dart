/// Cancellation support for LLM operations
///
/// This module provides cancellation capabilities for all async operations
/// in the library, including chat requests, streaming, embeddings, and audio.
///
/// ## Usage
///
/// ```dart
/// import 'package:llm_dart/llm_dart.dart';
///
/// // Create a cancel token
/// final cancelToken = CancelToken();
///
/// // Start an operation
/// final future = provider.chat(messages, cancelToken: cancelToken);
///
/// // Cancel it later (e.g., user cancels)
/// cancelToken.cancel('User cancelled');
///
/// // Handle cancellation
/// try {
///   final response = await future;
/// } catch (e) {
///   if (CancellationHelper.isCancelled(e)) {
///     print('Operation was cancelled');
///   }
/// }
/// ```
///
/// ## How it works
///
/// The library uses Dio's `CancelToken` internally to provide true cancellation
/// of HTTP requests at the network level. When you cancel a token:
/// - In-flight HTTP requests are aborted immediately
/// - Streaming responses stop emitting events
/// - Providers stop generating tokens
///
/// The same token can be shared across multiple operations - cancelling it
/// will abort all operations bound to that token.
library;

// Re-export Dio's CancelToken for public API
// This provides the actual cancellation mechanism
export 'package:dio/dio.dart' show CancelToken;

import 'package:dio/dio.dart';

/// Helper utilities for working with cancellation
class CancellationHelper {
  /// Check if an error indicates the operation was cancelled
  ///
  /// Returns `true` if the error is a `DioException` with type `cancel`.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   await provider.chat(messages, cancelToken: token);
  /// } catch (e) {
  ///   if (CancellationHelper.isCancelled(e)) {
  ///     print('Operation cancelled');
  ///   }
  /// }
  /// ```
  static bool isCancelled(Object error) {
    return error is DioException && CancelToken.isCancel(error);
  }

  /// Extract the cancellation reason/message from an error
  ///
  /// Returns the reason string if the error is a cancellation,
  /// otherwise returns null.
  ///
  /// Example:
  /// ```dart
  /// catch (e) {
  ///   final reason = CancellationHelper.getCancellationReason(e);
  ///   if (reason != null) {
  ///     print('Cancelled: $reason');
  ///   }
  /// }
  /// ```
  static String? getCancellationReason(Object error) {
    if (!isCancelled(error)) return null;
    final dioError = error as DioException;
    return dioError.message;
  }
}
