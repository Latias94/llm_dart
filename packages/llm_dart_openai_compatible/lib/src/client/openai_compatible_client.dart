import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../config/openai_compatible_config.dart';
import '../provider_profiles/openai_compatible_provider_profiles.dart';

/// Generic OpenAI-compatible HTTP client shared across all compatible providers.
class OpenAICompatibleClient {
  final OpenAICompatibleConfig config;
  final OpenAICompatibleProviderConfig? _providerProfile;
  late final Dio dio;

  final StringBuffer _sseBuffer = StringBuffer();

  OpenAICompatibleClient(this.config)
      : _providerProfile =
            OpenAICompatibleProviderProfiles.getConfig(config.providerId) {
    dio = DioClientFactory.create(
      strategy: _OpenAICompatibleDioStrategy(),
      config: config,
    );
  }

  /// Parse a Server-Sent Events chunk to a list of JSON objects.
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

        if (data.isEmpty) continue;

        try {
          final json = jsonDecode(data);
          if (json is! Map<String, dynamic>) {
            continue;
          }

          final error = json['error'] as Map<String, dynamic>?;
          if (error != null) {
            final message = error['message']?.toString() ?? 'Unknown error';
            throw ResponseFormatError(
              'SSE stream error: $message',
              data,
            );
          }

          results.add(json);
        } catch (e) {
          if (e is LLMError) rethrow;
        }
      }
    }

    return results;
  }

  void resetSSEBuffer() {
    _sseBuffer.clear();
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
        apiMessages.add(_convertMessage(message));
      }
    }

    return apiMessages;
  }

  Map<String, dynamic> _convertMessage(ChatMessage message) {
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
          contentArray.add({'type': 'text', 'text': message.content});
        }

        contentArray.add({
          'type': 'image_url',
          'image_url': {'url': imageDataUrl},
        });

        result['content'] = contentArray;
        break;
      case ImageUrlMessage(url: final url):
        final contentArray = <Map<String, dynamic>>[];
        if (message.content.isNotEmpty) {
          contentArray.add({'type': 'text', 'text': message.content});
        }
        contentArray.add({
          'type': 'image_url',
          'image_url': {'url': url},
        });
        result['content'] = contentArray;
        break;
      case FileMessage(data: final data):
        final base64Data = base64Encode(data);
        final contentArray = <Map<String, dynamic>>[];
        if (message.content.isNotEmpty) {
          contentArray.add({'type': 'text', 'text': message.content});
        }
        contentArray.add({
          'type': 'file',
          'file': {'file_data': base64Data},
        });
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

  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) async {
    if (config.apiKey.isEmpty) {
      throw const AuthError('Missing API key for OpenAI-compatible provider');
    }

    try {
      return await HttpResponseHandler.postJson(
        dio,
        endpoint,
        body,
        providerName: config.providerId,
        options: Options(headers: _buildTransformedHeaders()),
        cancelToken: cancelToken,
      );
    } on LLMError {
      rethrow;
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
      throw const AuthError('Missing API key for OpenAI-compatible provider');
    }

    resetSSEBuffer();

    try {
      final response = await dio.post(
        endpoint,
        data: body,
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            ..._buildTransformedHeaders(),
            'Accept': 'text/event-stream',
          },
        ),
      );

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
      throw DioErrorHandler.handleDioError(e, config.providerId);
    } catch (e) {
      throw GenericError('Unexpected error: $e');
    }
  }

  /// Build headers for this request, applying provider-specific transformers
  /// when available (e.g. Google Gemini OpenAI-compatible headers).
  Map<String, String> _buildTransformedHeaders() {
    final baseHeaders = <String, String>{};

    dio.options.headers.forEach((key, value) {
      if (value == null) return;
      if (value is String) {
        baseHeaders[key] = value;
      } else {
        baseHeaders[key] = value.toString();
      }
    });

    final providerConfig = _providerProfile;
    final transformer = providerConfig?.headersTransformer;
    final originalConfig = config.originalConfig;

    if (providerConfig == null ||
        transformer == null ||
        originalConfig == null) {
      return baseHeaders;
    }

    try {
      return transformer.transform(
        baseHeaders,
        originalConfig,
        providerConfig,
      );
    } catch (_) {
      // On any error, fall back to the base headers.
      return baseHeaders;
    }
  }
}

/// Minimal Dio strategy for OpenAI-compatible providers.
class _OpenAICompatibleDioStrategy extends BaseProviderDioStrategy {
  @override
  String get providerName => 'OpenAICompatible';

  @override
  Map<String, String> buildHeaders(dynamic config) {
    final c = config as OpenAICompatibleConfig;
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${c.apiKey}',
    };
  }
}
