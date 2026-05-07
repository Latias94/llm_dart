part of 'client.dart';

mixin _OpenAIClientHttpMixin {
  OpenAIConfig get config;
  Logger get logger;
  Dio get dio;
  OpenAISseChunkParser get _sseChunkParser;
  OpenAIClientErrorAdapter get _errorAdapter;

  /// Make a POST request with JSON body.
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> body, {
    TransportCancellation? cancelToken,
  }) async {
    return _request(
      endpoint: endpoint,
      logLabel: 'POST /$endpoint',
      cancelToken: cancelToken,
      send: (boundCancelToken) => dio.post(
        endpoint,
        data: body,
        cancelToken: boundCancelToken,
      ),
      decode: (response) => HttpResponseHandler.parseJsonResponse(
        response.data,
        providerName: 'OpenAI',
      ),
    );
  }

  /// Make a POST request with form data.
  Future<Map<String, dynamic>> postForm(
    String endpoint,
    FormData formData, {
    TransportCancellation? cancelToken,
  }) async {
    return _request(
      endpoint: endpoint,
      logLabel: 'POST /$endpoint (form)',
      cancelToken: cancelToken,
      send: (boundCancelToken) => dio.post(
        endpoint,
        data: formData,
        cancelToken: boundCancelToken,
      ),
      decode: (response) => response.data as Map<String, dynamic>,
    );
  }

  /// Make a POST request and return raw bytes.
  Future<List<int>> postRaw(
    String endpoint,
    Map<String, dynamic> body, {
    TransportCancellation? cancelToken,
  }) async {
    return _request(
      endpoint: endpoint,
      cancelToken: cancelToken,
      send: (boundCancelToken) => dio.post(
        endpoint,
        data: body,
        cancelToken: boundCancelToken,
        options: Options(responseType: ResponseType.bytes),
      ),
      decode: (response) => response.data as List<int>,
    );
  }

  /// Make a GET request.
  Future<Map<String, dynamic>> get(
    String endpoint, {
    TransportCancellation? cancelToken,
  }) async {
    return _request(
      endpoint: endpoint,
      logLabel: 'GET /$endpoint',
      cancelToken: cancelToken,
      send: (boundCancelToken) => dio.get(
        endpoint,
        cancelToken: boundCancelToken,
      ),
      decode: (response) => response.data as Map<String, dynamic>,
    );
  }

  /// Make a GET request and return raw bytes.
  Future<List<int>> getRaw(
    String endpoint, {
    TransportCancellation? cancelToken,
  }) async {
    return _request(
      endpoint: endpoint,
      cancelToken: cancelToken,
      send: (boundCancelToken) => dio.get(
        endpoint,
        options: Options(responseType: ResponseType.bytes),
        cancelToken: boundCancelToken,
      ),
      decode: (response) => response.data as List<int>,
    );
  }

  /// Make a DELETE request.
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    TransportCancellation? cancelToken,
  }) async {
    return _request(
      endpoint: endpoint,
      logLabel: 'DELETE /$endpoint',
      cancelToken: cancelToken,
      send: (boundCancelToken) => dio.delete(
        endpoint,
        cancelToken: boundCancelToken,
      ),
      decode: (response) => response.data as Map<String, dynamic>,
    );
  }

  /// Make a POST request and return SSE stream.
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> body, {
    TransportCancellation? cancelToken,
  }) async* {
    yield* await _request(
      endpoint: endpoint,
      logLabel: 'POST /$endpoint (stream)',
      cancelToken: cancelToken,
      resetSseBuffer: true,
      send: (boundCancelToken) => dio.post(
        endpoint,
        data: body,
        cancelToken: boundCancelToken,
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'},
        ),
      ),
      decode: (response) => decodeDioResponseTextStream(
        response.data,
        invalidBodyErrorFactory: GenericError.new,
      ),
    );
  }

  Future<T> _request<T>({
    required String endpoint,
    required Future<Response<dynamic>> Function(CancelToken? cancelToken) send,
    required T Function(Response<dynamic> response) decode,
    TransportCancellation? cancelToken,
    String? logLabel,
    bool resetSseBuffer = false,
  }) async {
    _ensureApiKey();
    if (resetSseBuffer) {
      _sseChunkParser.reset();
    }
    _logRequest(logLabel);

    try {
      final response = await send(bindDioCancellation(cancelToken));
      await _ensureSuccessStatus(response, endpoint);
      return decode(response);
    } on DioException catch (e) {
      throw await handleDioError(e);
    } catch (e) {
      if (e is LLMError) {
        rethrow;
      }
      throw GenericError('Unexpected error: $e');
    }
  }

  void _ensureApiKey() {
    if (config.apiKey.isEmpty) {
      throw const AuthError('Missing OpenAI API key');
    }
  }

  void _logRequest(String? logLabel) {
    if (logLabel == null || !logger.isLoggable(Level.FINE)) {
      return;
    }

    logger.fine('OpenAI request: $logLabel');
    logger.fine(
      'OpenAI request headers: '
      '${LogSanitizer.sanitizeHeaders(dio.options.headers)}',
    );
  }

  Future<void> _ensureSuccessStatus(Response response, String endpoint) {
    return _errorAdapter.ensureSuccessStatus(response, endpoint);
  }

  /// Handle Dio errors and convert them to appropriate LLM errors.
  Future<LLMError> handleDioError(DioException e) async {
    return _errorAdapter.handleDioError(e);
  }
}
