import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../config/anthropic_config.dart';
import '../http/anthropic_dio_strategy.dart';
import '../utils/anthropic_utf8_stream_decoder.dart';

/// Core Anthropic HTTP client shared across all capability modules.
class AnthropicClient {
  final AnthropicConfig config;
  final Logger logger = Logger('AnthropicClient');
  late final Dio dio;

  AnthropicClient(this.config) {
    dio = DioClientFactory.create(
      strategy: AnthropicDioStrategy(),
      config: config,
    );
  }

  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async {
    return HttpResponseHandler.postJson(
      dio,
      endpoint,
      data,
      providerName: 'Anthropic',
      logger: logger,
      cancelToken: cancelToken,
    );
  }

  Future<Map<String, dynamic>> getJson(
    String endpoint, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dio.get(
        endpoint,
        cancelToken: cancelToken,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      logger.severe('HTTP GET request failed: ${e.message}');
      throw DioErrorHandler.handleDioError(e, 'Anthropic');
    }
  }

  Future<Map<String, dynamic>> postForm(
    String endpoint,
    FormData formData, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dio.post(
        endpoint,
        data: formData,
        cancelToken: cancelToken,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      logger.severe('HTTP form request failed: ${e.message}');
      throw DioErrorHandler.handleDioError(e, 'Anthropic');
    }
  }

  Future<void> delete(
    String endpoint, {
    CancelToken? cancelToken,
  }) async {
    try {
      await dio.delete(
        endpoint,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      logger.severe('HTTP DELETE request failed: ${e.message}');
      throw DioErrorHandler.handleDioError(e, 'Anthropic');
    }
  }

  Future<List<int>> getRaw(
    String endpoint, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dio.get(
        endpoint,
        options: Options(responseType: ResponseType.bytes),
        cancelToken: cancelToken,
      );
      return response.data as List<int>;
    } on DioException catch (e) {
      logger.severe('HTTP raw request failed: ${e.message}');
      throw DioErrorHandler.handleDioError(e, 'Anthropic');
    }
  }

  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async* {
    try {
      final response = await dio.post(
        endpoint,
        data: data,
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'},
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

      final decoder = AnthropicUtf8StreamDecoder();

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
      logger.severe('Stream request failed: ${e.message}');
      throw DioErrorHandler.handleDioError(e, 'Anthropic');
    }
  }
}
