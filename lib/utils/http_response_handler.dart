import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import '../core/llm_error.dart';

/// Unified HTTP response handler for all providers
///
/// This utility class provides consistent response handling across all
/// AI providers, including proper error handling and response parsing.
class HttpResponseHandler {
  static final Logger _logger = Logger('HttpResponseHandler');

  /// Parse HTTP response data to Map\<String, dynamic\>
  ///
  /// Handles different response types:
  /// - `Map<String, dynamic>` (direct JSON object)
  /// - `String` (JSON string that needs parsing)
  /// - Other types (error cases)
  static Map<String, dynamic> parseJsonResponse(
    dynamic responseData, {
    String? providerName,
  }) {
    final provider = providerName ?? 'Unknown';

    try {
      // Handle direct JSON object
      if (responseData is Map<String, dynamic>) {
        return responseData;
      }

      // Handle JSON string
      if (responseData is String) {
        // Check if it's HTML (common error case)
        if (responseData.trim().startsWith('<')) {
          _logger.severe('$provider API returned HTML instead of JSON');
          throw ResponseFormatError(
            '$provider API returned HTML page instead of JSON response. '
            'This usually indicates an incorrect API endpoint or authentication issue.',
            responseData.length > 500
                ? '${responseData.substring(0, 500)}...'
                : responseData,
          );
        }

        // Try to parse as JSON
        try {
          final jsonData = jsonDecode(responseData);
          if (jsonData is Map<String, dynamic>) {
            return jsonData;
          } else {
            throw ResponseFormatError(
              '$provider API returned JSON that is not an object',
              responseData.length > 500
                  ? '${responseData.substring(0, 500)}...'
                  : responseData,
            );
          }
        } on FormatException catch (e) {
          _logger.severe('$provider API returned invalid JSON: ${e.message}');
          throw ResponseFormatError(
            '$provider API returned invalid JSON: ${e.message}',
            responseData.length > 500
                ? '${responseData.substring(0, 500)}...'
                : responseData,
          );
        }
      }

      // Handle other types
      throw ResponseFormatError(
        '$provider API returned unexpected response type: ${responseData.runtimeType}',
        responseData.toString().length > 500
            ? '${responseData.toString().substring(0, 500)}...'
            : responseData.toString(),
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
  ///
  /// This method provides consistent error handling and response parsing
  /// for all providers that need postJson functionality.
  static Future<Map<String, dynamic>> postJson(
    Dio dio,
    String endpoint,
    Map<String, dynamic> data, {
    String? providerName,
    Logger? logger,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final provider = providerName ?? 'Unknown';
    final log = logger ?? _logger;

    try {
      // Log request if fine logging is enabled
      if (log.isLoggable(Level.FINE)) {
        log.fine('$provider request: POST $endpoint');
        log.fine('$provider request payload: ${jsonEncode(data)}');
      }

      final response = await dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

      if (log.isLoggable(Level.FINE)) {
        log.fine('$provider HTTP status: ${response.statusCode}');
      }

      // Check status code
      if (response.statusCode != 200) {
        log.severe('$provider API returned status ${response.statusCode}');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: '$provider API returned status ${response.statusCode}',
        );
      }

      // Parse response using unified handler
      return parseJsonResponse(response.data, providerName: provider);
    } on DioException catch (e) {
      log.severe('$provider HTTP request failed: ${e.message}');
      // Convert DioException to LLMError using centralized handler
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
    CancelToken? cancelToken,
  }) async {
    final provider = providerName ?? 'Unknown';
    final log = logger ?? _logger;

    try {
      if (log.isLoggable(Level.FINE)) {
        log.fine('$provider request: GET $endpoint');
      }

      final response = await dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
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
      // Convert DioException to LLMError using centralized handler
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
