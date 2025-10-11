import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import '../../core/llm_error.dart';
import '../../utils/dio_client_factory.dart';
import 'config.dart';
import 'dio_strategy.dart';

/// ElevenLabs HTTP client implementation
///
/// This module handles all HTTP communication with the ElevenLabs API.
/// ElevenLabs provides text-to-speech and speech-to-text services.
class ElevenLabsClient {
  static final Logger _logger = Logger('ElevenLabsClient');

  final ElevenLabsConfig config;
  late final Dio _dio;

  ElevenLabsClient(this.config) {
    // Use unified Dio client factory with ElevenLabs-specific strategy
    _dio = DioClientFactory.create(
      strategy: ElevenLabsDioStrategy(),
      config: config,
    );
  }

  /// Logger instance for debugging
  Logger get logger => _logger;

  /// Make a GET request and return JSON response
  Future<Map<String, dynamic>> getJson(String endpoint) async {
    try {
      final response = await _dio.get(endpoint);

      if (response.statusCode != 200) {
        throw ProviderError(
          'ElevenLabs API returned status ${response.statusCode}: ${response.data}',
        );
      }

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw DioErrorHandler.handleDioError(e, 'ElevenLabs');
    }
  }

  /// Make a GET request and return list response
  Future<List<dynamic>> getList(String endpoint) async {
    try {
      final response = await _dio.get(endpoint);

      if (response.statusCode != 200) {
        throw ProviderError(
          'ElevenLabs API returned status ${response.statusCode}: ${response.data}',
        );
      }

      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw DioErrorHandler.handleDioError(e, 'ElevenLabs');
    }
  }

  /// Make a POST request and return binary response (for TTS)
  Future<Uint8List> postBinary(
    String endpoint,
    Map<String, dynamic> data, {
    Map<String, String>? queryParams,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParams,
        cancelToken: cancelToken,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode != 200) {
        throw ProviderError(
          'ElevenLabs API returned status ${response.statusCode}',
        );
      }

      return Uint8List.fromList(response.data as List<int>);
    } on DioException catch (e) {
      throw DioErrorHandler.handleDioError(e, 'ElevenLabs');
    }
  }

  /// Make a POST request with form data and return JSON response (for STT)
  Future<Map<String, dynamic>> postFormData(
    String endpoint,
    FormData formData, {
    Map<String, String>? queryParams,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: formData,
        cancelToken: cancelToken,
        queryParameters: queryParams,
        options: Options(headers: {'xi-api-key': config.apiKey}),
      );

      if (response.statusCode != 200) {
        throw ProviderError(
          'ElevenLabs STT API returned status ${response.statusCode}',
        );
      }

      // Handle both JSON and string responses like original implementation
      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        return responseData;
      } else if (responseData is String) {
        // Try to parse as JSON if it's a string
        try {
          final Map<String, dynamic> parsed = {};
          // For simple text responses, wrap in a text field
          parsed['text'] = responseData;
          return parsed;
        } catch (e) {
          throw ResponseFormatError(
            'Failed to parse ElevenLabs STT response: $e',
            responseData,
          );
        }
      } else {
        return responseData as Map<String, dynamic>;
      }
    } on DioException catch (e) {
      throw DioErrorHandler.handleDioError(e, 'ElevenLabs');
    } catch (e) {
      if (e is LLMError) rethrow;
      throw GenericError('Unexpected error: $e');
    }
  }

  /// Get response headers from last request
  String? getContentType(Response response) {
    return response.headers.value('content-type');
  }
}
