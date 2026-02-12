import 'dart:math';

import 'package:dio/dio.dart';

import 'package:llm_dart_core/llm_dart_core.dart';

const _attemptKey = 'llm_dart.retry.attempt';
const _disabledKey = 'llm_dart.retry.disabled';

/// Transport-level HTTP retry configuration (AI SDK-inspired).
///
/// This is intentionally **opt-in**: by default no retries are performed.
///
/// Configure via `LLMConfig.transportOptions['retry']`:
///
/// ```dart
/// final config = LLMConfig(...).withTransportOptions({
///   'retry': {
///     'maxRetries': 2,
///     'baseDelayMs': 200,
///     'maxDelayMs': 2000,
///     'backoffFactor': 2.0,
///     'jitter': 0.2,
///     'respectRetryAfter': true,
///   },
/// });
/// ```
class HttpRetryConfig {
  final int maxRetries;
  final Duration baseDelay;
  final Duration maxDelay;
  final double backoffFactor;
  final double jitter;
  final bool respectRetryAfter;
  final bool retryOnFormData;

  /// HTTP status codes that should be retried.
  final Set<int> retryStatusCodes;

  /// Whether to retry transient Dio errors (timeouts/connection errors).
  final bool retryOnDioErrors;

  const HttpRetryConfig({
    required this.maxRetries,
    required this.baseDelay,
    required this.maxDelay,
    required this.backoffFactor,
    required this.jitter,
    required this.respectRetryAfter,
    required this.retryOnFormData,
    required this.retryStatusCodes,
    required this.retryOnDioErrors,
  })  : assert(maxRetries >= 0),
        assert(backoffFactor >= 1.0),
        assert(jitter >= 0.0),
        assert(jitter <= 1.0);

  bool get enabled => maxRetries > 0;

  static const disabled = HttpRetryConfig(
    maxRetries: 0,
    baseDelay: Duration(milliseconds: 0),
    maxDelay: Duration(milliseconds: 0),
    backoffFactor: 2.0,
    jitter: 0.0,
    respectRetryAfter: true,
    retryOnFormData: false,
    retryStatusCodes: {408, 429, 500, 502, 503, 504},
    retryOnDioErrors: true,
  );

  /// Parse config from `LLMConfig.transportOptions['retry']`.
  ///
  /// Returns [disabled] when absent/invalid.
  factory HttpRetryConfig.fromLLMConfig(LLMConfig config) {
    final raw = config.getTransportOption<Object>('retry');
    if (raw == null) return disabled;
    if (raw is HttpRetryConfig) return raw;
    if (raw is! Map) return disabled;

    int? asInt(Object? v) => v is int ? v : (v is num ? v.toInt() : null);
    double? asDouble(Object? v) =>
        v is double ? v : (v is num ? v.toDouble() : null);
    bool? asBool(Object? v) => v is bool ? v : null;

    final map = raw.cast<String, Object?>();

    final maxRetries = asInt(map['maxRetries']) ?? 0;
    final baseDelayMs = asInt(map['baseDelayMs']) ?? 200;
    final maxDelayMs = asInt(map['maxDelayMs']) ?? 10 * 1000;
    final backoffFactor = asDouble(map['backoffFactor']) ?? 2.0;
    final jitter = asDouble(map['jitter']) ?? 0.2;
    final respectRetryAfter = asBool(map['respectRetryAfter']) ?? true;
    final retryOnDioErrors = asBool(map['retryOnDioErrors']) ?? true;
    final retryOnFormData = asBool(map['retryOnFormData']) ?? false;

    final retryStatusesRaw = map['retryStatusCodes'];
    final retryStatusCodes = <int>{};
    if (retryStatusesRaw is List) {
      for (final v in retryStatusesRaw) {
        final code = asInt(v);
        if (code != null) retryStatusCodes.add(code);
      }
    }
    if (retryStatusCodes.isEmpty) {
      retryStatusCodes.addAll(const {408, 429, 500, 502, 503, 504});
    }

    return HttpRetryConfig(
      maxRetries: maxRetries < 0 ? 0 : maxRetries,
      baseDelay: Duration(milliseconds: max(0, baseDelayMs)),
      maxDelay: Duration(milliseconds: max(0, maxDelayMs)),
      backoffFactor: backoffFactor < 1.0 ? 1.0 : backoffFactor,
      jitter: jitter.clamp(0.0, 1.0),
      respectRetryAfter: respectRetryAfter,
      retryOnFormData: retryOnFormData,
      retryStatusCodes: retryStatusCodes,
      retryOnDioErrors: retryOnDioErrors,
    );
  }

  Duration computeDelay({
    required int attempt,
    Duration? retryAfter,
    Random? random,
  }) {
    if (respectRetryAfter && retryAfter != null) {
      return retryAfter;
    }

    final factor = pow(backoffFactor, attempt).toDouble();
    final baseMs = (baseDelay.inMilliseconds * factor).round();
    var cappedMs = baseMs;
    if (maxDelay.inMilliseconds > 0) {
      cappedMs = min(cappedMs, maxDelay.inMilliseconds);
    }
    final capped = Duration(milliseconds: max(0, cappedMs));

    if (jitter <= 0) return capped;

    final rnd = random ?? Random();
    final ratio = (rnd.nextDouble() * 2 - 1) * jitter; // [-jitter, +jitter]
    final ms = (capped.inMilliseconds * (1 + ratio)).round();
    return Duration(milliseconds: max(0, ms));
  }
}

/// A Dio interceptor that retries failed requests with exponential backoff.
///
/// This is only meant for **non-streaming** requests. Streaming requests
/// (`responseType=stream`) are never retried.
class HttpRetryInterceptor extends Interceptor {
  final Dio _dio;
  final HttpRetryConfig config;
  final Random _random;

  /// Delay function used for backoff. Overridable for tests.
  final Future<void> Function(Duration) _sleep;

  HttpRetryInterceptor({
    required Dio dio,
    required this.config,
    Random? random,
    Future<void> Function(Duration)? sleep,
  })  : _dio = dio,
        _random = random ?? Random(),
        _sleep = sleep ?? Future.delayed;

  static void disableRetriesForRequest(RequestOptions options) {
    options.extra[_disabledKey] = true;
  }

  static int _attemptFor(RequestOptions options) {
    final raw = options.extra[_attemptKey];
    return raw is int ? raw : 0;
  }

  static void _setAttempt(RequestOptions options, int attempt) {
    options.extra[_attemptKey] = attempt;
  }

  static Duration? _parseRetryAfter(Headers? headers) {
    if (headers == null) return null;

    // AI SDK parity: prefer retry-after-ms, then retry-after, but only accept
    // "reasonable" values (0..60 seconds). Otherwise fall back to exponential
    // backoff to avoid extremely long stalls.
    final rawMs =
        headers.value('retry-after-ms') ?? headers.value('Retry-After-Ms');
    if (rawMs != null) {
      final ms = int.tryParse(rawMs.trim());
      if (ms != null && ms >= 0 && ms <= 60 * 1000) {
        return Duration(milliseconds: ms);
      }
    }

    // Best-effort: Retry-After is usually sent as seconds.
    final raw = headers.value('retry-after') ?? headers.value('Retry-After');
    if (raw == null) return null;

    final seconds = int.tryParse(raw.trim());
    if (seconds != null && seconds >= 0 && seconds <= 60) {
      return Duration(seconds: seconds);
    }
    return null;
  }

  bool _isStreaming(RequestOptions options) =>
      options.responseType == ResponseType.stream;

  bool _shouldRetry(DioException err) {
    if (!config.enabled) return false;

    final options = err.requestOptions;
    if (options.extra[_disabledKey] == true) return false;
    if (_isStreaming(options)) return false;
    if (options.data is FormData && !config.retryOnFormData) return false;

    final attempt = _attemptFor(options);
    if (attempt >= config.maxRetries) return false;

    final status = err.response?.statusCode;
    if (status != null) {
      // Retry on configured status codes and all 5xx by default when 500 is in set.
      if (config.retryStatusCodes.contains(status)) return true;
      if (status >= 500 && config.retryStatusCodes.contains(500)) return true;
      return false;
    }

    if (!config.retryOnDioErrors) return false;

    return switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError =>
        true,
      DioExceptionType.badCertificate => false,
      DioExceptionType.cancel => false,
      DioExceptionType.badResponse => false,
      DioExceptionType.unknown => true,
    };
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldRetry(err)) {
      handler.next(err);
      return;
    }

    final options = err.requestOptions;
    if (options.cancelToken?.isCancelled == true) {
      handler.next(err);
      return;
    }
    final attempt = _attemptFor(options);
    _setAttempt(options, attempt + 1);

    final retryAfter = config.respectRetryAfter
        ? _parseRetryAfter(err.response?.headers)
        : null;
    final delay = config.computeDelay(
      attempt: attempt,
      retryAfter: retryAfter,
      random: _random,
    );

    if (delay > Duration.zero) {
      await _sleep(delay);
    }

    try {
      if (options.cancelToken?.isCancelled == true) {
        handler.next(err);
        return;
      }
      final response = await _dio.fetch(options);
      handler.resolve(response);
    } catch (e) {
      if (e is DioException) {
        handler.next(e);
      } else {
        handler.next(
          DioException(
            requestOptions: options,
            error: e,
            type: DioExceptionType.unknown,
            message: e.toString(),
          ),
        );
      }
    }
  }
}
