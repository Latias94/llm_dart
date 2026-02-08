import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import 'capability.dart';
import 'llm_error.dart';
import 'config.dart';
import '../models/chat_models.dart';
import '../models/tool_models.dart';
import '../utils/http_config_utils.dart';
import '../utils/log_sanitizer.dart';

/// Base class for HTTP-based LLM providers
///
/// This class provides common functionality for providers that use HTTP APIs,
/// reducing code duplication and ensuring consistent error handling.
abstract class BaseHttpProvider implements ChatCapability {
  final Dio _dio;
  final Logger _logger;

  BaseHttpProvider(this._dio, String loggerName) : _logger = Logger(loggerName);

  /// Protected access to Dio instance for subclasses
  Dio get dio => _dio;

  /// Protected access to Logger instance for subclasses
  Logger get logger => _logger;

  /// Provider-specific name for logging and error messages
  String get providerName;

  /// Build the request body for chat requests
  ///
  /// Each provider should implement this to format requests according to their API
  Map<String, dynamic> buildRequestBody(
    List<ChatMessage> messages,
    List<Tool>? tools,
    bool stream,
  );

  /// Parse the response into a ChatResponse
  ///
  /// Each provider should implement this to parse their specific response format
  ChatResponse parseResponse(Map<String, dynamic> responseData);

  /// Parse streaming events
  ///
  /// Each provider should implement this to parse their specific streaming format
  List<ChatStreamEvent> parseStreamEvents(String chunk);

  /// Get the chat endpoint path
  String get chatEndpoint;

  /// Validate API key before making requests
  void validateApiKey(String? apiKey) {
    if (apiKey == null || apiKey.isEmpty) {
      throw AuthError('Missing $providerName API key');
    }
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    try {
      final requestBody = buildRequestBody(messages, tools, false);

      // Optimized trace logging with condition check
      if (_logger.isLoggable(Level.FINEST)) {
        _logger.finest(
            '$providerName request payload: ${jsonEncode(requestBody)}');
      }

      // Log request headers and body for debugging
      if (_logger.isLoggable(Level.FINE)) {
        _logger.fine('$providerName request: POST $chatEndpoint');
        _logger.fine(
            '$providerName request headers: ${LogSanitizer.sanitizeHeaders(_dio.options.headers)}');
      }
      if (_logger.isLoggable(Level.FINE)) {
        _logger.fine('$providerName request body: ${jsonEncode(requestBody)}');
      }

      final response = await _dio.post(
        chatEndpoint,
        data: requestBody,
        cancelToken: cancelToken,
      );

      _logger.fine('$providerName HTTP status: ${response.statusCode}');

      // Enhanced error handling with detailed information
      if (response.statusCode != 200) {
        _handleHttpError(response.statusCode, response.data);
      }

      final responseData = response.data;
      if (responseData is! Map<String, dynamic>) {
        throw ResponseFormatError(
          'Invalid response format from $providerName API',
          responseData.toString(),
        );
      }

      return parseResponse(responseData);
    } on DioException catch (e) {
      throw await handleDioError(e);
    } catch (e) {
      throw GenericError('Unexpected error: $e');
    }
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    try {
      final requestBody = buildRequestBody(messages, tools, true);

      // Optimized trace logging with condition check
      if (_logger.isLoggable(Level.FINEST)) {
        _logger.finest(
            '$providerName stream request payload: ${jsonEncode(requestBody)}');
      }

      // Log request headers and body for debugging
      if (_logger.isLoggable(Level.FINE)) {
        _logger.fine('$providerName stream request: POST $chatEndpoint');
        _logger.fine(
            '$providerName stream request headers: ${LogSanitizer.sanitizeHeaders(_dio.options.headers)}');
      }
      if (_logger.isLoggable(Level.FINE)) {
        _logger.fine(
            '$providerName stream request body: ${jsonEncode(requestBody)}');
      }

      final response = await _dio.post(
        chatEndpoint,
        data: requestBody,
        options: Options(responseType: ResponseType.stream),
        cancelToken: cancelToken,
      );

      _logger.fine('$providerName stream HTTP status: ${response.statusCode}');

      if (response.statusCode != 200) {
        yield ErrorEvent(
          ProviderError(
              '$providerName API returned status ${response.statusCode}'),
        );
        return;
      }

      final stream = response.data as ResponseBody;

      await for (final chunk in stream.stream.map(utf8.decode)) {
        try {
          // Debug logging for Google provider
          if (providerName == 'Google') {
            _logger.fine('$providerName raw stream chunk: $chunk');
          }

          final events = parseStreamEvents(chunk);
          for (final event in events) {
            yield event;
          }
        } catch (e) {
          // Skip malformed chunks but log them
          _logger.warning('Failed to parse stream chunk: $e');
          _logger.warning('Raw chunk content: $chunk');
          continue;
        }
      }
    } on DioException catch (e) {
      yield ErrorEvent(await handleDioError(e));
    } catch (e) {
      yield ErrorEvent(GenericError('Unexpected error: $e'));
    }
  }

  /// Handle HTTP error responses with provider-specific error messages
  void _handleHttpError(int? statusCode, dynamic errorData) {
    if (statusCode == 401) {
      throw AuthError('Invalid $providerName API key');
    } else if (statusCode == 429) {
      throw const ProviderError('Rate limit exceeded');
    } else if (statusCode == 400) {
      throw ResponseFormatError(
        'Bad request - check your parameters',
        errorData?.toString() ?? '',
      );
    } else if (statusCode == 500) {
      throw ProviderError('$providerName server error');
    } else {
      throw ResponseFormatError(
        '$providerName API returned error status: $statusCode',
        errorData?.toString() ?? '',
      );
    }
  }

  /// Handle Dio exceptions with consistent error mapping
  Future<LLMError> handleDioError(DioException e) async {
    final error = await DioErrorHandler.handleDioError(e, providerName);

    // Log the error with provider context
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        _logger.warning('$providerName timeout error: ${error.message}');
        break;
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;
        _logger.warning('$providerName bad response: $statusCode, data: $data');
        break;
      case DioExceptionType.connectionError:
        _logger.warning('$providerName connection error: ${error.message}');
        break;
      case DioExceptionType.badCertificate:
        _logger.warning('$providerName SSL error: ${error.message}');
        break;
      default:
        _logger.warning('$providerName error: ${error.message}');
        break;
    }

    return error;
  }

  /// Create a configured Dio instance with advanced HTTP settings
  ///
  /// This method uses HttpConfigUtils to apply unified HTTP configurations
  /// including proxy, SSL, custom headers, and logging.
  ///
  /// This is the recommended way to create Dio instances for all providers
  /// to ensure consistent HTTP configuration support.
  static Dio createConfiguredDio({
    required String baseUrl,
    required Map<String, String> headers,
    required LLMConfig config,
    Duration? timeout,
  }) {
    return HttpConfigUtils.createConfiguredDio(
      baseUrl: baseUrl,
      defaultHeaders: headers,
      config: config,
      defaultTimeout: timeout,
    );
  }
}
