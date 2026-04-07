import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart'
    show ProviderDioClientFactory, Utf8StreamDecoder, bindDioCancellation;
import 'package:logging/logging.dart';

import '../../core/cancellation.dart';
import '../../utils/http_response_handler.dart';
import 'config.dart';
import 'dio_strategy.dart';

/// Core Ollama HTTP client shared across all capability modules
///
/// This class provides the foundational HTTP functionality that all
/// Ollama capability implementations can use. It handles:
/// - Authentication (optional API key)
/// - Request/response processing
/// - Error handling
/// - JSON streaming (Ollama's streaming format)
/// - Provider-specific configurations
class OllamaClient {
  final OllamaConfig config;
  final Logger logger = Logger('OllamaClient');
  late final Dio dio;

  OllamaClient(this.config) {
    // Use unified Dio client factory with Ollama-specific strategy
    dio = ProviderDioClientFactory.create(
      strategy: OllamaDioStrategy(),
      config: config,
      overrides: config.dioOverrides,
    );
  }

  /// Make a POST request and return JSON response
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    TransportCancellation? cancelToken,
  }) async {
    return HttpResponseHandler.postJson(
      dio,
      endpoint,
      data,
      providerName: 'Ollama',
      logger: logger,
      cancelToken: cancelToken,
    );
  }

  /// Make a GET request and return JSON response
  Future<Map<String, dynamic>> getJson(
    String endpoint, {
    TransportCancellation? cancelToken,
  }) async {
    try {
      logger.fine('Ollama request: GET $endpoint');
      final response = await dio.get(
        endpoint,
        cancelToken: bindDioCancellation(cancelToken),
      );

      logger.fine('Ollama HTTP status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Ollama API returned status ${response.statusCode}',
        );
      }

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      logger.severe('HTTP request failed: ${e.message}');
      rethrow;
    }
  }

  /// Make a POST request and return raw stream for JSON streaming
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> data, {
    TransportCancellation? cancelToken,
  }) async* {
    try {
      logger.fine('Ollama streaming request payload: ${jsonEncode(data)}');

      final response = await dio.post(
        endpoint,
        data: data,
        cancelToken: bindDioCancellation(cancelToken),
        options: Options(responseType: ResponseType.stream),
      );

      logger.fine('Ollama streaming HTTP status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Ollama API returned status ${response.statusCode}',
        );
      }

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
    } on DioException catch (e) {
      logger.severe('Stream request failed: ${e.message}');
      rethrow;
    }
  }
}
