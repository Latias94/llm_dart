import 'package:llm_dart_transport/dio.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart'
    show decodeDioResponseTextStream, Logger, ProviderDioClientFactory;

import '../../../../core/cancellation.dart';
import '../../../../core/llm_error.dart';
import '../../../../providers/anthropic/config.dart';
import '../../../../utils/http_response_handler.dart';
import '../../http/dio_request_executor.dart';
import 'dio_strategy.dart';

/// Core Anthropic HTTP client shared across all capability modules
///
/// This class provides the foundational HTTP functionality that all
/// Anthropic capability implementations can use. It handles:
/// - Authentication and headers
/// - Request/response processing
/// - Error handling
/// - SSE stream parsing
/// - Provider-specific configurations
///
/// **API Documentation:**
/// - API Overview: https://docs.anthropic.com/en/api/overview
/// - Authentication: https://docs.anthropic.com/en/api/overview#authentication
/// - Versioning: https://docs.anthropic.com/en/api/versioning
/// - Beta Features: https://docs.anthropic.com/en/api/overview#beta-features
class AnthropicClient {
  final AnthropicConfig config;
  final Logger logger = Logger('AnthropicClient');
  late final Dio dio;
  late final CompatibilityDioRequestExecutor _requestExecutor;

  AnthropicClient(this.config) {
    // Use unified Dio client factory with Anthropic-specific strategy
    dio = ProviderDioClientFactory.create(
      strategy: AnthropicDioStrategy(),
      config: config,
      overrides: config.dioOverrides,
    );
    _requestExecutor = CompatibilityDioRequestExecutor(
      dio: dio,
      logger: logger,
      mapDioException: (error) => DioErrorHandler.handleDioError(
        error,
        'Anthropic',
      ),
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
      providerName: 'Anthropic',
      logger: logger,
      cancelToken: cancelToken,
    );
  }

  /// Make a GET request and return JSON response
  Future<Map<String, dynamic>> getJson(
    String endpoint, {
    TransportCancellation? cancelToken,
  }) async {
    final response = await _requestExecutor.request(
      'GET',
      endpoint,
      cancelToken: cancelToken,
      failureLogMessage: 'HTTP GET request',
    );
    return response.data as Map<String, dynamic>;
  }

  /// Make a POST request with form data
  Future<Map<String, dynamic>> postForm(
    String endpoint,
    FormData formData, {
    TransportCancellation? cancelToken,
  }) async {
    final response = await _requestExecutor.request(
      'POST',
      endpoint,
      data: formData,
      cancelToken: cancelToken,
      failureLogMessage: 'HTTP form request',
    );
    return response.data as Map<String, dynamic>;
  }

  /// Make a DELETE request
  Future<void> delete(
    String endpoint, {
    TransportCancellation? cancelToken,
  }) async {
    await _requestExecutor.request(
      'DELETE',
      endpoint,
      cancelToken: cancelToken,
      failureLogMessage: 'HTTP DELETE request',
    );
  }

  /// Make a GET request and return raw bytes
  Future<List<int>> getRaw(
    String endpoint, {
    TransportCancellation? cancelToken,
  }) async {
    final response = await _requestExecutor.request(
      'GET',
      endpoint,
      options: Options(responseType: ResponseType.bytes),
      cancelToken: cancelToken,
      failureLogMessage: 'HTTP raw request',
    );
    return response.data as List<int>;
  }

  /// Make a POST request and return raw stream for SSE
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> data, {
    TransportCancellation? cancelToken,
  }) async* {
    final response = await _requestExecutor.request(
      'POST',
      endpoint,
      data: data,
      cancelToken: cancelToken,
      options: Options(
        responseType: ResponseType.stream,
        headers: {'Accept': 'text/event-stream'},
      ),
      failureLogMessage: 'Stream request',
    );

    yield* decodeDioResponseTextStream(
      response.data,
      invalidBodyErrorFactory: Exception.new,
    );
  }
}
