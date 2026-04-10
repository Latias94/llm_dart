import 'package:llm_dart_transport/dio.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart'
    show
        decodeDioResponseTextStream,
        Logger,
        ProviderDioClientFactory,
        bindDioCancellation;

import '../../core/cancellation.dart';
import '../../utils/http_response_handler.dart';
import 'config.dart';
import 'dio_strategy.dart';
import 'error_handler.dart';

/// Core DeepSeek HTTP client shared across all capability modules
///
/// This class provides the foundational HTTP functionality that all
/// DeepSeek capability implementations can use. It handles:
/// - Authentication and headers (OpenAI-compatible)
/// - Request/response processing
/// - Error handling
/// - SSE stream parsing
/// - Provider-specific configurations
class DeepSeekClient {
  final DeepSeekConfig config;
  final Logger logger = Logger('DeepSeekClient');
  late final Dio dio;

  DeepSeekClient(this.config) {
    // Use unified Dio client factory with DeepSeek-specific strategy
    dio = ProviderDioClientFactory.create(
      strategy: DeepSeekDioStrategy(),
      config: config,
    );
  }

  /// Make a POST request and return JSON response
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    TransportCancellation? cancelToken,
  }) async {
    try {
      return await HttpResponseHandler.postJson(
        dio,
        endpoint,
        data,
        providerName: 'DeepSeek',
        logger: logger,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      logger.severe('HTTP request failed: ${e.message}');
      throw await DeepSeekErrorHandler.handleDioError(e);
    }
  }

  /// Make a POST request and return raw stream for SSE
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> data, {
    TransportCancellation? cancelToken,
  }) async* {
    try {
      final response = await dio.post(
        endpoint,
        data: data,
        cancelToken: bindDioCancellation(cancelToken),
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'},
        ),
      );

      yield* decodeDioResponseTextStream(
        response.data,
        invalidBodyErrorFactory: Exception.new,
      );
    } on DioException catch (e) {
      logger.severe('Stream request failed: ${e.message}');
      throw await DeepSeekErrorHandler.handleDioError(e);
    }
  }
}
