import 'package:dio/dio.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../config/xai_config.dart';
import '../http/xai_dio_strategy.dart';

class XAIClient {
  final XAIConfig config;
  final LLMLogger logger;
  late final Dio dio;

  XAIClient(this.config)
      : logger = config.originalConfig == null
            ? const NoopLLMLogger()
            : resolveLogger(config.originalConfig!) {
    dio = DioClientFactory.create(
      strategy: XAIDioStrategy(),
      config: config,
    );
  }

  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
    Map<String, String>? headers,
  }) async {
    try {
      logger.fine('xAI request: POST $endpoint');
      final response = await dio.post(
        endpoint,
        data: data,
        cancelToken: cancelToken,
        options: headers == null
            ? null
            : Options(headers: HttpHeaderUtils.mergeDioHeaders(dio, headers)),
      );
      logger.fine('xAI HTTP status: ${response.statusCode}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      logger.severe('HTTP request failed: ${e.message}', e);
      rethrow;
    }
  }

  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
    Map<String, String>? headers,
  }) async* {
    try {
      final response = await dio.post(
        endpoint,
        data: data,
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          headers: HttpHeaderUtils.mergeDioHeaders(dio, headers),
        ),
      );

      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'xAI API returned status ${response.statusCode}',
        );
      }

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
      rethrow;
    }
  }
}
