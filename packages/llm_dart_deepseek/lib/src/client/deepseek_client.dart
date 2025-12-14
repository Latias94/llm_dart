import 'package:dio/dio.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../config/deepseek_config.dart';
import '../error/deepseek_error_handler.dart';
import '../http/deepseek_dio_strategy.dart';

/// Core DeepSeek HTTP client shared across all capability modules.
///
/// This class provides the foundational HTTP functionality that all
/// DeepSeek capability implementations can use.
class DeepSeekClient {
  final DeepSeekConfig config;
  final LLMLogger logger;
  late final Dio dio;

  DeepSeekClient(this.config)
      : logger = config.originalConfig == null
            ? const NoopLLMLogger()
            : resolveLogger(config.originalConfig!) {
    dio = DioClientFactory.create(
      strategy: DeepSeekDioStrategy(),
      config: config,
    );
  }

  /// Make a POST request and return JSON response.
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
    Map<String, String>? headers,
  }) async {
    try {
      final options = headers == null
          ? null
          : Options(headers: HttpHeaderUtils.mergeDioHeaders(dio, headers));
      return await HttpResponseHandler.postJson(
        dio,
        endpoint,
        data,
        providerName: 'DeepSeek',
        logger: logger,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      logger.severe('HTTP request failed: ${e.message}', e);
      throw await DeepSeekErrorHandler.handleDioError(e);
    }
  }

  /// Make a POST request and return raw stream for SSE.
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
    Map<String, String>? headers,
  }) async* {
    try {
      final mergedHeaders = HttpHeaderUtils.mergeDioHeaders(dio, headers);
      mergedHeaders['Accept'] = 'text/event-stream';
      final response = await dio.post(
        endpoint,
        data: data,
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          headers: mergedHeaders,
        ),
      );

      final responseBody = response.data;
      Stream<List<int>> stream;

      if (responseBody is Stream<List<int>>) {
        stream = responseBody;
      } else if (responseBody is ResponseBody) {
        stream = responseBody.stream;
      } else {
        throw Exception(
          'Unexpected response type: ${responseBody.runtimeType}',
        );
      }

      final decoder = Utf8StreamDecoder();

      await for (final chunk in stream) {
        final decoded = decoder.decode(chunk);
        if (decoded.isNotEmpty) {
          yield decoded;
        }
      }

      final remaining = decoder.flush();
      if (remaining.isNotEmpty) {
        yield remaining;
      }
    } on DioException catch (e) {
      logger.severe('Stream request failed: ${e.message}', e);
      throw await DeepSeekErrorHandler.handleDioError(e);
    }
  }
}
