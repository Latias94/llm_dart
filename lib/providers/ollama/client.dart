import 'dart:convert';
import 'package:llm_dart_transport/dio.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart'
    show
        Level,
        LogSanitizer,
        Logger,
        ProviderDioClientFactory,
        TransportCancellation,
        bindDioCancellation;

import '../../core/llm_error.dart';
import '../../src/compatibility/http/dio_error_handler.dart';
import '../../src/compatibility/http/http_response_handler.dart';
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
    try {
      if (logger.isLoggable(Level.FINE)) {
        logger.fine(
          'Ollama request: POST ${LogSanitizer.sanitizeEndpoint(endpoint)}',
        );
        logger.fine('Ollama request payload: ${jsonEncode(data)}');
      }

      final response = await dio.post(
        endpoint,
        data: data,
        cancelToken: bindDioCancellation(cancelToken),
      );

      if (logger.isLoggable(Level.FINE)) {
        logger.fine('Ollama HTTP status: ${response.statusCode}');
      }

      await HttpResponseHandler.ensureSuccessStatus(
        response,
        providerName: 'Ollama',
        logger: logger,
      );

      return HttpResponseHandler.parseJsonResponse(
        response.data,
        providerName: 'Ollama',
      );
    } on DioException catch (e) {
      logger.severe('Ollama HTTP request failed: ${e.message}');
      throw await DioErrorHandler.handleDioError(e, 'Ollama');
    } catch (e) {
      if (e is LLMError) {
        rethrow;
      }
      logger.severe('Unexpected error in Ollama postJson: $e');
      throw GenericError('Unexpected error: $e');
    }
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

      await HttpResponseHandler.ensureSuccessStatus(
        response,
        providerName: 'Ollama',
        logger: logger,
      );

      return HttpResponseHandler.parseJsonResponse(
        response.data,
        providerName: 'Ollama',
      );
    } on DioException catch (e) {
      logger.severe('HTTP request failed: ${e.message}');
      throw await DioErrorHandler.handleDioError(e, 'Ollama');
    } catch (e) {
      if (e is LLMError) {
        rethrow;
      }
      logger.severe('Unexpected error in Ollama getJson: $e');
      throw GenericError('Unexpected error: $e');
    }
  }

  /// Make a POST request and return raw stream for JSON streaming
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> data, {
    TransportCancellation? cancelToken,
  }) async* {
    yield* HttpResponseHandler.postTextStream(
      dio,
      endpoint,
      data,
      providerName: 'Ollama',
      logger: logger,
      cancelToken: cancelToken,
      options: Options(responseType: ResponseType.stream),
      invalidBodyErrorFactory: Exception.new,
    );
  }
}
