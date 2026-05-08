import 'dart:typed_data';
import 'package:llm_dart_transport/dio.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart'
    show Logger, ProviderDioClientFactory, TransportCancellation;

import '../../core/llm_error.dart';
import '../../src/compatibility/http/dio_error_handler.dart';
import '../../src/compatibility/http/dio_request_executor.dart';
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
  late final CompatibilityDioRequestExecutor _requestExecutor;

  ElevenLabsClient(this.config) {
    // Use unified Dio client factory with ElevenLabs-specific strategy
    _dio = ProviderDioClientFactory.create(
      strategy: ElevenLabsDioStrategy(),
      config: config,
      overrides: config.dioOverrides,
    );
    _requestExecutor = CompatibilityDioRequestExecutor(
      dio: _dio,
      logger: _logger,
      mapDioException: (error) => DioErrorHandler.handleDioError(
        error,
        'ElevenLabs',
      ),
    );
  }

  /// Logger instance for debugging
  Logger get logger => _logger;

  /// Shared Dio client for compatibility bridge delegation.
  Dio get dio => _dio;

  /// Make a GET request and return JSON response
  Future<Map<String, dynamic>> getJson(
    String endpoint, {
    TransportCancellation? cancelToken,
  }) async {
    final response = await _requestExecutor.request(
      'GET',
      endpoint,
      cancelToken: cancelToken,
      failureLogMessage: 'HTTP GET request',
    );

    _ensureSuccessStatus(response, includeBody: true);
    return response.data as Map<String, dynamic>;
  }

  /// Make a GET request and return list response
  Future<List<dynamic>> getList(
    String endpoint, {
    TransportCancellation? cancelToken,
  }) async {
    final response = await _requestExecutor.request(
      'GET',
      endpoint,
      cancelToken: cancelToken,
      failureLogMessage: 'HTTP GET request',
    );

    _ensureSuccessStatus(response, includeBody: true);
    return response.data as List<dynamic>;
  }

  /// Make a POST request and return binary response (for TTS)
  Future<Uint8List> postBinary(
    String endpoint,
    Map<String, dynamic> data, {
    Map<String, String>? queryParams,
    TransportCancellation? cancelToken,
  }) async {
    final response = await _requestExecutor.request(
      'POST',
      endpoint,
      data: data,
      queryParameters: queryParams,
      cancelToken: cancelToken,
      options: Options(responseType: ResponseType.bytes),
      failureLogMessage: 'HTTP binary request',
    );

    _ensureSuccessStatus(response);
    return Uint8List.fromList(response.data as List<int>);
  }

  /// Make a POST request with form data and return JSON response (for STT)
  Future<Map<String, dynamic>> postFormData(
    String endpoint,
    FormData formData, {
    Map<String, String>? queryParams,
    TransportCancellation? cancelToken,
  }) async {
    final response = await _requestExecutor.request(
      'POST',
      endpoint,
      data: formData,
      cancelToken: cancelToken,
      queryParameters: queryParams,
      options: Options(headers: {'xi-api-key': config.apiKey}),
      failureLogMessage: 'HTTP form request',
    );

    _ensureSuccessStatus(
      response,
      customMessage:
          'ElevenLabs STT API returned status ${response.statusCode}',
    );

    try {
      // Handle both JSON and string responses like original implementation
      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        return responseData;
      } else if (responseData is String) {
        final Map<String, dynamic> parsed = {};
        parsed['text'] = responseData;
        return parsed;
      } else {
        return responseData as Map<String, dynamic>;
      }
    } catch (e) {
      if (e is LLMError) rethrow;
      throw GenericError('Unexpected error: $e');
    }
  }

  /// Get response headers from last request
  String? getContentType(Response response) {
    return response.headers.value('content-type');
  }

  void _ensureSuccessStatus(
    Response response, {
    bool includeBody = false,
    String? customMessage,
  }) {
    if (response.statusCode == 200) {
      return;
    }

    final message = customMessage ??
        'ElevenLabs API returned status ${response.statusCode}'
            '${includeBody ? ': ${response.data}' : ''}';
    throw ProviderError(message);
  }
}
