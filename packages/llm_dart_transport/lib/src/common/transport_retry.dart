import 'dart:math' as math;

import '../http/transport_client.dart';
import 'transport_exception.dart';

typedef TransportRetryPredicate = bool Function(TransportRetryContext context);

typedef TransportRetryDelayCalculator = Duration Function(
  TransportRetryContext context,
  Duration defaultDelay,
);

final class TransportRetryContext {
  final TransportRequest request;
  final int attempt;
  final bool isStreaming;
  final Object error;

  const TransportRetryContext({
    required this.request,
    required this.attempt,
    required this.isStreaming,
    required this.error,
  });

  int get nextAttempt => attempt + 1;
}

final class TransportRetryPolicy {
  final int maxAttempts;
  final Duration baseDelay;
  final double backoffMultiplier;
  final Duration? maxDelay;
  final bool respectRetryAfter;
  final TransportRetryPredicate retryIf;
  final TransportRetryDelayCalculator? delayCalculator;

  const TransportRetryPolicy({
    this.maxAttempts = 1,
    this.baseDelay = Duration.zero,
    this.backoffMultiplier = 2,
    this.maxDelay,
    this.respectRetryAfter = true,
    TransportRetryPredicate? retryIf,
    this.delayCalculator,
  })  : assert(maxAttempts >= 1),
        assert(backoffMultiplier > 0),
        retryIf = retryIf ?? defaultRetryIf;

  bool shouldRetry(TransportRetryContext context) {
    if (context.attempt >= maxAttempts) {
      return false;
    }

    return retryIf(context);
  }

  Duration delayFor(TransportRetryContext context) {
    final retryAfterDelay =
        respectRetryAfter ? retryAfterDelayFor(context.error) : null;
    final defaultDelay = retryAfterDelay ?? _defaultDelay(context);
    final customDelay = delayCalculator?.call(context, defaultDelay);
    final resolvedDelay = customDelay ?? defaultDelay;
    if (resolvedDelay.isNegative) {
      return Duration.zero;
    }
    return resolvedDelay;
  }

  Duration _defaultDelay(TransportRetryContext context) {
    if (baseDelay == Duration.zero) {
      return Duration.zero;
    }

    final multiplier = math.pow(backoffMultiplier, context.attempt - 1);
    final microseconds =
        (baseDelay.inMicroseconds * multiplier.toDouble()).round();
    final delay = Duration(microseconds: microseconds);
    if (maxDelay != null && delay > maxDelay!) {
      return maxDelay!;
    }
    return delay;
  }

  static bool defaultRetryIf(TransportRetryContext context) {
    return switch (context.error) {
      TransportTimeoutException() || TransportNetworkException() => true,
      TransportHttpException(statusCode: final statusCode) =>
        _isRetryableStatusCode(statusCode),
      _ => false,
    };
  }

  static Duration? retryAfterDelayFor(Object error) {
    if (error is! TransportHttpException) {
      return null;
    }

    final rawValue = error.headers.entries
        .firstWhere(
          (entry) => entry.key.toLowerCase() == 'retry-after',
          orElse: () => const MapEntry('', ''),
        )
        .value;
    final seconds = int.tryParse(rawValue.trim());
    if (seconds == null || seconds < 0) {
      return null;
    }

    return Duration(seconds: seconds);
  }
}

bool _isRetryableStatusCode(int statusCode) {
  return statusCode == 408 ||
      statusCode == 409 ||
      statusCode == 429 ||
      statusCode >= 500;
}
