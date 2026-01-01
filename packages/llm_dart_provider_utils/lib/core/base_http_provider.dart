import 'dart:async';
import 'package:dio/dio.dart' hide CancelToken;
import 'package:logging/logging.dart';

import 'package:llm_dart_core/llm_dart_core.dart';
import '../utils/dio_cancellation.dart';
import '../utils/dio_error_handler.dart';
import '../utils/http_config_utils.dart';
import '../utils/log_redactor.dart';
import '../utils/log_utils.dart';
import '../utils/utf8_stream_decoder.dart';

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
          '$providerName request payload: ${LogUtils.jsonEncodeTruncated(requestBody)}',
        );
      }

      // Log request headers and body for debugging
      if (_logger.isLoggable(Level.FINE)) {
        _logger.fine('$providerName request: POST $chatEndpoint');
        _logger.fine(
          '$providerName request headers: ${LogRedactor.redactHeaders(Map<String, dynamic>.from(_dio.options.headers))}',
        );
      }
      if (_logger.isLoggable(Level.FINE)) {
        _logger.fine(
          '$providerName request body: ${LogUtils.jsonEncodeTruncated(requestBody)}',
        );
      }

      final response = await withDioCancelToken(
        cancelToken,
        (dioToken) => _dio.post(
          chatEndpoint,
          data: requestBody,
          cancelToken: dioToken,
        ),
      );

      _logger.fine('$providerName HTTP status: ${response.statusCode}');

      // Enhanced error handling with detailed information
      if (response.statusCode != 200) {
        _handleHttpError(
          statusCode: response.statusCode,
          errorData: response.data,
        );
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
      if (e is LLMError) rethrow;
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
            '$providerName stream request payload: ${LogUtils.jsonEncodeTruncated(requestBody)}');
      }

      // Log request headers and body for debugging
      if (_logger.isLoggable(Level.FINE)) {
        _logger.fine('$providerName stream request: POST $chatEndpoint');
        _logger.fine(
            '$providerName stream request headers: ${LogRedactor.redactHeaders(Map<String, dynamic>.from(_dio.options.headers))}');
      }
      if (_logger.isLoggable(Level.FINE)) {
        _logger.fine(
            '$providerName stream request body: ${LogUtils.jsonEncodeTruncated(requestBody)}');
      }

      final response = await withDioCancelToken(
        cancelToken,
        (dioToken) => _dio.post(
          chatEndpoint,
          data: requestBody,
          options: Options(responseType: ResponseType.stream),
          cancelToken: dioToken,
        ),
      );

      _logger.fine('$providerName stream HTTP status: ${response.statusCode}');

      if (response.statusCode != 200) {
        yield ErrorEvent(
          _mapHttpStatusToError(
            providerName: providerName,
            statusCode: response.statusCode,
            errorData: null,
          ),
        );
        return;
      }

      final stream = response.data as ResponseBody;
      final decoder = Utf8StreamDecoder();

      await for (final bytes in stream.stream) {
        String? decodedChunk;
        try {
          final chunk = decoder.decode(bytes);
          decodedChunk = chunk;
          if (chunk.isEmpty) continue;

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
          final chunk = decodedChunk ?? '';
          final safeChunk = chunk.length > 4096
              ? '${chunk.substring(0, 4096)}...[truncated]'
              : chunk;
          _logger.warning('Raw chunk content ($providerName): $safeChunk');
          continue;
        }
      }

      final remaining = decoder.flush();
      if (remaining.isNotEmpty) {
        try {
          final events = parseStreamEvents(remaining);
          for (final event in events) {
            yield event;
          }
        } catch (_) {
          // Best-effort flush; ignore trailing decode/parse errors.
        }
      }
    } on DioException catch (e) {
      yield ErrorEvent(await handleDioError(e));
    } catch (e) {
      if (e is LLMError) {
        yield ErrorEvent(e);
        return;
      }
      yield ErrorEvent(GenericError('Unexpected error: $e'));
    }
  }

  /// Handle HTTP error responses with provider-specific error messages
  void _handleHttpError({
    required int? statusCode,
    required dynamic errorData,
  }) {
    throw _mapHttpStatusToError(
      providerName: providerName,
      statusCode: statusCode,
      errorData: errorData,
    );
  }

  static LLMError _mapHttpStatusToError({
    required String providerName,
    required int? statusCode,
    required dynamic errorData,
  }) {
    final detail = _extractErrorDetail(errorData);

    if (statusCode == null) {
      return HttpError('$providerName API returned an unknown HTTP status');
    }

    switch (statusCode) {
      case 400:
      case 422:
        return InvalidRequestError(
          detail == null
              ? 'Bad request - check your parameters'
              : 'Bad request - $detail',
        );

      case 401:
      case 403:
        return AuthError(detail ?? 'Invalid $providerName API key');

      case 404:
        return NotFoundError(
          detail == null
              ? '$providerName API endpoint not found'
              : '$providerName API endpoint not found: $detail',
        );

      case 408:
      case 504:
        return TimeoutError(detail ?? '$providerName request timed out');

      case 429:
        return RateLimitError(detail ?? 'Rate limit exceeded');
    }

    if (statusCode >= 500 && statusCode <= 599) {
      return ServerError(
        detail ?? '$providerName server error',
        statusCode: statusCode,
      );
    }

    return HttpError(
      detail == null
          ? '$providerName API returned HTTP $statusCode'
          : '$providerName API returned HTTP $statusCode: $detail',
    );
  }

  static String? _extractErrorDetail(dynamic errorData) {
    if (errorData == null) return null;

    if (errorData is String) {
      final trimmed = errorData.trim();
      return trimmed.isEmpty ? null : LogUtils.truncate(trimmed);
    }

    if (errorData is Map<String, dynamic>) {
      final error = errorData['error'];
      if (error is Map<String, dynamic>) {
        final msg = error['message'];
        if (msg is String && msg.trim().isNotEmpty) {
          return LogUtils.truncate(msg.trim());
        }
      }

      final msg = errorData['message'];
      if (msg is String && msg.trim().isNotEmpty) {
        return LogUtils.truncate(msg.trim());
      }

      return LogUtils.truncate(errorData.toString());
    }

    if (errorData is Map) {
      return LogUtils.truncate(errorData.toString());
    }

    return LogUtils.truncate(errorData.toString());
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
