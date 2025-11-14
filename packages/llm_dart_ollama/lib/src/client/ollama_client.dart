import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../config/ollama_config.dart';
import '../http/ollama_dio_strategy.dart';
import '../utils/ollama_utf8_stream_decoder.dart';

/// Core Ollama HTTP client for the sub-package.
class OllamaClient {
  final OllamaConfig config;
  final Logger logger = Logger('OllamaClient');
  late final Dio dio;

  OllamaClient(this.config) {
    dio = DioClientFactory.create(
      strategy: OllamaDioStrategy(),
      config: config,
    );
  }

  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async {
    try {
      logger.fine('Ollama request: POST $endpoint');
      final response = await dio.post(
        endpoint,
        data: data,
        cancelToken: cancelToken,
      );
      logger.fine('Ollama HTTP status: ${response.statusCode}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      logger.severe('HTTP request failed: ${e.message}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getJson(
    String endpoint, {
    CancelToken? cancelToken,
  }) async {
    try {
      logger.fine('Ollama request: GET $endpoint');
      final response = await dio.get(
        endpoint,
        cancelToken: cancelToken,
      );
      logger.fine('Ollama HTTP status: ${response.statusCode}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      logger.severe('HTTP request failed: ${e.message}');
      rethrow;
    }
  }

  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async* {
    try {
      logger.fine('Ollama streaming request payload: ${jsonEncode(data)}');

      final response = await dio.post(
        endpoint,
        data: data,
        cancelToken: cancelToken,
        options: Options(responseType: ResponseType.stream),
      );

      logger.fine('Ollama streaming HTTP status: ${response.statusCode}');

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

      final decoder = OllamaUtf8StreamDecoder();

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
      rethrow;
    }
  }
}
