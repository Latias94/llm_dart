/// (Tier 3 / opt-in) Low-level Google HTTP client.
///
/// This library powers the provider implementation but is intentionally not
/// part of the recommended provider entrypoints.
library;

import 'package:dio/dio.dart' hide CancelToken;
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/utils/response_metadata_sanitizer.dart';
import 'package:logging/logging.dart';
import 'config.dart';
import 'dio_strategy.dart';

/// Core Google HTTP client shared across all capability modules
///
/// This class provides the foundational HTTP functionality that all
/// Google capability implementations can use. It handles:
/// - Authentication via API key query parameter
/// - Request/response processing
/// - Error handling
/// - JSON array stream parsing (Google's streaming format)
/// - Provider-specific configurations
class GoogleClient {
  final GoogleConfig config;
  final Logger logger = Logger('GoogleClient');
  late final Dio dio;
  late final bool _useApiKeyHeaderAuth;

  GoogleClient(this.config) {
    // Use unified Dio client factory with Google-specific strategy
    dio = DioClientFactory.create(
      strategy: GoogleDioStrategy(),
      config: config,
    );

    // Vertex "express mode" (aiplatform.googleapis.com) uses API key auth via
    // headers (Vercel AI SDK parity). Gemini API uses query parameter auth.
    final baseUri = Uri.tryParse(config.baseUrl);
    _useApiKeyHeaderAuth =
        baseUri != null && baseUri.host.endsWith('aiplatform.googleapis.com');
    if (_useApiKeyHeaderAuth) {
      dio.options.headers['x-goog-api-key'] = config.apiKey;
    }
  }

  /// Whether this client authenticates via the `x-goog-api-key` header.
  ///
  /// When false, requests authenticate using the `?key=` query parameter.
  bool get usesApiKeyHeaderAuth => _useApiKeyHeaderAuth;

  /// Get endpoint with API key authentication
  String _getEndpointWithAuth(String endpoint) {
    if (_useApiKeyHeaderAuth) {
      return endpoint;
    }
    // Google uses query parameter authentication
    final separator = endpoint.contains('?') ? '&' : '?';
    return '$endpoint${separator}key=${config.apiKey}';
  }

  /// Make a POST request and return response
  Future<Response> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final fullEndpoint = _getEndpointWithAuth(endpoint);
      return await withDioCancelToken(
        cancelToken,
        (dioToken) => dio.post(
          fullEndpoint,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: dioToken,
        ),
      );
    } on DioException catch (e) {
      logger.severe('HTTP request failed: ${e.message}');
      rethrow;
    }
  }

  /// Make a POST request and return JSON response
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async {
    return HttpResponseHandler.postJson(
      dio,
      _getEndpointWithAuth(endpoint),
      data,
      providerName: 'Google',
      logger: logger,
      cancelToken: cancelToken,
    );
  }

  /// Make a POST request and return JSON response + response headers (best-effort).
  Future<({Map<String, dynamic> json, Map<String, String> headers})>
      postJsonWithHeaders(
    String endpoint,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) async {
    return HttpResponseHandler.postJsonWithHeaders(
      dio,
      _getEndpointWithAuth(endpoint),
      data,
      providerName: 'Google',
      logger: logger,
      options: headers == null ? null : Options(headers: headers),
      cancelToken: cancelToken,
    );
  }

  /// Make a GET request and return JSON response.
  Future<Map<String, dynamic>> getJson(
    String endpoint, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) {
    return HttpResponseHandler.getJson(
      dio,
      _getEndpointWithAuth(endpoint),
      providerName: 'Google',
      logger: logger,
      options: headers == null ? null : Options(headers: headers),
      cancelToken: cancelToken,
    );
  }

  /// Make a GET request and return JSON response + response headers (best-effort).
  Future<({Map<String, dynamic> json, Map<String, String> headers})>
      getJsonWithHeaders(
    String endpoint, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) {
    return HttpResponseHandler.getJsonWithHeaders(
      dio,
      _getEndpointWithAuth(endpoint),
      providerName: 'Google',
      logger: logger,
      options: headers == null ? null : Options(headers: headers),
      cancelToken: cancelToken,
    );
  }

  /// Make a POST request and return stream response
  Stream<Response> postStream(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async* {
    try {
      final fullEndpoint = _getEndpointWithAuth(endpoint);
      final response = await dio.post(
        fullEndpoint,
        data: data,
        queryParameters: queryParameters,
        options: options?.copyWith(responseType: ResponseType.stream) ??
            Options(responseType: ResponseType.stream),
      );
      yield response;
    } on DioException catch (e) {
      logger.severe('Stream request failed: ${e.message}');
      rethrow;
    }
  }

  /// Make a POST request and return raw stream for JSON array streaming
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async* {
    final streamed = await postStreamRawWithHeaders(
      endpoint,
      data,
      cancelToken: cancelToken,
    );
    yield* streamed.stream;
  }

  /// Make a POST request and return raw stream + response headers (best-effort).
  Future<({Stream<String> stream, Map<String, String> headers})>
      postStreamRawWithHeaders(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async {
    try {
      final fullEndpoint = _getEndpointWithAuth(endpoint);
      final response = await withDioCancelToken(
        cancelToken,
        (dioToken) => dio.post(
          fullEndpoint,
          data: data,
          cancelToken: dioToken,
          options: Options(
            responseType: ResponseType.stream,
            headers: {'Accept': 'text/event-stream'},
          ),
        ),
      );

      final headerMap = <String, String>{};
      response.headers.forEach((name, values) {
        if (values.isEmpty) return;
        headerMap[name] = values.join(',');
      });
      final sanitizedHeaders = sanitizeResponseHeadersForMetadata(headerMap);

      // Handle ResponseBody properly for streaming
      final responseBody = response.data;
      Stream<List<int>> stream;

      if (responseBody is Stream<List<int>>) {
        stream = responseBody;
      } else if (responseBody is ResponseBody) {
        stream = responseBody.stream;
      } else {
        throw Exception(
            'Unexpected response type: ${responseBody.runtimeType}');
      }

      Stream<String> decodedStream() async* {
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
      }

      return (
        stream: decodedStream(),
        headers: sanitizedHeaders.isEmpty
            ? const <String, String>{}
            : Map<String, String>.unmodifiable(sanitizedHeaders),
      );
    } on DioException catch (e) {
      logger.severe('Stream request failed: ${e.message}');
      rethrow;
    }
  }
}
