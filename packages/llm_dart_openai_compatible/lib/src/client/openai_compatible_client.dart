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

  // Shared SSE line buffer used for streaming responses.
  final SSELineBuffer _sseLineBuffer = SSELineBuffer();

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

    final lines = _sseLineBuffer.addChunk(chunk);
    if (lines.isEmpty) return results;

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      if (!trimmedLine.startsWith('data:')) continue;

      final data = trimmedLine.startsWith('data: ')
          ? trimmedLine.substring(6).trim()
          : trimmedLine.substring(5).trim();

      if (data == '[DONE]') {
        _sseLineBuffer.clear();
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
        // For generic OpenAI-compatible providers, silently skip malformed chunks.
      }
    }

    return results;
  }

  void resetSSEBuffer() {
    _sseLineBuffer.clear();
  }

  /// Build API messages from the structured ModelMessage model.
  ///
  /// This mirrors the OpenAI client's behavior but keeps only the
  /// subset of features that are meaningful for generic
  /// OpenAI-compatible providers.
  List<Map<String, dynamic>> buildApiMessagesFromPrompt(
    List<ModelMessage> promptMessages,
  ) {
    return OpenAIMessageMapper.buildApiMessagesFromPrompt(
      promptMessages,
      isResponsesApi: false,
    );
  }

  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
    Map<String, String>? headers,
  }) async {
    if (config.apiKey.isEmpty) {
      throw const AuthError('Missing API key for OpenAI-compatible provider');
    }

    try {
      final effectiveHeaders = headers == null
          ? _buildTransformedHeaders()
          : {..._buildTransformedHeaders(), ...headers};
      return await HttpResponseHandler.postJson(
        dio,
        endpoint,
        body,
        providerName: config.providerId,
        options: Options(headers: effectiveHeaders),
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
    Map<String, String>? headers,
  }) async* {
    if (config.apiKey.isEmpty) {
      throw const AuthError('Missing API key for OpenAI-compatible provider');
    }

    resetSSEBuffer();

    try {
      final baseHeaders = {
        ..._buildTransformedHeaders(),
        'Accept': 'text/event-stream',
      };
      final effectiveHeaders =
          headers == null ? baseHeaders : {...baseHeaders, ...headers};
      final response = await dio.post(
        endpoint,
        data: body,
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          headers: effectiveHeaders,
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
      throw await DioErrorHandler.handleDioError(e, config.providerId);
    } catch (e) {
      throw GenericError('Unexpected error: $e');
    }
  }

  /// Build headers for this request, applying provider-specific transformers
  /// when available (e.g. Google Gemini OpenAI-compatible headers).
  Map<String, String> _buildTransformedHeaders() {
    final baseHeaders = HttpHeaderUtils.mergeDioHeaders(dio);

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
class _OpenAICompatibleDioStrategy
    extends BaseProviderDioStrategy<OpenAICompatibleConfig> {
  @override
  String get providerName => 'OpenAICompatible';

  @override
  Map<String, String> buildHeaders(OpenAICompatibleConfig config) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${config.apiKey}',
    };
  }
}
