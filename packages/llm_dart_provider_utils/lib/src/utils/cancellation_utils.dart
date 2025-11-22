import 'package:dio/dio.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

/// Utilities for bridging core cancellation tokens to Dio.
class CancellationUtils {
  /// Convert a core [CancellationToken] to a Dio [CancelToken].
  ///
  /// The returned [CancelToken] will be cancelled when the core token
  /// is cancelled. If the core token is already cancelled, the Dio
  /// token will be cancelled immediately.
  static CancelToken? toDioCancelToken(CancellationToken? token) {
    if (token == null) return null;

    final dioToken = CancelToken();

    token.onCancelled((reason) {
      if (!dioToken.isCancelled) {
        dioToken.cancel(reason);
      }
    });

    return dioToken;
  }
}
