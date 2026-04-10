import 'package:llm_dart_transport/dio.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart'
    show
        decodeDioResponseTextStream,
        Logger,
        ProviderDioClientFactory;

import '../../../../core/cancellation.dart';
import '../../../../utils/http_response_handler.dart';
import '../../../../providers/google/config.dart';
import '../../http/dio_request_executor.dart';
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
  late final CompatibilityDioRequestExecutor _requestExecutor;

  GoogleClient(this.config) {
    // Use unified Dio client factory with Google-specific strategy
    dio = ProviderDioClientFactory.create(
      strategy: GoogleDioStrategy(),
      config: config,
    );
    _requestExecutor = CompatibilityDioRequestExecutor(
      dio: dio,
      logger: logger,
      mapDioException: (error) async => error,
    );
  }

  /// Get endpoint with API key authentication
  String _getEndpointWithAuth(String endpoint) {
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
    TransportCancellation? cancelToken,
  }) async {
    return _requestExecutor.request(
      'POST',
      _getEndpointWithAuth(endpoint),
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      failureLogMessage: 'HTTP request',
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
      _getEndpointWithAuth(endpoint),
      data,
      providerName: 'Google',
      logger: logger,
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
    yield await _requestExecutor.request(
      'POST',
      _getEndpointWithAuth(endpoint),
      data: data,
      queryParameters: queryParameters,
      options: options?.copyWith(responseType: ResponseType.stream) ??
          Options(responseType: ResponseType.stream),
      failureLogMessage: 'Stream request',
    );
  }

  /// Make a POST request and return raw stream for JSON array streaming
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> data, {
    TransportCancellation? cancelToken,
  }) async* {
    final response = await _requestExecutor.request(
      'POST',
      _getEndpointWithAuth(endpoint),
      data: data,
      cancelToken: cancelToken,
      options: Options(
        responseType: ResponseType.stream,
        headers: {'Accept': 'application/json'},
      ),
      failureLogMessage: 'Stream request',
    );

    yield* decodeDioResponseTextStream(
      response.data,
      invalidBodyErrorFactory: Exception.new,
    );
  }
}
