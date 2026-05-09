import 'package:llm_dart_transport/dio.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart'
    show
        decodeDioResponseTextStream,
        Level,
        LogSanitizer,
        Logger,
        ProviderDioClientFactory,
        bindDioCancellation;

import '../../../../core/cancellation.dart' show TransportCancellation;
import '../../../../core/llm_error.dart';
import '../../../../models/chat_models.dart';
import '../../../../providers/openai/config.dart';
import '../../http/http_response_handler.dart';
import 'client_error_support.dart';
import 'client_message_support.dart';
import 'client_sse_support.dart';
import 'config_views.dart';
import 'dio_strategy.dart';

/// Core OpenAI HTTP client shared across all capability modules
///
/// This class provides the foundational HTTP functionality that all
/// OpenAI capability implementations can use. It handles:
/// - Authentication and headers
/// - Request/response processing
/// - Error handling
/// - SSE stream parsing
/// - Provider-specific configurations
class OpenAIClient {
  final OpenAIConfig config;
  final Logger logger = Logger('OpenAIClient');
  late final Dio dio;
  late final OpenAISseChunkParser _sseChunkParser;
  late final OpenAIClientMessageCodec _messageCodec;
  late final OpenAIClientErrorAdapter _errorAdapter;

  OpenAIClient(this.config) {
    // Use unified Dio client factory with OpenAI-specific strategy
    dio = ProviderDioClientFactory.create(
      strategy: OpenAIDioStrategy(),
      config: config,
      overrides: config.dioOverrides,
    );
    _sseChunkParser = OpenAISseChunkParser(logger);
    _messageCodec = OpenAIClientMessageCodec(
      usesResponsesApi: config.responsesCompat.enabled,
    );
    _errorAdapter = OpenAIClientErrorAdapter(logger);
  }

  /// Get provider ID based on base URL for provider-specific behavior.
  String get providerId {
    final baseUrl = config.baseUrl.toLowerCase();

    if (baseUrl.contains('openrouter')) {
      return 'openrouter';
    } else if (baseUrl.contains('groq')) {
      return 'groq';
    } else if (baseUrl.contains('deepseek')) {
      return 'deepseek';
    } else if (baseUrl.contains('azure')) {
      return 'azure-openai';
    } else if (baseUrl.contains('copilot') || baseUrl.contains('github')) {
      return 'copilot';
    } else if (baseUrl.contains('together')) {
      return 'together';
    } else if (baseUrl.contains('openai')) {
      return 'openai';
    } else {
      return 'openai';
    }
  }

  List<Map<String, dynamic>> parseSSEChunk(String chunk) {
    return _sseChunkParser.parse(chunk);
  }

  /// Reset SSE buffer (call when starting a new stream).
  void resetSSEBuffer() {
    _sseChunkParser.reset();
  }

  /// Convert ChatMessage to OpenAI API format.
  Map<String, dynamic> convertMessage(ChatMessage message) {
    return _messageCodec.convertMessage(message);
  }

  /// Build API messages array from ChatMessage list.
  ///
  /// Note: System prompt should be added by the calling module if needed,
  /// not here to avoid duplication.
  List<Map<String, dynamic>> buildApiMessages(List<ChatMessage> messages) {
    return _messageCodec.buildApiMessages(messages);
  }

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
