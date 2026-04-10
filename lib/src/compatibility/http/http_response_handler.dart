import 'dart:convert';

import 'package:llm_dart_transport/dio.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart'
    show
        JsonObjectResponseDecoder,
        Level,
        LogSanitizer,
        Logger,
        TransportResponseFormatException,
        bindDioCancellation;

import '../../../core/cancellation.dart';
import '../../../core/llm_error.dart';

/// Unified HTTP response handler for all providers
///
/// This utility class provides consistent response handling across all
/// AI providers, including proper error handling and response parsing.
class HttpResponseHandler {
  static final Logger _logger = Logger('HttpResponseHandler');

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

      if (log.isLoggable(Level.FINE)) {
        log.fine('$provider HTTP status: ${response.statusCode}');
      }

      if (response.statusCode != 200) {
        log.severe('$provider API returned status ${response.statusCode}');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: '$provider API returned status ${response.statusCode}',
        );
      }

      return parseJsonResponse(response.data, providerName: provider);
    } on DioException catch (e) {
      log.severe('$provider HTTP request failed: ${e.message}');
      throw await DioErrorHandler.handleDioError(e, provider);
    } catch (e) {
      if (e is LLMError) {
        rethrow;
      }
      log.severe('Unexpected error in $provider postJson: $e');
      throw GenericError('Unexpected error: $e');
    }
  }

  /// Create a standardized getJson method for providers
  static Future<Map<String, dynamic>> getJson(
    Dio dio,
    String endpoint, {
    String? providerName,
    Logger? logger,
    Map<String, dynamic>? queryParameters,
    Options? options,
    TransportCancellation? cancelToken,
  }) async {
    final provider = providerName ?? 'Unknown';
    final log = logger ?? _logger;

    try {
      if (log.isLoggable(Level.FINE)) {
        log.fine(
            '$provider request: GET ${LogSanitizer.sanitizeEndpoint(endpoint)}');
      }

      final response = await dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: options,
        cancelToken: bindDioCancellation(cancelToken),
      );

      if (log.isLoggable(Level.FINE)) {
        log.fine('$provider HTTP status: ${response.statusCode}');
      }

      if (response.statusCode != 200) {
        log.severe('$provider API returned status ${response.statusCode}');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: '$provider API returned status ${response.statusCode}',
        );
      }

      return parseJsonResponse(response.data, providerName: provider);
    } on DioException catch (e) {
      log.severe('$provider HTTP GET request failed: ${e.message}');
      throw await DioErrorHandler.handleDioError(e, provider);
    } catch (e) {
      if (e is LLMError) {
        rethrow;
      }
      log.severe('Unexpected error in $provider getJson: $e');
      throw GenericError('Unexpected error: $e');
    }
  }
}
