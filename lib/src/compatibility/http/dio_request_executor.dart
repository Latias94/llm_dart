import 'package:llm_dart_transport/dio.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart'
    show Logger, bindDioCancellation;

import '../../../core/cancellation.dart';

/// Thin compatibility-owned Dio request executor.
///
/// This helper intentionally owns only request dispatch mechanics:
/// - binding cancellation,
/// - forwarding request options,
/// - logging request failures, and
/// - delegating Dio exception mapping back to the caller.
///
/// It does not own provider error semantics, status-code policy, or response
/// parsing.
class CompatibilityDioRequestExecutor {
  final Dio dio;
  final Logger logger;
  final Future<Object> Function(DioException error) mapDioException;

  const CompatibilityDioRequestExecutor({
    required this.dio,
    required this.logger,
    required this.mapDioException,
  });

  /// Sends a raw Dio request and delegates Dio exception mapping.
  Future<Response<dynamic>> request(
    String method,
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    TransportCancellation? cancelToken,
    String failureLogMessage = 'HTTP request',
  }) async {
    try {
      return await dio.request<dynamic>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: (options ?? Options()).copyWith(method: method),
        cancelToken: bindDioCancellation(cancelToken),
      );
    } on DioException catch (error) {
      logger.severe('$failureLogMessage failed: ${error.message}');
      throw await mapDioException(error);
    }
  }
}
