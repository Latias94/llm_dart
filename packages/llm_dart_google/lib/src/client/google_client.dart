import 'package:dio/dio.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../config/google_config.dart';
import '../http/google_dio_strategy.dart';
import '../utils/google_utf8_stream_decoder.dart';

/// Core Google HTTP client shared across all capability modules (sub-package).
class GoogleClient {
  final GoogleConfig config;
  final LLMLogger logger;
  late final Dio dio;

  GoogleClient(this.config)
      : logger = config.originalConfig == null
            ? const NoopLLMLogger()
            : resolveLogger(config.originalConfig!) {
    dio = DioClientFactory.create(
      strategy: GoogleDioStrategy(),
      config: config,
    );
  }

  String _getEndpointWithAuth(String endpoint) {
    final separator = endpoint.contains('?') ? '&' : '?';
    return '$endpoint${separator}key=${config.apiKey}';
  }

  Future<Response> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final fullEndpoint = _getEndpointWithAuth(endpoint);
      return await dio.post(
        fullEndpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      logger.severe('HTTP request failed: ${e.message}', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await dio.post(
        _getEndpointWithAuth(endpoint),
        data: data,
        cancelToken: cancelToken,
        options: headers == null
            ? null
            : Options(headers: HttpHeaderUtils.mergeDioHeaders(dio, headers)),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      logger.severe('HTTP request failed: ${e.message}', e);
      rethrow;
    }
  }

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
      logger.severe('Stream request failed: ${e.message}', e);
      rethrow;
    }
  }

  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
    Map<String, String>? headers,
  }) async* {
    try {
      final fullEndpoint = _getEndpointWithAuth(endpoint);
      final effectiveHeaders = HttpHeaderUtils.mergeDioHeaders(dio, headers);
      effectiveHeaders['Accept'] = 'application/json';
      final response = await dio.post(
        fullEndpoint,
        data: data,
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
        throw Exception(
          'Unexpected response type: ${responseBody.runtimeType}',
        );
      }

      final decoder = GoogleUtf8StreamDecoder();

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
      logger.severe('Stream request failed: ${e.message}', e);
      rethrow;
    }
  }
}
