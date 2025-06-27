import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import '../../utils/dio_client_factory.dart';
import '../../utils/http_response_handler.dart';
import '../../utils/utf8_stream_decoder.dart';
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
    dio = DioClientFactory.create(
      strategy: DeepSeekDioStrategy(),
      config: config,
    );
  }

  /// Make a POST request and return JSON response
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      return await HttpResponseHandler.postJson(
        dio,
        endpoint,
        data,
        providerName: 'DeepSeek',
        logger: logger,
      );
    } on DioException catch (e) {
      logger.severe('HTTP request failed: ${e.message}');
      throw DeepSeekErrorHandler.handleDioError(e);
    }
  }

  /// Make a POST request and return raw stream for SSE
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> data,
  ) async* {
    try {
      final response = await dio.post(
        endpoint,
        data: data,
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'},
        ),
      );

      // Handle ResponseBody properly for streaming
      final responseBody = response.data;
      Stream<List<int>> stream;

      if (responseBody is Stream<List<int>>) {
        stream = responseBody;
      } else if (responseBody is ResponseBody) {
        stream = responseBody.stream;
      } else {
        throw Exception(
            'Unexpected response type: ${responseBody.runtimeType}');
      }

      // Use UTF-8 stream decoder to handle incomplete byte sequences
      final decoder = Utf8StreamDecoder();

      await for (final chunk in stream) {
        final decoded = decoder.decode(chunk);
        if (decoded.isNotEmpty) {
          yield decoded;
        }
      }

      // Flush any remaining bytes
      final remaining = decoder.flush();
      if (remaining.isNotEmpty) {
        yield remaining;
      }
    } on DioException catch (e) {
      logger.severe('Stream request failed: ${e.message}');
      throw DeepSeekErrorHandler.handleDioError(e);
    }
  }
}
