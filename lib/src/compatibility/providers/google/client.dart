import 'package:llm_dart_transport/dio.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart'
    show decodeDioResponseTextStream, Logger, ProviderDioClientFactory;

import '../../../../core/cancellation.dart';
import '../../../../providers/google/config.dart';
import '../../http/dio_request_executor.dart';
import '../../http/http_response_handler.dart';
import 'dio_strategy.dart';

/// Core Google HTTP client shared across all capability modules.
///
/// This class provides the foundational HTTP functionality that all
/// Google capability implementations can use.
class GoogleClient {
  final GoogleConfig config;
  final Logger logger = Logger('GoogleClient');
  late final Dio dio;
  late final CompatibilityDioRequestExecutor _requestExecutor;

  GoogleClient(this.config) {
    dio = ProviderDioClientFactory.create(
      strategy: GoogleDioStrategy(),
      config: config,
      overrides: config.dioOverrides,
    );
    _requestExecutor = CompatibilityDioRequestExecutor(
      dio: dio,
      logger: logger,
      mapDioException: (error) async => error,
    );
  }

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

  String _getEndpointWithAuth(String endpoint) {
    final separator = endpoint.contains('?') ? '&' : '?';
    return '$endpoint${separator}key=${config.apiKey}';
  }
}
