import 'dart:convert';
import 'dart:typed_data';

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

  Map<String, dynamic>? _getDefaultQueryParameters() {
    final original = config.originalConfig;
    if (original == null) return null;

    final effectiveProviderId = providerId;
    final fallbackProviderId =
        effectiveProviderId == 'google-openai' ? 'google' : null;
    final rawGlobal = readProviderOptionMap(
          original.providerOptions,
          'openai-compatible',
          'queryParams',
        ) ??
        readProviderOptionMap(
          original.providerOptions,
          'openai-compatible',
          'queryParameters',
        );
    final rawProvider = readProviderOptionMap(
          original.providerOptions,
          effectiveProviderId,
          'queryParams',
          fallbackProviderId: fallbackProviderId,
        ) ??
        readProviderOptionMap(
          original.providerOptions,
          effectiveProviderId,
          'queryParameters',
          fallbackProviderId: fallbackProviderId,
        );

    final raw = <String, dynamic>{
      ...?rawGlobal,
      ...?rawProvider,
    };

    if (raw.isEmpty) return null;

    final result = <String, dynamic>{};
    for (final entry in raw.entries) {
      if (entry.key.trim().isEmpty) continue;
      final value = entry.value;
      if (value == null) continue;
      result[entry.key] = value.toString();
    }
    return result.isEmpty ? null : result;
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

  String _resolveEndpoint(String endpoint) {
    final rawPrefix = config.endpointPrefix?.trim();
    if (rawPrefix == null || rawPrefix.isEmpty) return endpoint;

    final parts = endpoint.split('?');
    final rawPath = parts.isNotEmpty ? parts.first : endpoint;
    final rawQuery = parts.length > 1 ? parts.sublist(1).join('?') : null;

    final prefix =
        rawPrefix.replaceAll(RegExp(r'^/+'), '').replaceAll(RegExp(r'/+$'), '');
    final path = rawPath.replaceAll(RegExp(r'^/+'), '');

    final combined = prefix.isEmpty ? path : '$prefix/$path';
    if (rawQuery == null || rawQuery.isEmpty) return combined;
    return '$combined?$rawQuery';
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
        // Clear buffer and stop processing this chunk.
        // Note: a single network chunk can contain multiple SSE events; do not
        // discard already-parsed JSON objects that appeared before [DONE].
        _sseParser.reset();
        break;
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

  String? _audioFormatForMime(String mimeType) {
    switch (mimeType.toLowerCase()) {
      case 'audio/wav':
        return 'wav';
      case 'audio/mp3':
      case 'audio/mpeg':
        return 'mp3';
      default:
        return null;
    }
  }

  Map<String, dynamic> _toolCallToWireJson(ToolCall toolCall) {
    final effectiveProviderId = providerId;
    final thoughtSignature =
        toolCall.providerOptions[effectiveProviderId]?['thoughtSignature'];

    final wire = <String, dynamic>{
      'id': toolCall.id,
      'type': toolCall.callType,
      'function': {
        'name': toolCall.function.name,
        'arguments': toolCall.function.arguments,
      },
    };

    if (thoughtSignature is String && thoughtSignature.trim().isNotEmpty) {
      wire['extra_content'] = {
        'google': {
          'thought_signature': thoughtSignature.trim(),
        },
      };
    }

    return wire;
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

      case FileMessage(mime: final mime, data: final data):
        final mimeType = mime.mimeType;

        // Build content array with optional caption + part.
        final contentArray = <Map<String, dynamic>>[];

        if (message.content.isNotEmpty) {
          contentArray.add({
            'type': 'text',
            'text': message.content,
          });
        }

        if (mimeType.toLowerCase() == 'application/pdf') {
          final base64Data = base64Encode(data);
          contentArray.add({
            'type': 'file',
            'file': {
              'filename': 'document.pdf',
              'file_data': 'data:application/pdf;base64,$base64Data',
            },
          });
          result['content'] = contentArray;
          break;
        }

        if (mimeType.toLowerCase().startsWith('audio/')) {
          final format = _audioFormatForMime(mimeType);
          if (format == null) {
            throw InvalidRequestError(
              'Unsupported audio media type for OpenAI-compatible provider: $mimeType',
            );
          }
          contentArray.add({
            'type': 'input_audio',
            'input_audio': {
              'data': base64Encode(data),
              'format': format,
            },
          });
          result['content'] = contentArray;
          break;
        }

        if (mimeType.toLowerCase().startsWith('text/')) {
          final decoded =
              utf8.decode(Uint8List.fromList(data), allowMalformed: true);
          // Prefer emitting plain string content when possible.
          final merged = [
            if (message.content.isNotEmpty) message.content,
            if (decoded.trim().isNotEmpty) decoded,
          ].join('\n\n');
          result['content'] = merged;
          break;
        }

        throw InvalidRequestError(
          'Unsupported file media type for OpenAI-compatible provider: $mimeType',
        );

      case ToolUseMessage(toolCalls: final toolCalls):
        result['tool_calls'] =
            toolCalls.map((tc) => _toolCallToWireJson(tc)).toList();
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

  /// Build OpenAI-compatible API messages from Prompt IR.
  ///
  /// This preserves multi-part message structure (text + image/file parts in a
  /// single message) instead of relying on `Prompt.toChatMessages()` which
  /// emits one ChatMessage per part.
  List<Map<String, dynamic>> buildApiMessagesFromPrompt(Prompt prompt) {
    final apiMessages = <Map<String, dynamic>>[];

    String? currentRole;
    String? currentName;
    final currentContentParts = <Map<String, dynamic>>[];
    final currentToolCalls = <ToolCall>[];

    void flush() {
      if (currentRole == null) return;
      if (currentContentParts.isEmpty && currentToolCalls.isEmpty) {
        currentRole = null;
        currentName = null;
        return;
      }

      final msg = <String, dynamic>{'role': currentRole};
      if (currentName != null && currentName!.trim().isNotEmpty) {
        msg['name'] = currentName;
      }

      if (currentContentParts.isNotEmpty) {
        if (currentContentParts.length == 1 &&
            currentContentParts.first['type'] == 'text' &&
            currentToolCalls.isEmpty) {
          msg['content'] = currentContentParts.first['text'] ?? '';
        } else {
          msg['content'] = List<Map<String, dynamic>>.from(currentContentParts);
        }
      }

      if (currentToolCalls.isNotEmpty) {
        msg['tool_calls'] =
            currentToolCalls.map((t) => _toolCallToWireJson(t)).toList();
      }

      apiMessages.add(msg);

      currentRole = null;
      currentName = null;
      currentContentParts.clear();
      currentToolCalls.clear();
    }

    List<Map<String, dynamic>> toContentParts(PromptPart part) {
      switch (part) {
        case TextPart(:final text):
          if (text.isEmpty) return const [];
          return [
            {
              'type': 'text',
              'text': text,
            }
          ];

        case ImagePart(:final mime, :final data, :final text):
          final base64Data = base64Encode(data);
          final imageDataUrl = 'data:${mime.mimeType};base64,$base64Data';

          final parts = <Map<String, dynamic>>[];
          if (text != null && text.trim().isNotEmpty) {
            parts.add({'type': 'text', 'text': text});
          }
          parts.add({
            'type': 'image_url',
            'image_url': {'url': imageDataUrl},
          });
          return parts;

        case ImageUrlPart(:final url, :final text):
          final parts = <Map<String, dynamic>>[];
          if (text != null && text.trim().isNotEmpty) {
            parts.add({'type': 'text', 'text': text});
          }
          parts.add({
            'type': 'image_url',
            'image_url': {'url': url},
          });
          return parts;

        case FilePart(:final mime, :final data, :final text):
          final parts = <Map<String, dynamic>>[];
          if (text != null && text.trim().isNotEmpty) {
            parts.add({'type': 'text', 'text': text});
          }

          final mimeType = mime.mimeType;

          if (mimeType.toLowerCase() == 'application/pdf') {
            parts.add({
              'type': 'file',
              'file': {
                'filename': 'document.pdf',
                'file_data':
                    'data:application/pdf;base64,${base64Encode(data)}',
              },
            });
            return parts;
          }

          if (mimeType.toLowerCase().startsWith('audio/')) {
            final format = _audioFormatForMime(mimeType);
            if (format == null) {
              throw InvalidRequestError(
                'Unsupported audio media type for OpenAI-compatible provider: $mimeType',
              );
            }
            parts.add({
              'type': 'input_audio',
              'input_audio': {
                'data': base64Encode(data),
                'format': format,
              },
            });
            return parts;
          }

          if (mimeType.toLowerCase().startsWith('text/')) {
            final decoded =
                utf8.decode(Uint8List.fromList(data), allowMalformed: true);
            if (decoded.trim().isNotEmpty) {
              parts.add({'type': 'text', 'text': decoded});
            }
            return parts;
          }

          throw InvalidRequestError(
            'Unsupported file media type for OpenAI-compatible provider: $mimeType',
          );

        case FileUrlPart(:final mime, :final url, :final text):
          final parts = <Map<String, dynamic>>[];
          if (text != null && text.trim().isNotEmpty) {
            parts.add({'type': 'text', 'text': text});
          }

          final mimeType = mime.mimeType.toLowerCase();
          final trimmed = url.trim();

          if (mimeType.startsWith('image/')) {
            parts.add({
              'type': 'image_url',
              'image_url': {'url': trimmed},
            });
            return parts;
          }

          throw InvalidRequestError(
            'FileUrlPart ($mimeType) is not supported by the Chat Completions API. '
            'Use the Responses API (useResponsesAPI=true) or send file data inline.',
          );

        case FileIdPart(:final mime, :final id):
          throw InvalidRequestError(
            'FileIdPart (${mime.mimeType}) is not supported by the Chat '
            'Completions API. Use the Responses API (useResponsesAPI=true) '
            'or send file data inline. Got id: "$id"',
          );

        case ToolCallPart() || ToolResultPart():
          return const [];
      }
    }

    for (final message in prompt.messages) {
      if (message.role == ChatRole.system) {
        flush();

        final texts = <String>[];
        for (final part in message.parts) {
          if (part case TextPart(:final text)) {
            if (text.trim().isNotEmpty) texts.add(text);
            continue;
          }
          throw const InvalidRequestError(
            'System messages must be plain text for OpenAI-compatible providers.',
          );
        }

        apiMessages.add({
          'role': 'system',
          if (message.name != null && message.name!.trim().isNotEmpty)
            'name': message.name,
          'content': texts.join('\n\n'),
        });
        continue;
      }

      for (final part in message.parts) {
        ChatRole effectiveRole;
        if (part case ToolCallPart(:final overrideRole)) {
          effectiveRole = overrideRole ?? message.role;
        } else if (part case ToolResultPart(:final overrideRole)) {
          effectiveRole = overrideRole ?? message.role;
        } else {
          effectiveRole = message.role;
        }

        if (part case ToolCallPart(:final toolCall)) {
          if (effectiveRole != ChatRole.assistant) {
            throw const InvalidRequestError(
              'ToolCallPart must be emitted from an assistant message.',
            );
          }

          if (currentRole != null && currentRole != 'assistant') {
            flush();
          }
          currentRole ??= 'assistant';
          currentName ??= message.name;
          currentToolCalls.add(toolCall);
          continue;
        }

        if (part case ToolResultPart(:final toolResult)) {
          if (effectiveRole != ChatRole.user) {
            throw const InvalidRequestError(
              'ToolResultPart must be emitted from a user message.',
            );
          }

          flush();
          apiMessages.add({
            'role': 'tool',
            'tool_call_id': toolResult.id,
            'content': toolResult.function.arguments.isNotEmpty
                ? toolResult.function.arguments
                : 'Tool result',
          });
          continue;
        }

        final targetRole =
            effectiveRole == ChatRole.user ? 'user' : 'assistant';
        if (currentRole != null && currentRole != targetRole) {
          flush();
        }
        currentRole ??= targetRole;
        currentName ??= message.name;

        currentContentParts.addAll(toContentParts(part));
      }

      flush();
    }

    return apiMessages;
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
    try {
      final resolvedEndpoint = _resolveEndpoint(endpoint);

      // Optimized logging with condition check
      if (logger.isLoggable(Level.FINE)) {
        logger.fine('${config.providerName} request: POST /$resolvedEndpoint');
        logger.fine(
            '${config.providerName} request headers: ${dio.options.headers}');
      }

      final response = await withDioCancelToken(
        cancelToken,
        (dioToken) => dio.post(
          resolvedEndpoint,
          data: body,
          queryParameters: _getDefaultQueryParameters(),
          cancelToken: dioToken,
        ),
      );

      if (logger.isLoggable(Level.FINE)) {
        logger
            .fine('${config.providerName} HTTP status: ${response.statusCode}');
      }

      if (response.statusCode != 200) {
        _handleErrorResponse(response, resolvedEndpoint);
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
    try {
      final resolvedEndpoint = _resolveEndpoint(endpoint);

      if (logger.isLoggable(Level.FINE)) {
        logger.fine('${config.providerName} request: GET /$resolvedEndpoint');
        logger.fine(
            '${config.providerName} request headers: ${dio.options.headers}');
      }

      final mergedQueryParameters = <String, dynamic>{
        ...?_getDefaultQueryParameters(),
        ...?queryParameters,
      };

      final response = await withDioCancelToken(
        cancelToken,
        (dioToken) => dio.get(
          resolvedEndpoint,
          queryParameters:
              mergedQueryParameters.isEmpty ? null : mergedQueryParameters,
          cancelToken: dioToken,
        ),
      );

      if (logger.isLoggable(Level.FINE)) {
        logger
            .fine('${config.providerName} HTTP status: ${response.statusCode}');
      }

      if (response.statusCode != 200) {
        _handleErrorResponse(response, resolvedEndpoint);
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
    try {
      final resolvedEndpoint = _resolveEndpoint(endpoint);

      if (logger.isLoggable(Level.FINE)) {
        logger.fine(
            '${config.providerName} request: POST /$resolvedEndpoint (form)');
        logger.fine(
            '${config.providerName} request headers: ${dio.options.headers}');
      }

      final response = await withDioCancelToken(
        cancelToken,
        (dioToken) => dio.post(
          resolvedEndpoint,
          data: formData,
          queryParameters: _getDefaultQueryParameters(),
          cancelToken: dioToken,
        ),
      );

      if (logger.isLoggable(Level.FINE)) {
        logger
            .fine('${config.providerName} HTTP status: ${response.statusCode}');
      }

      if (response.statusCode != 200) {
        _handleErrorResponse(response, resolvedEndpoint);
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
    try {
      final resolvedEndpoint = _resolveEndpoint(endpoint);

      final response = await withDioCancelToken(
        cancelToken,
        (dioToken) => dio.post(
          resolvedEndpoint,
          data: body,
          queryParameters: _getDefaultQueryParameters(),
          cancelToken: dioToken,
          options: Options(responseType: ResponseType.bytes),
        ),
      );

      if (response.statusCode != 200) {
        _handleErrorResponse(response, resolvedEndpoint);
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
    try {
      final resolvedEndpoint = _resolveEndpoint(endpoint);

      if (logger.isLoggable(Level.FINE)) {
        logger.fine('${config.providerName} request: GET /$resolvedEndpoint');
        logger.fine(
            '${config.providerName} request headers: ${dio.options.headers}');
      }

      final response = await withDioCancelToken(
        cancelToken,
        (dioToken) => dio.get(
          resolvedEndpoint,
          queryParameters: _getDefaultQueryParameters(),
          cancelToken: dioToken,
        ),
      );

      if (logger.isLoggable(Level.FINE)) {
        logger
            .fine('${config.providerName} HTTP status: ${response.statusCode}');
      }

      if (response.statusCode != 200) {
        _handleErrorResponse(response, resolvedEndpoint);
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
    try {
      final resolvedEndpoint = _resolveEndpoint(endpoint);

      final response = await withDioCancelToken(
        cancelToken,
        (dioToken) => dio.get(
          resolvedEndpoint,
          queryParameters: _getDefaultQueryParameters(),
          options: Options(responseType: ResponseType.bytes),
          cancelToken: dioToken,
        ),
      );

      if (response.statusCode != 200) {
        _handleErrorResponse(response, resolvedEndpoint);
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
    try {
      final resolvedEndpoint = _resolveEndpoint(endpoint);

      if (logger.isLoggable(Level.FINE)) {
        logger
            .fine('${config.providerName} request: DELETE /$resolvedEndpoint');
        logger.fine(
            '${config.providerName} request headers: ${dio.options.headers}');
      }

      final response = await withDioCancelToken(
        cancelToken,
        (dioToken) => dio.delete(
          resolvedEndpoint,
          queryParameters: _getDefaultQueryParameters(),
          cancelToken: dioToken,
        ),
      );

      if (logger.isLoggable(Level.FINE)) {
        logger
            .fine('${config.providerName} HTTP status: ${response.statusCode}');
      }

      if (response.statusCode != 200) {
        _handleErrorResponse(response, resolvedEndpoint);
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
    // Reset SSE buffer for new stream
    resetSSEBuffer();

    try {
      final resolvedEndpoint = _resolveEndpoint(endpoint);

      if (logger.isLoggable(Level.FINE)) {
        logger.fine(
            '${config.providerName} request: POST /$resolvedEndpoint (stream)');
        logger.fine(
            '${config.providerName} request headers: ${dio.options.headers}');
      }

      final response = await withDioCancelToken(
        cancelToken,
        (dioToken) => dio.post(
          resolvedEndpoint,
          data: body,
          queryParameters: _getDefaultQueryParameters(),
          cancelToken: dioToken,
          options: Options(
            responseType: ResponseType.stream,
            headers: {'Accept': 'text/event-stream'},
          ),
        ),
      );

      if (response.statusCode != 200) {
        _handleErrorResponse(response, resolvedEndpoint);
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
    final errorField = responseData['error'];

    // Some OpenAI-compatible providers return `{ "error": "..." }`.
    if (errorField is String) {
      final trimmed = errorField.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }

    if (errorField is Map<String, dynamic>) {
      final message = errorField['message'] as String?;
      final type = errorField['type'] as String?;
      final code = errorField['code']?.toString();

      if (message != null && message.trim().isNotEmpty) {
        final parts = <String>[message.trim()];
        if (type != null && type.trim().isNotEmpty) {
          parts.add('type: ${type.trim()}');
        }
        if (code != null && code.trim().isNotEmpty) {
          parts.add('code: ${code.trim()}');
        }
        return parts.join(', ');
      }

      // Alternative nested shapes.
      final nestedError = errorField['error'];
      if (nestedError is String && nestedError.trim().isNotEmpty) {
        return nestedError.trim();
      }
      final detail = errorField['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return detail.trim();
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
