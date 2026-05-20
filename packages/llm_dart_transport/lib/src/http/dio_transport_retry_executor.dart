import 'dart:async';

import 'package:dio/dio.dart';

import '../common/transport_cancellation.dart';
import '../common/transport_diagnostics.dart';
import '../common/transport_exception.dart';
import '../common/transport_retry.dart';
import 'dio_cancellation_adapter.dart';
import 'dio_transport_diagnostics_support.dart';
import 'dio_transport_error_mapper.dart';
import 'transport_client.dart';

typedef DioTransportAttempt<T> = Future<DioTransportAttemptSuccess<T>> Function(
    CancelToken? cancelToken);

final class DioTransportRetryExecutor {
  final DioTransportDiagnosticsSupport diagnosticsSupport;
  final DioTransportErrorMapper errorMapper;
  final TransportRetryPolicy retryPolicy;

  static final Object _retryDelaySentinel = Object();

  const DioTransportRetryExecutor({
    required this.diagnosticsSupport,
    required this.errorMapper,
    required this.retryPolicy,
  });

  Future<T> execute<T>(
    TransportRequest request, {
    required bool isStreaming,
    required DioTransportAttempt<T> sendAttempt,
  }) async {
    final effectiveRetryPolicy = _effectiveRetryPolicy(request);
    final requestInfo = diagnosticsSupport.createRequestInfo(
      request,
      isStreaming: isStreaming,
      retryPolicy: effectiveRetryPolicy,
    );
    for (var attempt = 1; true; attempt++) {
      final startedAt = DateTime.now();
      diagnosticsSupport.emit(
        TransportDiagnosticsEvent(
          kind: TransportDiagnosticsEventKind.requestStart,
          request: requestInfo,
          timestamp: startedAt,
          attempt: attempt,
        ),
      );

      try {
        request.cancellation?.throwIfCancelled();
        final cancelToken = bindDioCancellation(request.cancellation);
        final success = await sendAttempt(cancelToken);
        final finishedAt = DateTime.now();
        diagnosticsSupport.emit(
          TransportDiagnosticsEvent(
            kind: TransportDiagnosticsEventKind.requestSuccess,
            request: requestInfo,
            response: success.response,
            timestamp: finishedAt,
            duration: finishedAt.difference(startedAt),
            attempt: attempt,
          ),
        );
        return success.value;
      } on DioException catch (error) {
        final mapped = await errorMapper.mapDioException(
          error,
          uri: request.uri,
        );
        final shouldRetry = await _handleFailure(
          request: request,
          requestInfo: requestInfo,
          isStreaming: isStreaming,
          attempt: attempt,
          startedAt: startedAt,
          error: mapped,
          retryPolicy: effectiveRetryPolicy,
        );
        if (shouldRetry) {
          continue;
        }
        throw mapped;
      } on TransportException catch (error) {
        final shouldRetry = await _handleFailure(
          request: request,
          requestInfo: requestInfo,
          isStreaming: isStreaming,
          attempt: attempt,
          startedAt: startedAt,
          error: error,
          retryPolicy: effectiveRetryPolicy,
        );
        if (shouldRetry) {
          continue;
        }
        rethrow;
      } catch (error) {
        final shouldRetry = await _handleFailure(
          request: request,
          requestInfo: requestInfo,
          isStreaming: isStreaming,
          attempt: attempt,
          startedAt: startedAt,
          error: error,
          retryPolicy: effectiveRetryPolicy,
        );
        if (shouldRetry) {
          continue;
        }
        rethrow;
      }
    }
  }

  Future<bool> _handleFailure({
    required TransportRequest request,
    required TransportDiagnosticsRequestInfo requestInfo,
    required bool isStreaming,
    required int attempt,
    required DateTime startedAt,
    required Object error,
    required TransportRetryPolicy retryPolicy,
  }) async {
    final finishedAt = DateTime.now();
    diagnosticsSupport.emit(
      TransportDiagnosticsEvent(
        kind: TransportDiagnosticsEventKind.requestFailure,
        request: requestInfo,
        response: diagnosticsSupport.responseInfoFromError(error),
        error: error,
        timestamp: finishedAt,
        duration: finishedAt.difference(startedAt),
        attempt: attempt,
      ),
    );

    final retryContext = TransportRetryContext(
      request: request,
      attempt: attempt,
      isStreaming: isStreaming,
      error: error,
    );
    if (!retryPolicy.shouldRetry(retryContext)) {
      return false;
    }

    await _waitForRetryDelay(
      retryPolicy.delayFor(retryContext),
      request.cancellation,
    );
    return true;
  }

  TransportRetryPolicy _effectiveRetryPolicy(TransportRequest request) {
    final maxRetries = request.maxRetries;
    if (maxRetries == null) {
      return retryPolicy;
    }

    return retryPolicy.withRequestMaxRetries(maxRetries);
  }

  Future<void> _waitForRetryDelay(
    Duration delay,
    TransportCancellation? cancellation,
  ) async {
    if (delay <= Duration.zero) {
      cancellation?.throwIfCancelled();
      return;
    }

    if (cancellation == null) {
      await Future<void>.delayed(delay);
      return;
    }

    final result = await Future.any<Object?>([
      Future<Object?>.delayed(delay, () => _retryDelaySentinel),
      cancellation.whenCancelled,
    ]);
    if (!identical(result, _retryDelaySentinel)) {
      throw TransportCancelledException(result);
    }
  }
}

final class DioTransportAttemptSuccess<T> {
  final T value;
  final TransportDiagnosticsResponseInfo response;

  const DioTransportAttemptSuccess({
    required this.value,
    required this.response,
  });
}
