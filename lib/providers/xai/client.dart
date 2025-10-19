import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import '../../core/llm_error.dart';
import '../../utils/dio_client_factory.dart';
import '../../utils/http_response_handler.dart';
import '../../utils/utf8_stream_decoder.dart';
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
    dio = DioClientFactory.create(
      strategy: XAIDioStrategy(),
      config: config,
    );
  }

  /// Make a POST request and return JSON response
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async {
    try {
      return await HttpResponseHandler.postJson(
        dio,
        endpoint,
        data,
        providerName: 'xAI',
        logger: logger,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      logger.severe('HTTP request failed: ${e.message}');
      throw DioErrorHandler.handleDioError(e, 'xAI');
    }
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
        options: Options(responseType: ResponseType.stream),
      );

      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'xAI API returned status ${response.statusCode}',
        );
      }

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
      throw DioErrorHandler.handleDioError(e, 'xAI');
    }
  }
}
