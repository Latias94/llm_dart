import 'dart:async';
import 'dart:math' as math;

import 'package:llm_dart_core/llm_dart_core.dart';

import 'middleware.dart';

typedef RetryDelayStrategy = Duration Function({
  required int attempt,
  required Object error,
});

typedef RetryPredicate = bool Function(Object error);

typedef RetrySleep = Future<void> Function(Duration delay);

Duration _defaultDelayStrategy({
  required int attempt,
  required Object error,
  required Duration baseDelay,
  required Duration maxDelay,
  required double jitterRatio,
  required math.Random random,
}) {
  if (error is RateLimitError && error.retryAfter != null) {
    final retryAfter = error.retryAfter!;
    return retryAfter > maxDelay ? maxDelay : retryAfter;
  }

  final exp = math.pow(2, attempt - 1).toInt();
  final raw = Duration(
    milliseconds: baseDelay.inMilliseconds * exp,
  );
  final capped = raw > maxDelay ? maxDelay : raw;

  if (jitterRatio <= 0) return capped;

  final minFactor = (1 - jitterRatio).clamp(0.0, 1.0);
  final maxFactor = (1 + jitterRatio).clamp(1.0, 2.0);
  final factor = minFactor + (maxFactor - minFactor) * random.nextDouble();
  return Duration(milliseconds: (capped.inMilliseconds * factor).round());
}

bool _defaultShouldRetry(Object error) {
  if (error is CancelledError) return false;

  return switch (error) {
    // Transient-ish:
    TimeoutError() || ServerError() || RateLimitError() => true,

    // Usually deterministic or requires user action:
    AuthError() ||
    InvalidRequestError() ||
    ContentFilterError() ||
    StructuredOutputError() ||
    ToolConfigError() ||
    ToolValidationError() ||
    QuotaExceededError() ||
    ModelNotAvailableError() => false,

    _ => false,
  };
}

/// Retries transient failures for non-streaming calls and best-effort streaming calls.
///
/// Notes:
/// - Retries are only attempted for thrown exceptions (not for `LLMErrorPart`).
/// - Streaming retry only happens if the stream fails before emitting any part.
class RetryMiddleware extends LanguageModelMiddleware {
  final int maxRetries;
  final RetryPredicate shouldRetry;
  final RetryDelayStrategy delayStrategy;
  final RetrySleep sleep;

  RetryMiddleware({
    this.maxRetries = 2,
    RetryPredicate? shouldRetry,
    Duration baseDelay = const Duration(milliseconds: 200),
    Duration maxDelay = const Duration(seconds: 2),
    double jitterRatio = 0,
    math.Random? random,
    RetryDelayStrategy? delayStrategy,
    RetrySleep? sleep,
  })  : shouldRetry = shouldRetry ?? _defaultShouldRetry,
        delayStrategy = delayStrategy ??
            (({required attempt, required error}) => _defaultDelayStrategy(
                  attempt: attempt,
                  error: error,
                  baseDelay: baseDelay,
                  maxDelay: maxDelay,
                  jitterRatio: jitterRatio,
                  random: random ?? math.Random(),
                )),
        sleep = sleep ?? Future<void>.delayed {
    if (maxRetries < 0) {
      throw const InvalidRequestError('maxRetries must be >= 0.');
    }
  }

  @override
  Future<ChatResponse> chat(
    ChatMiddlewareContext context,
    ChatMiddlewareNext next,
  ) async {
    var attempt = 0;
    while (true) {
      try {
        return await next(context);
      } catch (e) {
        attempt++;
        if (attempt > maxRetries || !shouldRetry(e)) rethrow;

        final delay = delayStrategy(attempt: attempt, error: e);
        if (delay > Duration.zero) {
          await sleep(delay);
        }
      }
    }
  }

  @override
  Stream<LLMStreamPart> stream(
    ChatStreamMiddlewareContext context,
    ChatStreamMiddlewareNext next,
  ) async* {
    var attempt = 0;
    while (true) {
      var emittedAny = false;
      try {
        await for (final part in next(context)) {
          emittedAny = true;
          yield part;
        }
        return;
      } catch (e) {
        attempt++;
        final canRetry =
            !emittedAny && attempt <= maxRetries && shouldRetry(e);
        if (!canRetry) rethrow;

        final delay = delayStrategy(attempt: attempt, error: e);
        if (delay > Duration.zero) {
          await sleep(delay);
        }
      }
    }
  }
}

