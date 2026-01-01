import 'dart:convert';

import 'package:dio/dio.dart' hide CancelToken;
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:logging/logging.dart';
import 'dio_strategy.dart';
import 'openai_request_config.dart';

/// Core OpenAI HTTP client shared across all capability modules
///
/// This class provides the foundational HTTP functionality that all
/// OpenAI capability implementations can use. It handles:
/// - Authentication and headers
/// - Request/response processing
/// - Error handling
/// - SSE stream parsing
/// - Provider-specific configurations
class OpenAIClient {
  final OpenAIRequestConfig config;
  final Logger logger = Logger('OpenAIClient');
  late final Dio dio;

  // Buffer for incomplete SSE chunks.
  final SseChunkParser _sseParser = SseChunkParser();

  OpenAIClient(this.config) {
    // Use unified Dio client factory with OpenAI-specific strategy
    dio = DioClientFactory.create(
      strategy: OpenAIDioStrategy(providerName: config.providerName),
      config: config,
    );
  }

  /// Get provider ID based on base URL for provider-specific behavior
  String get providerId {
    final configured = config.providerId.trim();
    if (configured.isNotEmpty) return configured;

    final baseUrl = config.baseUrl.toLowerCase();

    if (baseUrl.contains('openrouter')) {
      return 'openrouter';
    } else if (baseUrl.contains('groq')) {
      return 'groq';
    } else if (baseUrl.contains('deepseek')) {
      return 'deepseek';
    } else if (baseUrl.contains('azure')) {
      return 'azure-openai';
    } else if (baseUrl.contains('copilot') || baseUrl.contains('github')) {
      return 'copilot';
    } else if (baseUrl.contains('together')) {
      return 'together';
    } else if (baseUrl.contains('openai')) {
      return 'openai';
    } else {
      return 'openai'; // Default fallback for OpenAI-compatible APIs
    }
  }

  /// Parse a Server-Sent Events (SSE) chunk from OpenAI's streaming API
  ///
  /// This method handles incomplete SSE chunks that can be split across network boundaries.
  /// It maintains an internal buffer to reconstruct complete SSE events.
  ///
  /// Returns:
  /// - `List<Map<String, dynamic>>` - List of parsed JSON objects from the chunk
  /// - Empty list if no valid data found or chunk should be skipped
  ///
  /// Throws:
  /// - `ResponseFormatError` - If critical parsing errors occur
  List<Map<String, dynamic>> parseSSEChunk(String chunk) {
    final results = <Map<String, dynamic>>[];

    final lines = _sseParser.parse(chunk);
    if (lines.isEmpty) {
      // No complete lines yet, keep buffering.
      return results;
    }
    for (final line in lines) {
      final data = line.data;

      // Handle completion signal.
      if (data == '[DONE]') {
        // Clear buffer and return empty list to signal completion.
        _sseParser.reset();
        return [];
      }

      // Skip empty data.
      if (data.isEmpty) {
        continue;
      }

      try {
        final json = jsonDecode(data);
        if (json is! Map<String, dynamic>) {
          logger.warning('SSE chunk is not a JSON object: $data');
          continue;
        }

        // Check for error in the SSE data.
        if (json.containsKey('error')) {
          final error = json['error'] as Map<String, dynamic>?;
          if (error != null) {
            final message = error['message'] as String? ?? 'Unknown error';
            final type = error['type'] as String?;
            final code = error['code']?.toString();

            throw ResponseFormatError(
              'SSE stream error: $message${type != null ? ' (type: $type)' : ''}${code != null ? ' (code: $code)' : ''}',
              data,
            );
          }
        }

        results.add(json);
      } catch (e) {
        if (e is LLMError) rethrow;

        // Log and skip malformed JSON chunks, but don't fail the entire stream.
        logger.warning('Failed to parse SSE chunk JSON: $e, data: $data');
        continue;
      }
    }

    return results;
  }

  /// Reset SSE buffer (call when starting a new stream)
  void resetSSEBuffer() {
    _sseParser.reset();
  }

  /// Convert ChatMessage to OpenAI API format
  Map<String, dynamic> convertMessage(ChatMessage message) {
    final result = <String, dynamic>{'role': message.role.name};

    // Add name field if present (useful for system messages)
    if (message.name != null) {
      result['name'] = message.name;
    }

    switch (message.messageType) {
      case TextMessage():
        result['content'] = message.content;
        break;
      case ImageMessage(mime: final mime, data: final data):
        // Handle base64 encoded images
        final base64Data = base64Encode(data);
        final imageDataUrl = 'data:${mime.mimeType};base64,$base64Data';

        // Build content array with optional text + image
        final contentArray = <Map<String, dynamic>>[];

        // Add text content if present
        if (message.content.isNotEmpty) {
          contentArray.add({
            'type': 'text',
            'text': message.content,
          });
        }

        // Add image content
        contentArray.add({
          'type': 'image_url',
          'image_url': {'url': imageDataUrl},
        });

        result['content'] = contentArray;
        break;

      case ImageUrlMessage(url: final url):
        // Build content array with optional text + image
        final contentArray = <Map<String, dynamic>>[];

        // Add text content if present
        if (message.content.isNotEmpty) {
          contentArray.add({
            'type': 'text',
            'text': message.content,
          });
        }

        // Add image content
        contentArray.add({
          'type': 'image_url',
          'image_url': {'url': url},
        });

        result['content'] = contentArray;
        break;

      case FileMessage(data: final data):
        // Handle file messages (documents, audio, video, etc.)
        final base64Data = base64Encode(data);

        // Build content array with optional text + file
        final contentArray = <Map<String, dynamic>>[];

        // Add text content if present
        if (message.content.isNotEmpty) {
          contentArray.add({
            'type': 'text',
            'text': message.content,
          });
        }

        // Add file content
        // Chat Completions API format: { type: 'file', file: { file_data: '<base64>' } }
        contentArray.add({
          'type': 'file',
          'file': {
            'file_data': base64Data,
          },
        });

        result['content'] = contentArray;
        break;

      case ToolUseMessage(toolCalls: final toolCalls):
        result['tool_calls'] = toolCalls.map((tc) => tc.toJson()).toList();
        break;
      case ToolResultMessage(results: final results):
        // Tool results are normally handled in buildApiMessages where we
        // expand them into individual tool role messages, but we keep a sane
        // default here for completeness.
        result['content'] =
            message.content.isNotEmpty ? message.content : 'Tool result';
        result['tool_call_id'] = results.isNotEmpty ? results.first.id : null;
        break;
    }

    return result;
  }

  /// Build API messages array from ChatMessage list
  ///
  /// Note: System prompt should be added by the calling module if needed,
  /// not here to avoid duplication.
  List<Map<String, dynamic>> buildApiMessages(List<ChatMessage> messages) {
    final apiMessages = <Map<String, dynamic>>[];

    // Convert messages to OpenAI format
    for (final message in messages) {
      if (message.messageType is ToolResultMessage) {
        // Expand tool results into separate `tool` role messages.
        //
        // OpenAI expects the tool message content to be the tool OUTPUT,
        // not the original function arguments, so we prefer the
        // ChatMessage.content here and only fall back to arguments if the
        // content is empty.
        final toolResults = (message.messageType as ToolResultMessage).results;
        for (final result in toolResults) {
          apiMessages.add({
            'role': 'tool',
            'tool_call_id': result.id,
            'content': message.content.isNotEmpty
                ? message.content
                : (result.function.arguments.isNotEmpty
                    ? result.function.arguments
                    : 'Tool result'),
          });
        }
      } else {
        apiMessages.add(convertMessage(message));
      }
    }

    return apiMessages;
  }

  /// Make a POST request with JSON body
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) async {
    if (config.apiKey.isEmpty) {
      throw AuthError('Missing ${config.providerName} API key');
    }

    try {
      // Optimized logging with condition check
      if (logger.isLoggable(Level.FINE)) {
        logger.fine('${config.providerName} request: POST /$endpoint');
        logger.fine(
            '${config.providerName} request headers: ${dio.options.headers}');
      }

      final response = await withDioCancelToken(
        cancelToken,
        (dioToken) => dio.post(
          endpoint,
          data: body,
          cancelToken: dioToken,
        ),
      );

      if (logger.isLoggable(Level.FINE)) {
        logger
            .fine('${config.providerName} HTTP status: ${response.statusCode}');
      }

      if (response.statusCode != 200) {
        _handleErrorResponse(response, endpoint);
      }

      // Use unified response parsing while keeping OpenAI's error handling
      return HttpResponseHandler.parseJsonResponse(
        response.data,
        providerName: config.providerName,
      );
    } on DioException catch (e) {
      throw await handleDioError(e);
    } catch (e) {
      throw GenericError('Unexpected error: $e');
    }
  }

  /// Make a GET request and return a JSON object response.
  Future<Map<String, dynamic>> getJson(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    if (config.apiKey.isEmpty) {
      throw AuthError('Missing ${config.providerName} API key');
    }

    try {
      if (logger.isLoggable(Level.FINE)) {
        logger.fine('${config.providerName} request: GET /$endpoint');
        logger.fine(
            '${config.providerName} request headers: ${dio.options.headers}');
      }

      final response = await withDioCancelToken(
        cancelToken,
        (dioToken) => dio.get(
          endpoint,
          queryParameters: queryParameters,
          cancelToken: dioToken,
        ),
      );

      if (logger.isLoggable(Level.FINE)) {
        logger
            .fine('${config.providerName} HTTP status: ${response.statusCode}');
      }

      if (response.statusCode != 200) {
        _handleErrorResponse(response, endpoint);
      }

      return HttpResponseHandler.parseJsonResponse(
        response.data,
        providerName: config.providerName,
      );
    } on DioException catch (e) {
      throw await handleDioError(e);
    } catch (e) {
      throw GenericError('Unexpected error: $e');
    }
  }

  /// Make a POST request with form data
  Future<Map<String, dynamic>> postForm(
    String endpoint,
    FormData formData, {
    CancelToken? cancelToken,
  }) async {
    if (config.apiKey.isEmpty) {
      throw AuthError('Missing ${config.providerName} API key');
    }

    try {
      if (logger.isLoggable(Level.FINE)) {
        logger.fine('${config.providerName} request: POST /$endpoint (form)');
        logger.fine(
            '${config.providerName} request headers: ${dio.options.headers}');
      }

      final response = await withDioCancelToken(
        cancelToken,
        (dioToken) => dio.post(
          endpoint,
          data: formData,
          cancelToken: dioToken,
        ),
      );

      if (logger.isLoggable(Level.FINE)) {
        logger
            .fine('${config.providerName} HTTP status: ${response.statusCode}');
      }

      if (response.statusCode != 200) {
        _handleErrorResponse(response, endpoint);
      }

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw await handleDioError(e);
    } catch (e) {
      throw GenericError('Unexpected error: $e');
    }
  }

  /// Make a POST request and return raw bytes
  Future<List<int>> postRaw(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) async {
    if (config.apiKey.isEmpty) {
      throw AuthError('Missing ${config.providerName} API key');
    }

    try {
      final response = await withDioCancelToken(
        cancelToken,
        (dioToken) => dio.post(
          endpoint,
          data: body,
          cancelToken: dioToken,
          options: Options(responseType: ResponseType.bytes),
        ),
      );

      if (response.statusCode != 200) {
        _handleErrorResponse(response, endpoint);
      }

      return response.data as List<int>;
    } on DioException catch (e) {
      throw await handleDioError(e);
    } catch (e) {
      throw GenericError('Unexpected error: $e');
    }
  }

  /// Make a GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    CancelToken? cancelToken,
  }) async {
    if (config.apiKey.isEmpty) {
      throw AuthError('Missing ${config.providerName} API key');
    }

    try {
      if (logger.isLoggable(Level.FINE)) {
        logger.fine('${config.providerName} request: GET /$endpoint');
        logger.fine(
            '${config.providerName} request headers: ${dio.options.headers}');
      }

      final response = await withDioCancelToken(
        cancelToken,
        (dioToken) => dio.get(endpoint, cancelToken: dioToken),
      );

      if (logger.isLoggable(Level.FINE)) {
        logger
            .fine('${config.providerName} HTTP status: ${response.statusCode}');
      }

      if (response.statusCode != 200) {
        _handleErrorResponse(response, endpoint);
      }

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw await handleDioError(e);
    } catch (e) {
      throw GenericError('Unexpected error: $e');
    }
  }

  /// Make a GET request and return raw bytes
  Future<List<int>> getRaw(
    String endpoint, {
    CancelToken? cancelToken,
  }) async {
    if (config.apiKey.isEmpty) {
      throw AuthError('Missing ${config.providerName} API key');
    }

    try {
      final response = await withDioCancelToken(
        cancelToken,
        (dioToken) => dio.get(
          endpoint,
          options: Options(responseType: ResponseType.bytes),
          cancelToken: dioToken,
        ),
      );

      if (response.statusCode != 200) {
        _handleErrorResponse(response, endpoint);
      }

      return response.data as List<int>;
    } on DioException catch (e) {
      throw await handleDioError(e);
    } catch (e) {
      throw GenericError('Unexpected error: $e');
    }
  }

  /// Make a DELETE request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    CancelToken? cancelToken,
  }) async {
    if (config.apiKey.isEmpty) {
      throw AuthError('Missing ${config.providerName} API key');
    }

    try {
      if (logger.isLoggable(Level.FINE)) {
        logger.fine('${config.providerName} request: DELETE /$endpoint');
        logger.fine(
            '${config.providerName} request headers: ${dio.options.headers}');
      }

      final response = await withDioCancelToken(
        cancelToken,
        (dioToken) => dio.delete(endpoint, cancelToken: dioToken),
      );

      if (logger.isLoggable(Level.FINE)) {
        logger
            .fine('${config.providerName} HTTP status: ${response.statusCode}');
      }

      if (response.statusCode != 200) {
        _handleErrorResponse(response, endpoint);
      }

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw await handleDioError(e);
    } catch (e) {
      throw GenericError('Unexpected error: $e');
    }
  }

  /// Make a POST request and return SSE stream
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) async* {
    if (config.apiKey.isEmpty) {
      throw AuthError('Missing ${config.providerName} API key');
    }

    // Reset SSE buffer for new stream
    resetSSEBuffer();

    try {
      if (logger.isLoggable(Level.FINE)) {
        logger.fine('${config.providerName} request: POST /$endpoint (stream)');
        logger.fine(
            '${config.providerName} request headers: ${dio.options.headers}');
      }

      final response = await withDioCancelToken(
        cancelToken,
        (dioToken) => dio.post(
          endpoint,
          data: body,
          cancelToken: dioToken,
          options: Options(
            responseType: ResponseType.stream,
            headers: {'Accept': 'text/event-stream'},
          ),
        ),
      );

      if (response.statusCode != 200) {
        _handleErrorResponse(response, endpoint);
      }

      // Handle ResponseBody properly for streaming
      final responseBody = response.data;
      Stream<List<int>> stream;

      if (responseBody is Stream<List<int>>) {
        stream = responseBody;
      } else if (responseBody is ResponseBody) {
        stream = responseBody.stream;
      } else {
        throw GenericError(
            'Unexpected response type: ${responseBody.runtimeType}');
      }

      // Use UTF-8 stream decoder to handle incomplete byte sequences
      final decoder = Utf8StreamDecoder();

      await for (final chunk in stream) {
        final decoded = decoder.decode(chunk);
        if (decoded.isNotEmpty) {
          yield decoded;
        }
      }

      // Flush any remaining bytes
      final remaining = decoder.flush();
      if (remaining.isNotEmpty) {
        yield remaining;
      }
    } on DioException catch (e) {
      throw await handleDioError(e);
    } catch (e) {
      throw GenericError('Unexpected error: $e');
    }
  }

  /// Handle Dio errors and convert them to appropriate LLM errors
  Future<LLMError> handleDioError(DioException e) async {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutError('Request timeout: ${e.message}');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;

        if (statusCode != null) {
          // Use HttpErrorMapper for consistent error handling
          final errorMessage =
              await _extractErrorMessage(responseData) ?? '$statusCode';
          final responseMap =
              responseData is Map<String, dynamic> ? responseData : null;

          return HttpErrorMapper.mapStatusCode(
              statusCode, errorMessage, responseMap);
        } else {
          return ResponseFormatError(
            'HTTP error without status code',
            responseData?.toString() ?? '',
          );
        }
      case DioExceptionType.cancel:
        return CancelledError(e.message ?? 'Request cancelled');
      case DioExceptionType.connectionError:
        return const GenericError('Connection error');
      case DioExceptionType.badCertificate:
        return const GenericError('SSL certificate error');
      case DioExceptionType.unknown:
        return GenericError('Unknown error: ${e.message}');
    }
  }

  /// Extract error message from OpenAI API response
  Future<String?> _extractErrorMessage(dynamic responseData) async {
    // Handle ResponseBody by reading the stream
    if (responseData is ResponseBody) {
      try {
        final bytes = await responseData.stream.toList();
        final concatenated = bytes.expand((x) => x).toList();
        final content = utf8.decode(concatenated);

        // Try to parse as JSON
        try {
          final jsonData = jsonDecode(content) as Map<String, dynamic>;
          return _extractErrorMessageFromMap(jsonData);
        } catch (_) {
          // Not JSON, return raw content
          return content.isNotEmpty ? content : null;
        }
      } catch (_) {
        return null;
      }
    }

    if (responseData is Map<String, dynamic>) {
      return _extractErrorMessageFromMap(responseData);
    }

    return null;
  }

  /// Extract error message from a parsed Map
  String? _extractErrorMessageFromMap(Map<String, dynamic> responseData) {
    // OpenAI error format: {"error": {"message": "...", "type": "...", "code": "..."}}
    final error = responseData['error'] as Map<String, dynamic>?;
    if (error != null) {
      final message = error['message'] as String?;
      final type = error['type'] as String?;
      final code = error['code']?.toString();

      if (message != null) {
        final parts = <String>[message];
        if (type != null) parts.add('type: $type');
        if (code != null) parts.add('code: $code');
        return parts.join(', ');
      }
    }

    // Fallback: look for direct message field
    final directMessage = responseData['message'] as String?;
    if (directMessage != null) return directMessage;

    return null;
  }

  /// Handle error responses with specific error types
  Future<void> _handleErrorResponse(Response response, String endpoint) async {
    final statusCode = response.statusCode;
    final errorData = response.data;

    if (statusCode != null) {
      final errorMessage = await _extractErrorMessage(errorData) ??
          '${config.providerName} $endpoint API returned error status: $statusCode';
      final responseMap = errorData is Map<String, dynamic> ? errorData : null;

      throw HttpErrorMapper.mapStatusCode(
          statusCode, errorMessage, responseMap);
    } else {
      throw ResponseFormatError(
        '${config.providerName} $endpoint API returned unknown error',
        errorData?.toString() ?? '',
      );
    }
  }
}
