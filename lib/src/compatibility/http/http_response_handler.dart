import 'dart:convert';

import 'package:llm_dart_transport/dio.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart'
    show
        InvalidDioResponseBodyFactory,
        JsonObjectResponseDecoder,
        Level,
        LogSanitizer,
        Logger,
        TransportResponseFormatException,
        decodeDioResponseTextStream,
        bindDioCancellation;

import '../../../core/cancellation.dart';
import '../../../core/llm_error.dart';

typedef CompatibilityDioErrorMapper = Future<LLMError> Function(
  DioException error,
);

/// Unified HTTP response handler for all providers
///
/// This utility class provides consistent response handling across all
/// AI providers, including proper error handling and response parsing.
class HttpResponseHandler {
  static final Logger _logger = Logger('HttpResponseHandler');

  /// Validates that a compatibility HTTP response uses the expected success status.
  static Future<void> ensureSuccessStatus(
    Response response, {
    required String providerName,
    Logger? logger,
    Future<void> Function(Response response)? onFailure,
  }) async {
    final log = logger ?? _logger;
    if (log.isLoggable(Level.FINE)) {
      log.fine('$providerName HTTP status: ${response.statusCode}');
    }

    if (response.statusCode == 200) {
      return;
    }

    log.severe('$providerName API returned status ${response.statusCode}');
    final failureHandler = onFailure;
    if (failureHandler != null) {
      await failureHandler(response);
      return;
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: '$providerName API returned status ${response.statusCode}',
    );
  }

  /// Parse HTTP response data to Map\<String, dynamic\>
  static Map<String, dynamic> parseJsonResponse(
    dynamic responseData, {
    String? providerName,
  }) {
    final provider = providerName ?? 'Unknown';

    try {
      return JsonObjectResponseDecoder.decode(
        responseData,
        sourceName: provider,
      );
    } on TransportResponseFormatException catch (e) {
      _logger.severe(e.message);
      throw ResponseFormatError(
        e.message,
        e.responseBody?.toString() ?? '',
      );
    } catch (e) {
      if (e is LLMError) {
        rethrow;
      }
      _logger.severe('Unexpected error parsing $provider response: $e');
      throw GenericError('Failed to parse $provider API response: $e');
    }
  }

  /// Create a standardized postJson method for providers
  static Future<Map<String, dynamic>> postJson(
    Dio dio,
    String endpoint,
    Map<String, dynamic> data, {
    String? providerName,
    Logger? logger,
    Map<String, dynamic>? queryParameters,
    Options? options,
    TransportCancellation? cancelToken,
    CompatibilityDioErrorMapper? mapDioException,
  }) async {
    final provider = providerName ?? 'Unknown';
    final log = logger ?? _logger;

    try {
      if (log.isLoggable(Level.FINE)) {
        log.fine(
            '$provider request: POST ${LogSanitizer.sanitizeEndpoint(endpoint)}');
        log.fine('$provider request payload: ${jsonEncode(data)}');
      }

      final response = await dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: bindDioCancellation(cancelToken),
      );

      await ensureSuccessStatus(
        response,
        providerName: provider,
        logger: log,
      );

      return parseJsonResponse(response.data, providerName: provider);
    } on DioException catch (e) {
      log.severe('$provider HTTP request failed: ${e.message}');
      final dioErrorMapper = mapDioException;
      throw await (dioErrorMapper?.call(e) ??
          DioErrorHandler.handleDioError(e, provider));
    } catch (e) {
      if (e is LLMError) {
        rethrow;
      }
      log.severe('Unexpected error in $provider postJson: $e');
      throw GenericError('Unexpected error: $e');
    }
  }

  /// Creates a standardized text-stream POST helper for compatibility clients.
  static Stream<String> postTextStream(
    Dio dio,
    String endpoint,
    Map<String, dynamic> data, {
    String? providerName,
    Logger? logger,
    Options? options,
    TransportCancellation? cancelToken,
    CompatibilityDioErrorMapper? mapDioException,
    InvalidDioResponseBodyFactory? invalidBodyErrorFactory,
  }) async* {
    final provider = providerName ?? 'Unknown';
    final log = logger ?? _logger;

    try {
      if (log.isLoggable(Level.FINE)) {
        log.fine(
          '$provider stream request: POST ${LogSanitizer.sanitizeEndpoint(endpoint)}',
        );
        log.fine('$provider stream request payload: ${jsonEncode(data)}');
      }

      final response = await dio.post(
        endpoint,
        data: data,
        options: options,
        cancelToken: bindDioCancellation(cancelToken),
      );

      await ensureSuccessStatus(
        response,
        providerName: provider,
        logger: log,
      );

      yield* decodeDioResponseTextStream(
        response.data,
        invalidBodyErrorFactory: invalidBodyErrorFactory,
      );
    } on DioException catch (e) {
      log.severe('$provider stream request failed: ${e.message}');
      final dioErrorMapper = mapDioException;
      throw await (dioErrorMapper?.call(e) ??
          DioErrorHandler.handleDioError(e, provider));
    } catch (e) {
      if (e is LLMError) {
        rethrow;
      }
      log.severe('Unexpected error in $provider postTextStream: $e');
      throw GenericError('Unexpected error: $e');
    }
  }

}
