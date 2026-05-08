import 'dart:convert';
import 'package:llm_dart_transport/dio.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart'
    show Level, Logger, ProviderDioClientFactory, decodeDioResponseTextStream;

import '../../core/cancellation.dart';
import '../../core/llm_error.dart';
import '../../src/compatibility/http/dio_error_handler.dart';
import '../../src/compatibility/http/dio_request_executor.dart';
import 'config.dart';
import 'dio_strategy.dart';

/// Phind HTTP client implementation
///
/// This module handles all HTTP communication with the Phind API.
/// Phind has a unique API format that requires special handling.
class PhindClient {
  static final Logger _logger = Logger('PhindClient');

  final PhindConfig config;
  late final Dio _dio;
  late final CompatibilityDioRequestExecutor _requestExecutor;

  PhindClient(this.config) {
    // Use unified Dio client factory with Phind-specific strategy
    _dio = ProviderDioClientFactory.create(
      strategy: PhindDioStrategy(),
      config: config,
      overrides: config.dioOverrides,
    );
    _requestExecutor = CompatibilityDioRequestExecutor(
      dio: _dio,
      logger: _logger,
      mapDioException: (error) => DioErrorHandler.handleDioError(
        error,
        'Phind',
      ),
    );
  }

  /// Logger instance for debugging
  Logger get logger => _logger;

  /// Make a POST request and return JSON response
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    TransportCancellation? cancelToken,
  }) async {
    if (_logger.isLoggable(Level.FINE)) {
      _logger.fine('Phind request payload: ${jsonEncode(data)}');
    }

    final response = await _requestExecutor.request(
      'POST',
      endpoint,
      data: data,
      cancelToken: cancelToken,
      failureLogMessage: 'HTTP request',
    );

    _ensureSuccessStatus(response, includeBody: true);

    // Phind returns streaming response even for non-streaming requests
    final responseText = response.data as String;
    final content = _parsePhindStreamResponse(responseText);

    if (content.isEmpty) {
      throw const ProviderError('No completion choice returned.');
    }

    // Return a mock JSON response with the parsed content
    return {
      'choices': [
        {
          'message': {'content': content}
        }
      ]
    };
  }

  /// Make a POST request and return raw stream
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> data, {
    TransportCancellation? cancelToken,
  }) async* {
    if (_logger.isLoggable(Level.FINE)) {
      _logger.fine('Phind stream request payload: ${jsonEncode(data)}');
    }

    final response = await _requestExecutor.request(
      'POST',
      endpoint,
      data: data,
      cancelToken: cancelToken,
      options: Options(responseType: ResponseType.stream),
      failureLogMessage: 'Stream request',
    );

    _ensureSuccessStatus(response);

    yield* decodeDioResponseTextStream(
      response.data,
      invalidBodyErrorFactory: Exception.new,
    );
  }

  void _ensureSuccessStatus(
    Response response, {
    bool includeBody = false,
  }) {
    _logger.info('Phind HTTP status: ${response.statusCode}');
    if (response.statusCode == 200) {
      return;
    }

    final suffix = includeBody ? ': ${response.data}' : '';
    throw ProviderError(
      'Phind API returned status ${response.statusCode}$suffix',
    );
  }

  /// Parse the complete Phind streaming response into a single string
  String _parsePhindStreamResponse(String responseText) {
    return responseText
        .split('\n')
        .map(_parsePhindLine)
        .where((content) => content != null)
        .join();
  }

  /// Parse a single line from the Phind streaming response
  String? _parsePhindLine(String line) {
    if (!line.startsWith('data: ')) return null;

    final data = line.substring(6);
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      return json['choices']?.first?['delta']?['content'] as String?;
    } catch (e) {
      return null;
    }
  }
}
