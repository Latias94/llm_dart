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
/// // Create a cancellation token
/// final cancelToken = TransportCancellation();
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
/// The library uses transport-level cancellation abstractions and adapts them
/// to provider HTTP clients internally. When you cancel a token:
/// - In-flight HTTP requests are aborted immediately
/// - Streaming responses stop emitting events
/// - Providers stop generating tokens
///
/// The same token can be shared across multiple operations - cancelling it
/// will abort all operations bound to that token.
library;

export 'package:llm_dart_core/llm_dart_core.dart'
    show TransportCancellation, TransportCancelledException;

import 'package:dio/dio.dart' as dio;
import 'package:llm_dart_core/llm_dart_core.dart';
import 'llm_error.dart';

@Deprecated('Use TransportCancellation instead.')
typedef CancelToken = TransportCancellation;

/// Helper utilities for working with cancellation
class CancellationHelper {
  /// Check if an error indicates the operation was cancelled
  ///
  /// Returns `true` if the error is a `CancelledError`,
  /// `TransportCancelledException`, or a raw Dio cancellation exception.
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
    // Check for our custom CancelledError
    if (error is CancelledError) return true;

    if (error is TransportCancelledException) return true;

    // Check for Dio's raw cancellation exception
    // (this should not normally occur as we map it to CancelledError)
    return error is dio.DioException && dio.CancelToken.isCancel(error);
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

    if (error is CancelledError) {
      return error.message;
    }

    if (error is TransportCancelledException) {
      return error.reason?.toString();
    }

    if (error is dio.DioException) {
      return error.message;
    }

    return null;
  }
}
