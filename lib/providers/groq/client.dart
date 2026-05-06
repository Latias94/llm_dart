import 'package:llm_dart_transport/dio.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart'
    show Logger, ProviderDioClientFactory;

import '../../core/cancellation.dart';
import '../../utils/http_response_handler.dart';
import 'config.dart';
import 'dio_strategy.dart';

/// Core Groq HTTP client shared across all capability modules
///
/// This class provides the foundational HTTP functionality that all
/// Groq capability implementations can use. It handles:
/// - Authentication and headers (OpenAI-compatible)
/// - Request/response processing
/// - Error handling
/// - SSE stream parsing
/// - Provider-specific configurations
class GroqClient {
  final GroqConfig config;
  final Logger logger = Logger('GroqClient');
  late final Dio dio;

  GroqClient(this.config) {
    // Use unified Dio client factory with Groq-specific strategy
    dio = ProviderDioClientFactory.create(
      strategy: GroqDioStrategy(),
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
      providerName: 'Groq',
      logger: logger,
      cancelToken: cancelToken,
    );
  }

  /// Make a POST request and return raw stream for SSE
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> data, {
    TransportCancellation? cancelToken,
  }) async* {
    yield* HttpResponseHandler.postTextStream(
      dio,
      endpoint,
      data,
      providerName: 'Groq',
      logger: logger,
      cancelToken: cancelToken,
      options: Options(
        responseType: ResponseType.stream,
        headers: {'Accept': 'text/event-stream'},
      ),
      invalidBodyErrorFactory: Exception.new,
    );
  }
}
