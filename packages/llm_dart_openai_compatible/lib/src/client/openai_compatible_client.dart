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

  /// Build API messages from the structured ChatPromptMessage model.
  ///
  /// This mirrors the OpenAI client's behavior but keeps only the
  /// subset of features that are meaningful for generic
  /// OpenAI-compatible providers.
  List<Map<String, dynamic>> buildApiMessagesFromPrompt(
    List<ChatPromptMessage> promptMessages,
  ) {
    final apiMessages = <Map<String, dynamic>>[];

    for (final message in promptMessages) {
      final hasToolResult =
          message.parts.any((part) => part is ToolResultContentPart);

      if (hasToolResult) {
        _appendToolResultMessagesFromPrompt(message, apiMessages);
      } else {
        apiMessages.add(_convertPromptMessage(message));
      }
    }

    return apiMessages;
  }

  Map<String, dynamic> _convertPromptMessage(ChatPromptMessage message) {
    final role = switch (message.role) {
      ChatRole.system => 'system',
      ChatRole.user => 'user',
      ChatRole.assistant => 'assistant',
    };

    // System: merge text + reasoning into one content string.
    if (role == 'system') {
      final buffer = StringBuffer();
      for (final part in message.parts) {
        if (part is TextContentPart) {
          if (buffer.isNotEmpty) buffer.writeln();
          buffer.write(part.text);
        } else if (part is ReasoningContentPart) {
          if (buffer.isNotEmpty) buffer.writeln();
          buffer.write(part.text);
        }
      }

      return {
        'role': 'system',
        'content': buffer.isNotEmpty ? buffer.toString() : '',
      };
    }

    // Assistant with optional tool calls
    if (role == 'assistant') {
      final buffer = StringBuffer();
      final toolCalls = <Map<String, dynamic>>[];

      for (final part in message.parts) {
        if (part is TextContentPart) {
          buffer.write(part.text);
        } else if (part is ReasoningContentPart) {
          buffer.write(part.text);
        } else if (part is ToolCallContentPart) {
          toolCalls.add({
            'id': part.toolCallId ?? 'call_${toolCalls.length}',
            'type': 'function',
            'function': {
              'name': part.toolName,
              'arguments': part.argumentsJson,
            },
          });
        }
      }

      final result = <String, dynamic>{
        'role': 'assistant',
        'content': buffer.toString(),
      };

      if (toolCalls.isNotEmpty) {
        result['tool_calls'] = toolCalls;
      }

      return result;
    }

    // User
    if (role == 'user') {
      final pureParts = message.parts
          .where((part) => part is! ToolResultContentPart)
          .toList();
      final textParts =
          pureParts.whereType<TextContentPart>().toList(growable: false);
      final nonTextParts =
          pureParts.where((p) => p is! TextContentPart).toList();

      // Pure text
      if (nonTextParts.isEmpty && textParts.length == 1) {
        return {
          'role': 'user',
          'content': textParts.first.text,
        };
      }

      // Multi-part / multi-modal
      final contentArray = <Map<String, dynamic>>[];

      for (final part in pureParts) {
        if (part is TextContentPart) {
          if (part.text.isEmpty) continue;
          contentArray.add({'type': 'text', 'text': part.text});
        } else if (part is ReasoningContentPart) {
          if (part.text.isEmpty) continue;
          contentArray.add({'type': 'text', 'text': part.text});
        } else if (part is UrlFileContentPart) {
          contentArray.add({
            'type': 'image_url',
            'image_url': {'url': part.url},
          });
        } else if (part is FileContentPart) {
          _appendFilePartForPrompt(part, contentArray);
        }
      }

      return {
        'role': 'user',
        'content': contentArray,
      };
    }

    // Fallback
    return {
      'role': role,
      'content': '',
    };
  }

  void _appendFilePartForPrompt(
    FileContentPart part,
    List<Map<String, dynamic>> contentArray,
  ) {
    final mime = part.mime;
    final data = part.data;
    final base64Data = base64Encode(data);

    if (mime.mimeType.startsWith('image/')) {
      final imageDataUrl = 'data:${mime.mimeType};base64,$base64Data';
      contentArray.add({
        'type': 'image_url',
        'image_url': {'url': imageDataUrl},
      });
    } else {
      contentArray.add({
        'type': 'file',
        'file': {'file_data': base64Data},
      });
    }
  }

  void _appendToolResultMessagesFromPrompt(
    ChatPromptMessage message,
    List<Map<String, dynamic>> apiMessages,
  ) {
    final fallbackText = message.parts
        .whereType<TextContentPart>()
        .map((p) => p.text)
        .join('\n');

    for (final part in message.parts) {
      if (part is! ToolResultContentPart) continue;

      String content;
      final payload = part.payload;
      if (payload is ToolResultTextPayload) {
        content = payload.value.isNotEmpty ? payload.value : fallbackText;
      } else if (payload is ToolResultJsonPayload) {
        content = jsonEncode(payload.value);
      } else if (payload is ToolResultErrorPayload) {
        content = payload.message;
      } else if (payload is ToolResultContentPayload) {
        final texts = <String>[];
        for (final nested in payload.parts) {
          if (nested is TextContentPart) {
            texts.add(nested.text);
          }
        }
        content = texts.join('\n');
      } else {
        content = fallbackText.isNotEmpty ? fallbackText : 'Tool result';
      }

      apiMessages.add({
        'role': 'tool',
        'tool_call_id': part.toolCallId,
        'content': content,
      });
    }
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
