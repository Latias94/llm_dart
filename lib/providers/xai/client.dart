import 'package:llm_dart_transport/dio.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart'
    show Logger, ProviderDioClientFactory;

import '../../core/cancellation.dart';
import '../../src/compatibility/http/http_response_handler.dart';
import 'config.dart';
import 'dio_strategy.dart';

/// Core xAI HTTP client shared across all capability modules
///
/// This class provides the foundational HTTP functionality that all
/// xAI capability implementations can use. It handles:
/// - Authentication and headers (OpenAI-compatible)
/// - Request/response processing
/// - Error handling
/// - SSE stream parsing
/// - Provider-specific configurations
class XAIClient {
  final XAIConfig config;
  final Logger logger = Logger('XAIClient');
  late final Dio dio;

  XAIClient(this.config) {
    // Use unified Dio client factory with xAI-specific strategy
    dio = ProviderDioClientFactory.create(
      strategy: XAIDioStrategy(),
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
      providerName: 'xAI',
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
      providerName: 'xAI',
      logger: logger,
      cancelToken: cancelToken,
      options: Options(responseType: ResponseType.stream),
      invalidBodyErrorFactory: Exception.new,
    );
  }
}
