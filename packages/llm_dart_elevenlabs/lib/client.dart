import 'dart:typed_data';

import 'package:dio/dio.dart' hide CancelToken;
import 'package:logging/logging.dart';
import 'package:llm_dart_core/core/cancellation.dart';
import 'package:llm_dart_core/core/llm_error.dart';
import 'package:llm_dart_provider_utils/utils/dio_cancellation.dart';
import 'package:llm_dart_provider_utils/utils/dio_client_factory.dart';
import 'package:llm_dart_provider_utils/utils/dio_error_handler.dart';

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

      return Uint8List.fromList(response.data as List<int>);
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
        return responseData;
      } else if (responseData is String) {
        return {'text': responseData};
      } else {
        return responseData as Map<String, dynamic>;
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
