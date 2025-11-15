import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import '../../core/llm_error.dart';
import '../../utils/dio_client_factory.dart';
import '../../utils/http_error_handler.dart';
import '../../utils/http_response_handler.dart';
import '../../utils/utf8_stream_decoder.dart';
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
    dio = DioClientFactory.create(
      strategy: GroqDioStrategy(),
      config: config,
    );
  }

  /// Make a POST request and return JSON response
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
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
    CancelToken? cancelToken,
  }) async* {
    try {
      final response = await dio.post(
        endpoint,
        data: data,
        cancelToken: cancelToken,
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
      throw DioErrorHandler.handleDioError(e, 'Groq');
    }
  }
}
