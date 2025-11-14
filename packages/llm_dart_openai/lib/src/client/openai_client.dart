import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../config/openai_config.dart';
import '../http/openai_dio_strategy.dart';
import '../utils/openai_utf8_stream_decoder.dart';

/// Core OpenAI HTTP client shared across all capability modules.
class OpenAIClient {
  final OpenAIConfig config;
  final Logger logger = Logger('OpenAIClient');
  late final Dio dio;

  final StringBuffer _sseBuffer = StringBuffer();

  OpenAIClient(this.config) {
    dio = DioClientFactory.create(
      strategy: OpenAIDioStrategy(),
      config: config,
    );
  }

  String get providerId {
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
      return 'openai';
    }
  }

  List<Map<String, dynamic>> parseSSEChunk(String chunk) {
    final results = <Map<String, dynamic>>[];

    _sseBuffer.write(chunk);
    final bufferContent = _sseBuffer.toString();
    final lastNewlineIndex = bufferContent.lastIndexOf('\n');

    if (lastNewlineIndex == -1) {
      return results;
    }

    final completeContent = bufferContent.substring(0, lastNewlineIndex + 1);
    final remainingContent = bufferContent.substring(lastNewlineIndex + 1);

    _sseBuffer
      ..clear()
      ..write(remainingContent);

    final lines = completeContent.split('\n');
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      if (trimmedLine.startsWith('data: ')) {
        final data = trimmedLine.substring(6).trim();

        if (data == '[DONE]') {
          _sseBuffer.clear();
          return [];
        }

        if (data.isEmpty) {
          continue;
        }

        try {
          final json = jsonDecode(data);
          if (json is! Map<String, dynamic>) {
            logger.warning('SSE chunk is not a JSON object: $data');
            continue;
          }

          final error = json['error'] as Map<String, dynamic>?;
          if (error != null) {
            final message = error['message']?.toString() ?? 'Unknown error';
            final type = error['type'] as String?;
            final code = error['code'] as String?;

            throw ResponseFormatError(
              'SSE stream error: $message'
              '${type != null ? ' (type: $type)' : ''}'
              '${code != null ? ' (code: $code)' : ''}',
              data,
            );
          }

          results.add(json);
        } catch (e) {
          if (e is LLMError) rethrow;
          logger.warning('Failed to parse SSE chunk JSON: $e, data: $data');
          continue;
        }
      }
    }

    return results;
  }

  void resetSSEBuffer() {
    _sseBuffer.clear();
  }

  Map<String, dynamic> convertMessage(ChatMessage message) {
    final result = <String, dynamic>{'role': message.role.name};

    if (message.name != null) {
      result['name'] = message.name;
    }

    switch (message.messageType) {
      case TextMessage():
        result['content'] = message.content;
        break;
      case ImageMessage(mime: final mime, data: final data):
        final base64Data = base64Encode(data);
        final imageDataUrl = 'data:${mime.mimeType};base64,$base64Data';
        final contentArray = <Map<String, dynamic>>[];

        if (message.content.isNotEmpty) {
          if (config.useResponsesAPI) {
            contentArray.add({'type': 'input_text', 'text': message.content});
          } else {
            contentArray.add({'type': 'text', 'text': message.content});
          }
        }

        if (config.useResponsesAPI) {
          contentArray.add({
            'type': 'input_image',
            'image_url': imageDataUrl,
          });
        } else {
          contentArray.add({
            'type': 'image_url',
            'image_url': {'url': imageDataUrl},
          });
        }

        result['content'] = contentArray;
        break;

      case ImageUrlMessage(url: final url):
        final contentArray = <Map<String, dynamic>>[];

        if (message.content.isNotEmpty) {
          if (config.useResponsesAPI) {
            contentArray.add({'type': 'input_text', 'text': message.content});
          } else {
            contentArray.add({'type': 'text', 'text': message.content});
          }
        }

        if (config.useResponsesAPI) {
          contentArray.add({'type': 'input_image', 'image_url': url});
        } else {
          contentArray.add({
            'type': 'image_url',
            'image_url': {'url': url},
          });
        }

        result['content'] = contentArray;
        break;

      case FileMessage(data: final data):
        final base64Data = base64Encode(data);
        final contentArray = <Map<String, dynamic>>[];

        if (message.content.isNotEmpty) {
          if (config.useResponsesAPI) {
            contentArray.add({'type': 'input_text', 'text': message.content});
          } else {
            contentArray.add({'type': 'text', 'text': message.content});
          }
        }

        if (config.useResponsesAPI) {
          contentArray.add({'type': 'input_file', 'file_data': base64Data});
        } else {
          contentArray.add({
            'type': 'file',
            'file': {'file_data': base64Data},
          });
        }

        result['content'] = contentArray;
        break;

      case ToolUseMessage(toolCalls: final toolCalls):
        result['tool_calls'] = toolCalls.map((tc) => tc.toJson()).toList();
        break;

      case ToolResultMessage(results: final results):
        result['content'] =
            message.content.isNotEmpty ? message.content : 'Tool result';
        result['tool_call_id'] = results.isNotEmpty ? results.first.id : null;
        break;
    }

    return result;
  }

  List<Map<String, dynamic>> buildApiMessages(List<ChatMessage> messages) {
    final apiMessages = <Map<String, dynamic>>[];

    for (final message in messages) {
      if (message.messageType is ToolResultMessage) {
        final toolResults = (message.messageType as ToolResultMessage).results;
        for (final result in toolResults) {
          apiMessages.add({
            'role': 'tool',
            'tool_call_id': result.id,
            'content': result.function.arguments.isNotEmpty
                ? result.function.arguments
                : message.content,
          });
        }
      } else {
        apiMessages.add(convertMessage(message));
      }
    }

    return apiMessages;
  }

  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) async {
    if (config.apiKey.isEmpty) {
      throw const AuthError('Missing OpenAI API key');
    }

    try {
      if (logger.isLoggable(Level.FINE)) {
        logger.fine('OpenAI request: POST /$endpoint');
        logger.fine('OpenAI request headers: ${dio.options.headers}');
      }

      final response = await dio.post(
        endpoint,
        data: body,
        cancelToken: cancelToken,
      );

      if (logger.isLoggable(Level.FINE)) {
        logger.fine('OpenAI HTTP status: ${response.statusCode}');
      }

      if (response.statusCode != 200) {
        _handleErrorResponse(response, endpoint);
      }

      return HttpResponseHandler.parseJsonResponse(
        response.data,
        providerName: 'OpenAI',
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      throw GenericError('Unexpected error: $e');
    }
  }

  Future<Map<String, dynamic>> postForm(
    String endpoint,
    FormData formData, {
    CancelToken? cancelToken,
  }) async {
    if (config.apiKey.isEmpty) {
      throw const AuthError('Missing OpenAI API key');
    }

    try {
      if (logger.isLoggable(Level.FINE)) {
        logger.fine('OpenAI request: POST /$endpoint (form)');
        logger.fine('OpenAI request headers: ${dio.options.headers}');
      }

      final response = await dio.post(
        endpoint,
        data: formData,
        cancelToken: cancelToken,
      );

      if (logger.isLoggable(Level.FINE)) {
        logger.fine('OpenAI HTTP status: ${response.statusCode}');
      }

      if (response.statusCode != 200) {
        _handleErrorResponse(response, endpoint);
      }

      return HttpResponseHandler.parseJsonResponse(
        response.data,
        providerName: 'OpenAI',
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      throw GenericError('Unexpected error: $e');
    }
  }

  Future<List<int>> postRaw(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) async {
    if (config.apiKey.isEmpty) {
      throw const AuthError('Missing OpenAI API key');
    }

    try {
      final response = await dio.post(
        endpoint,
        data: body,
        cancelToken: cancelToken,
        options: Options(responseType: ResponseType.bytes),
      );

      if (logger.isLoggable(Level.FINE)) {
        logger.fine('OpenAI HTTP status: ${response.statusCode}');
      }

      if (response.statusCode != 200) {
        _handleErrorResponse(response, endpoint);
      }

      return response.data as List<int>;
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      throw GenericError('Unexpected error: $e');
    }
  }

  Future<Map<String, dynamic>> getJson(
    String endpoint, {
    CancelToken? cancelToken,
  }) async {
    if (config.apiKey.isEmpty) {
      throw const AuthError('Missing OpenAI API key');
    }

    try {
      if (logger.isLoggable(Level.FINE)) {
        logger.fine('OpenAI request: GET /$endpoint');
        logger.fine('OpenAI request headers: ${dio.options.headers}');
      }

      final response = await dio.get(
        endpoint,
        cancelToken: cancelToken,
      );

      if (logger.isLoggable(Level.FINE)) {
        logger.fine('OpenAI HTTP status: ${response.statusCode}');
      }

      if (response.statusCode != 200) {
        _handleErrorResponse(response, endpoint);
      }

      return HttpResponseHandler.parseJsonResponse(
        response.data,
        providerName: 'OpenAI',
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      throw GenericError('Unexpected error: $e');
    }
  }

  Future<List<int>> getBytes(
    String endpoint, {
    CancelToken? cancelToken,
  }) async {
    if (config.apiKey.isEmpty) {
      throw const AuthError('Missing OpenAI API key');
    }

    try {
      if (logger.isLoggable(Level.FINE)) {
        logger.fine('OpenAI request: GET /$endpoint (bytes)');
        logger.fine('OpenAI request headers: ${dio.options.headers}');
      }

      final response = await dio.get(
        endpoint,
        options: Options(responseType: ResponseType.bytes),
        cancelToken: cancelToken,
      );

      if (logger.isLoggable(Level.FINE)) {
        logger.fine('OpenAI HTTP status: ${response.statusCode}');
      }

      if (response.statusCode != 200) {
        _handleErrorResponse(response, endpoint);
      }

      return response.data as List<int>;
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      throw GenericError('Unexpected error: $e');
    }
  }

  Future<Map<String, dynamic>> delete(
    String endpoint, {
    CancelToken? cancelToken,
  }) async {
    if (config.apiKey.isEmpty) {
      throw const AuthError('Missing OpenAI API key');
    }

    try {
      if (logger.isLoggable(Level.FINE)) {
        logger.fine('OpenAI request: DELETE /$endpoint');
        logger.fine('OpenAI request headers: ${dio.options.headers}');
      }

      final response = await dio.delete(
        endpoint,
        cancelToken: cancelToken,
      );

      if (logger.isLoggable(Level.FINE)) {
        logger.fine('OpenAI HTTP status: ${response.statusCode}');
      }

      if (response.statusCode != 200) {
        _handleErrorResponse(response, endpoint);
      }

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      throw GenericError('Unexpected error: $e');
    }
  }

  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) async* {
    if (config.apiKey.isEmpty) {
      throw const AuthError('Missing OpenAI API key');
    }

    resetSSEBuffer();

    try {
      if (logger.isLoggable(Level.FINE)) {
        logger.fine('OpenAI request: POST /$endpoint (stream)');
        logger.fine('OpenAI request headers: ${dio.options.headers}');
      }

      final response = await dio.post(
        endpoint,
        data: body,
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'},
        ),
      );

      if (logger.isLoggable(Level.FINE)) {
        logger.fine('OpenAI HTTP status: ${response.statusCode}');
      }

      if (response.statusCode != 200) {
        _handleErrorResponse(response, endpoint);
      }

      final responseBody = response.data;
      Stream<List<int>> stream;

      if (responseBody is Stream<List<int>>) {
        stream = responseBody;
      } else if (responseBody is ResponseBody) {
        stream = responseBody.stream;
      } else {
        throw GenericError(
          'Unexpected response type: ${responseBody.runtimeType}',
        );
      }

      final decoder = Utf8StreamDecoder();

      await for (final chunk in stream) {
        final decoded = decoder.decode(chunk);
        if (decoded.isNotEmpty) {
          yield decoded;
        }
      }

      final remaining = decoder.flush();
      if (remaining.isNotEmpty) {
        yield remaining;
      }
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      throw GenericError('Unexpected error: $e');
    }
  }

  LLMError handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutError('Request timeout: ${e.message}');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;

        if (statusCode != null) {
          final errorMessage =
              _extractErrorMessage(statusCode, responseData) ?? '$statusCode';
          final responseMap =
              responseData is Map<String, dynamic> ? responseData : null;

          return HttpErrorMapper.mapStatusCode(
            statusCode,
            errorMessage,
            responseMap,
          );
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

  String? _extractErrorMessage(int statusCode, dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final error = responseData['error'] as Map<String, dynamic>?;
      if (error != null) {
        final message = error['message'] as String?;
        final type = error['type'] as String?;
        final code = error['code'] as String?;

        if (message != null) {
          final parts = <String>[message];
          if (type != null) parts.add('type: $type');
          if (code != null) parts.add('code: $code');
          return parts.join(', ');
        }
      }

      final directMessage = responseData['message'] as String?;
      if (directMessage != null) return directMessage;
    } else if (responseData is String && responseData.isNotEmpty) {
      return responseData;
    }

    return null;
  }

  void _handleErrorResponse(Response response, String endpoint) {
    final statusCode = response.statusCode;
    final errorData = response.data;

    if (statusCode != null) {
      final errorMessage = _extractErrorMessage(statusCode, errorData) ??
          'OpenAI $endpoint API returned error status: $statusCode';
      final responseMap = errorData is Map<String, dynamic> ? errorData : null;

      throw HttpErrorMapper.mapStatusCode(
        statusCode,
        errorMessage,
        responseMap,
      );
    } else {
      throw ResponseFormatError(
        'OpenAI $endpoint API returned unknown error',
        errorData?.toString() ?? '',
      );
    }
  }
}
