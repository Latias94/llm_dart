/// (Tier 3 / opt-in) Low-level ElevenLabs HTTP client.
///
/// This library powers the provider implementation but is intentionally not
/// part of the recommended provider entrypoints.
library;

import 'dart:typed_data';

import 'package:dio/dio.dart' hide CancelToken;
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:llm_dart_provider_utils/utils/response_metadata_sanitizer.dart';
import 'package:logging/logging.dart';

import 'config.dart';
import 'dio_strategy.dart';

/// ElevenLabs HTTP client implementation.
class ElevenLabsClient {
  static final Logger _logger = Logger('ElevenLabsClient');

  final ElevenLabsConfig config;
  late final Dio _dio;

  ElevenLabsClient(this.config) {
    _dio = DioClientFactory.create(
      strategy: ElevenLabsDioStrategy(),
      config: config,
    );
  }

  Logger get logger => _logger;

  Map<String, String> _sanitizeResponseHeaders(Headers headers) {
    final headerMap = <String, String>{};
    headers.forEach((name, values) {
      if (values.isEmpty) return;
      headerMap[name] = values.join(',');
    });

    final sanitized = sanitizeResponseHeadersForMetadata(headerMap);
    return sanitized.isEmpty
        ? const <String, String>{}
        : Map<String, String>.unmodifiable(sanitized);
  }

  Future<Map<String, dynamic>> getJson(
    String endpoint, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await withDioCancelToken(
        cancelToken,
        (dioToken) => _dio.get(endpoint, cancelToken: dioToken),
      );

      if (response.statusCode != 200) {
        throw ProviderError(
          'ElevenLabs API returned status ${response.statusCode}: ${response.data}',
        );
      }

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw await DioErrorHandler.handleDioError(e, 'ElevenLabs');
    }
  }

  Future<List<dynamic>> getList(
    String endpoint, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await withDioCancelToken(
        cancelToken,
        (dioToken) => _dio.get(endpoint, cancelToken: dioToken),
      );

      if (response.statusCode != 200) {
        throw ProviderError(
          'ElevenLabs API returned status ${response.statusCode}: ${response.data}',
        );
      }

      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw await DioErrorHandler.handleDioError(e, 'ElevenLabs');
    }
  }

  Future<Uint8List> postBinary(
    String endpoint,
    Map<String, dynamic> data, {
    Map<String, String>? queryParams,
    CancelToken? cancelToken,
  }) async {
    final response = await postBinaryWithResponseHeaders(
      endpoint,
      data,
      queryParams: queryParams,
      cancelToken: cancelToken,
    );
    return response.data;
  }

  Future<({Uint8List data, Map<String, String> headers})>
      postBinaryWithResponseHeaders(
    String endpoint,
    Map<String, dynamic> data, {
    Map<String, String>? queryParams,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await withDioCancelToken(
        cancelToken,
        (dioToken) => _dio.post(
          endpoint,
          data: data,
          queryParameters: queryParams,
          cancelToken: dioToken,
          options: Options(responseType: ResponseType.bytes),
        ),
      );

      if (response.statusCode != 200) {
        throw ProviderError(
          'ElevenLabs API returned status ${response.statusCode}',
        );
      }

      return (
        data: Uint8List.fromList(response.data as List<int>),
        headers: _sanitizeResponseHeaders(response.headers),
      );
    } on DioException catch (e) {
      throw await DioErrorHandler.handleDioError(e, 'ElevenLabs');
    }
  }

  Future<Response<ResponseBody>> postStream(
    String endpoint,
    Map<String, dynamic> data, {
    Map<String, String>? queryParams,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await withDioCancelToken(
        cancelToken,
        (dioToken) => _dio.post<ResponseBody>(
          endpoint,
          data: data,
          queryParameters: queryParams,
          cancelToken: dioToken,
          options: Options(responseType: ResponseType.stream),
        ),
      );

      if (response.statusCode != 200) {
        throw ProviderError(
          'ElevenLabs API returned status ${response.statusCode}',
        );
      }

      return response;
    } on DioException catch (e) {
      throw await DioErrorHandler.handleDioError(e, 'ElevenLabs');
    }
  }

  Future<Map<String, dynamic>> postFormData(
    String endpoint,
    FormData formData, {
    Map<String, String>? queryParams,
    CancelToken? cancelToken,
  }) async {
    final response = await postFormDataWithResponseHeaders(
      endpoint,
      formData,
      queryParams: queryParams,
      cancelToken: cancelToken,
    );
    return response.json;
  }

  Future<({Map<String, dynamic> json, Map<String, String> headers})>
      postFormDataWithResponseHeaders(
    String endpoint,
    FormData formData, {
    Map<String, String>? queryParams,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await withDioCancelToken(
        cancelToken,
        (dioToken) => _dio.post(
          endpoint,
          data: formData,
          cancelToken: dioToken,
          queryParameters: queryParams,
          options: Options(headers: {'xi-api-key': config.apiKey}),
        ),
      );

      if (response.statusCode != 200) {
        throw ProviderError(
          'ElevenLabs STT API returned status ${response.statusCode}',
        );
      }

      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        return (
          json: responseData,
          headers: _sanitizeResponseHeaders(response.headers),
        );
      } else if (responseData is String) {
        return (
          json: {'text': responseData},
          headers: _sanitizeResponseHeaders(response.headers),
        );
      } else {
        return (
          json: responseData as Map<String, dynamic>,
          headers: _sanitizeResponseHeaders(response.headers),
        );
      }
    } on DioException catch (e) {
      throw await DioErrorHandler.handleDioError(e, 'ElevenLabs');
    } catch (e) {
      if (e is LLMError) rethrow;
      throw GenericError('Unexpected error: $e');
    }
  }

  Future<Uint8List> postBinaryFormData(
    String endpoint,
    FormData formData, {
    Map<String, String>? queryParams,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await withDioCancelToken(
        cancelToken,
        (dioToken) => _dio.post(
          endpoint,
          data: formData,
          cancelToken: dioToken,
          queryParameters: queryParams,
          options: Options(responseType: ResponseType.bytes),
        ),
      );

      if (response.statusCode != 200) {
        throw ProviderError(
          'ElevenLabs API returned status ${response.statusCode}',
        );
      }

      return Uint8List.fromList(response.data as List<int>);
    } on DioException catch (e) {
      throw await DioErrorHandler.handleDioError(e, 'ElevenLabs');
    } catch (e) {
      if (e is LLMError) rethrow;
      throw GenericError('Unexpected error: $e');
    }
  }

  Future<Response<ResponseBody>> postStreamFormData(
    String endpoint,
    FormData formData, {
    Map<String, String>? queryParams,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await withDioCancelToken(
        cancelToken,
        (dioToken) => _dio.post<ResponseBody>(
          endpoint,
          data: formData,
          cancelToken: dioToken,
          queryParameters: queryParams,
          options: Options(responseType: ResponseType.stream),
        ),
      );

      if (response.statusCode != 200) {
        throw ProviderError(
          'ElevenLabs API returned status ${response.statusCode}',
        );
      }

      return response;
    } on DioException catch (e) {
      throw await DioErrorHandler.handleDioError(e, 'ElevenLabs');
    } catch (e) {
      if (e is LLMError) rethrow;
      throw GenericError('Unexpected error: $e');
    }
  }
}
