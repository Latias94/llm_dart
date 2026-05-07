part of 'client.dart';

mixin _GoogleClientHttpMixin {
  GoogleConfig get config;
  Logger get logger;
  Dio get dio;
  CompatibilityDioRequestExecutor get _requestExecutor;

  Future<Response> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    TransportCancellation? cancelToken,
  }) async {
    return _requestExecutor.request(
      'POST',
      _getEndpointWithAuth(config, endpoint),
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
      _getEndpointWithAuth(config, endpoint),
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
      _getEndpointWithAuth(config, endpoint),
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
      _getEndpointWithAuth(config, endpoint),
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
