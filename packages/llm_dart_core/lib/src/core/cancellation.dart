/// Cancellation support for LLM operations
///
/// This module provides a transport-agnostic cancellation abstraction for
/// all async operations in the library, including chat requests, streaming,
/// embeddings, audio, and file operations.
///
/// ## Usage
///
/// ```dart
/// import 'package:llm_dart/llm_dart.dart';
///
/// // Create a cancellation source and token
/// final source = CancellationTokenSource();
/// final token = source.token;
///
/// // Start an operation
/// final future = provider.chat(messages, cancelToken: token);
///
/// // Cancel it later (e.g., user cancels)
/// source.cancel('User cancelled');
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
/// The core library exposes a provider-agnostic [CancellationToken] type.
/// HTTP-based providers can adapt this token to their underlying HTTP
/// client primitives (for example, Dio's `CancelToken`) in utility layers
/// without adding HTTP client dependencies to `llm_dart_core`.
///
/// The same token can be shared across multiple operations - cancelling it
/// will signal all operations bound to that token.
library;

import 'llm_error.dart';

/// Signature for cancellation callbacks.
typedef CancellationCallback = void Function(String? reason);

/// Provider-agnostic cancellation token interface.
///
/// Implementations are responsible for tracking cancellation state and
/// notifying registered listeners when cancellation occurs.
abstract class CancellationToken {
  /// Whether cancellation has been requested.
  bool get isCancellationRequested;

  /// Optional human-readable cancellation reason.
  String? get reason;

  /// Register a callback that is invoked exactly once when this token
  /// is cancelled.
  ///
  /// If the token is already cancelled when this method is called,
  /// the callback is invoked synchronously before the method returns.
  void onCancelled(CancellationCallback callback);
}

/// Source for creating and controlling a [CancellationToken].
///
/// This mirrors the conceptual design of common cancellation primitives
/// (such as .NET's `CancellationTokenSource`) while remaining minimal.
class CancellationTokenSource {
  final _MutableCancellationToken _token = _MutableCancellationToken();

  /// The token associated with this source.
  CancellationToken get token => _token;

  /// Cancel the token with an optional [reason].
  ///
  /// This method is idempotent: subsequent calls have no additional effect.
  void cancel([String? reason]) {
    _token._cancel(reason);
  }
}

/// Simple in-memory [CancellationToken] implementation.
class _MutableCancellationToken implements CancellationToken {
  bool _isCancelled = false;
  String? _reason;
  final List<CancellationCallback> _callbacks = [];

  @override
  bool get isCancellationRequested => _isCancelled;

  @override
  String? get reason => _reason;

  @override
  void onCancelled(CancellationCallback callback) {
    if (_isCancelled) {
      callback(_reason);
      return;
    }
    _callbacks.add(callback);
  }

  void _cancel(String? reason) {
    if (_isCancelled) return;
    _isCancelled = true;
    _reason = reason;

    for (final callback in _callbacks) {
      callback(reason);
    }
    _callbacks.clear();
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
