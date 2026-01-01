import 'package:dio/dio.dart' hide CancelToken;
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:logging/logging.dart';
import 'config.dart';
import 'dio_strategy.dart';

/// Core Anthropic HTTP client shared across all capability modules
///
/// This class provides the foundational HTTP functionality that all
/// Anthropic capability implementations can use. It handles:
/// - Authentication and headers
/// - Request/response processing
/// - Error handling
/// - SSE stream parsing
/// - Provider-specific configurations
///
/// **API Documentation:**
/// - API Overview: https://docs.anthropic.com/en/api/overview
/// - Authentication: https://docs.anthropic.com/en/api/overview#authentication
/// - Versioning: https://docs.anthropic.com/en/api/versioning
/// - Beta Features: https://docs.anthropic.com/en/api/overview#beta-features
class AnthropicClient {
  final AnthropicConfig config;
  final String providerName;
  late final Logger logger;
  late final Dio dio;

  AnthropicClient(
    this.config, {
    ProviderDioStrategy? strategy,
  }) : providerName = (strategy ?? AnthropicDioStrategy()).providerName {
    logger = Logger('${providerName}Client');
    // Use unified Dio client factory with Anthropic-specific strategy
    dio = DioClientFactory.create(
      strategy: strategy ?? AnthropicDioStrategy(),
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
      providerName: providerName,
      logger: logger,
      cancelToken: cancelToken,
    );
  }

  /// Make a GET request and return JSON response
  Future<Map<String, dynamic>> getJson(
    String endpoint, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await withDioCancelToken(
        cancelToken,
        (dioToken) => dio.get(endpoint, cancelToken: dioToken),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      logger.severe('HTTP GET request failed: ${e.message}');
      throw await DioErrorHandler.handleDioError(e, providerName);
    }
  }

  /// Make a POST request with form data
  Future<Map<String, dynamic>> postForm(
    String endpoint,
    FormData formData, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await withDioCancelToken(
        cancelToken,
        (dioToken) => dio.post(
          endpoint,
          data: formData,
          cancelToken: dioToken,
        ),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      logger.severe('HTTP form request failed: ${e.message}');
      throw await DioErrorHandler.handleDioError(e, providerName);
    }
  }

  /// Make a DELETE request
  Future<void> delete(
    String endpoint, {
    CancelToken? cancelToken,
  }) async {
    try {
      await withDioCancelToken(
        cancelToken,
        (dioToken) => dio.delete(endpoint, cancelToken: dioToken),
      );
    } on DioException catch (e) {
      logger.severe('HTTP DELETE request failed: ${e.message}');
      throw await DioErrorHandler.handleDioError(e, providerName);
    }
  }

  /// Make a GET request and return raw bytes
  Future<List<int>> getRaw(
    String endpoint, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await withDioCancelToken(
        cancelToken,
        (dioToken) => dio.get(
          endpoint,
          options: Options(responseType: ResponseType.bytes),
          cancelToken: dioToken,
        ),
      );
      return response.data as List<int>;
    } on DioException catch (e) {
      logger.severe('HTTP raw request failed: ${e.message}');
      throw await DioErrorHandler.handleDioError(e, providerName);
    }
  }

  /// Make a POST request and return raw stream for SSE
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async* {
    try {
      final response = await withDioCancelToken(
        cancelToken,
        (dioToken) => dio.post(
          endpoint,
          data: data,
          cancelToken: dioToken,
          options: Options(
            responseType: ResponseType.stream,
            headers: {'Accept': 'text/event-stream'},
          ),
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
      throw await DioErrorHandler.handleDioError(e, providerName);
    }
  }
}
