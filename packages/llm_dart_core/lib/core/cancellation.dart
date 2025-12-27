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
/// `llm_dart` exposes a lightweight, provider-agnostic [CancelToken].
///
/// Provider implementations may bridge it to their underlying HTTP client
/// cancellation mechanisms (e.g. Dio).
library;

import 'llm_error.dart';

typedef CancelListener = void Function(Object? reason);

/// A provider-agnostic cancellation token.
///
/// This mirrors the basic ergonomics of Dio's `CancelToken`, but lives in
/// `llm_dart_core` so core APIs do not depend on any specific HTTP client.
class CancelToken {
  bool _cancelled = false;
  Object? _reason;

  int _nextListenerId = 0;
  final Map<int, CancelListener> _listeners = {};

  /// Whether cancellation has been requested.
  bool get isCancelled => _cancelled;

  /// Optional cancellation reason.
  Object? get reason => _reason;

  /// Request cancellation.
  ///
  /// Calling this multiple times is a no-op after the first call.
  void cancel([Object? reason]) {
    if (_cancelled) return;
    _cancelled = true;
    _reason = reason;

    final listeners = List<CancelListener>.from(_listeners.values);
    _listeners.clear();
    for (final listener in listeners) {
      try {
        listener(_reason);
      } catch (_) {
        // Best-effort notifications; ignore listener errors.
      }
    }
  }

  /// Subscribe to cancellation notifications.
  ///
  /// Returns a disposer that unregisters the listener.
  ///
  /// If already cancelled, [listener] is invoked immediately and the disposer
  /// is a no-op.
  void Function() addListener(CancelListener listener) {
    if (_cancelled) {
      listener(_reason);
      return () {};
    }

    final id = _nextListenerId++;
    _listeners[id] = listener;
    return () {
      _listeners.remove(id);
    };
  }
}

/// Helper utilities for working with cancellation
class CancellationHelper {
  /// Check if an error indicates the operation was cancelled
  ///
  /// Returns `true` if the error is a [CancelledError].
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
    return false;
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

    return null;
  }
}
