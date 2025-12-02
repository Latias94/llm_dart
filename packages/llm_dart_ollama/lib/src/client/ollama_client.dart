import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../config/ollama_config.dart';
import '../http/ollama_dio_strategy.dart';

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

  Future<Map<String, dynamic>> deleteJson(
    String endpoint, {
    Map<String, dynamic>? data,
    CancelToken? cancelToken,
  }) async {
    try {
      logger.fine('Ollama request: DELETE $endpoint');
      final response = await dio.delete(
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
      logger.severe('Stream request failed: ${e.message}');
      rethrow;
    }
  }

  /// Show detailed information about a model.
  Future<Map<String, dynamic>> showModel(
    String model, {
    bool verbose = false,
    CancelToken? cancelToken,
  }) {
    final body = <String, dynamic>{
      'model': model,
      if (verbose) 'verbose': true,
    };
    return postJson('/api/show', body, cancelToken: cancelToken);
  }

  /// Copy a model to a new name.
  Future<void> copyModel(
    String source,
    String destination, {
    CancelToken? cancelToken,
  }) async {
    await postJson(
      '/api/copy',
      {
        'source': source,
        'destination': destination,
      },
      cancelToken: cancelToken,
    );
  }

  /// Delete a model and its data.
  Future<void> deleteModel(
    String model, {
    CancelToken? cancelToken,
  }) async {
    await deleteJson(
      '/api/delete',
      data: {'model': model},
      cancelToken: cancelToken,
    );
  }

  /// Pull a model from the Ollama library.
  ///
  /// By default this uses a non-streaming response and returns the final
  /// status object (e.g. `{ "status": "success" }`).
  Future<Map<String, dynamic>> pullModel(
    String model, {
    bool insecure = false,
    CancelToken? cancelToken,
  }) {
    final body = <String, dynamic>{
      'model': model,
      'stream': false,
      if (insecure) 'insecure': true,
    };
    return postJson('/api/pull', body, cancelToken: cancelToken);
  }

  /// Push a model to a remote library.
  ///
  /// By default this uses a non-streaming response and returns the final
  /// status object (e.g. `{ "status": "success" }`).
  Future<Map<String, dynamic>> pushModel(
    String model, {
    bool insecure = false,
    CancelToken? cancelToken,
  }) {
    final body = <String, dynamic>{
      'model': model,
      'stream': false,
      if (insecure) 'insecure': true,
    };
    return postJson('/api/push', body, cancelToken: cancelToken);
  }

  /// List models currently loaded into memory.
  Future<List<Map<String, dynamic>>> listRunningModels({
    CancelToken? cancelToken,
  }) async {
    final json = await getJson('/api/ps', cancelToken: cancelToken);
    final models = json['models'] as List? ?? [];
    return models.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  /// Get the Ollama server version.
  Future<Map<String, dynamic>> version({
    CancelToken? cancelToken,
  }) {
    return getJson('/api/version', cancelToken: cancelToken);
  }
}
