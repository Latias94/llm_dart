import 'package:llm_dart_core/core/cancellation.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'config.dart';
import 'dio_strategy.dart';

/// Core Google HTTP client shared across all capability modules
///
/// This class provides the foundational HTTP functionality that all
/// Google capability implementations can use. It handles:
/// - Authentication via API key query parameter
/// - Request/response processing
/// - Error handling
/// - JSON array stream parsing (Google's streaming format)
/// - Provider-specific configurations
class GoogleClient {
  final GoogleConfig config;
  final Logger logger = Logger('GoogleClient');
  late final Dio dio;

  GoogleClient(this.config) {
    // Use unified Dio client factory with Google-specific strategy
    dio = DioClientFactory.create(
      strategy: GoogleDioStrategy(),
      config: config,
    );
  }

  /// Get endpoint with API key authentication
  String _getEndpointWithAuth(String endpoint) {
    // Google uses query parameter authentication
    final separator = endpoint.contains('?') ? '&' : '?';
    return '$endpoint${separator}key=${config.apiKey}';
  }

  /// Make a POST request and return response
  Future<Response> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final fullEndpoint = _getEndpointWithAuth(endpoint);
      return await withDioCancelToken(
        cancelToken,
        (dioToken) => dio.post(
          fullEndpoint,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: dioToken,
        ),
      );
    } on DioException catch (e) {
      logger.severe('HTTP request failed: ${e.message}');
      rethrow;
    }
  }

  /// Make a POST request and return JSON response
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async {
    return HttpResponseHandler.postJson(
      dio,
      _getEndpointWithAuth(endpoint),
      data,
      providerName: 'Google',
      logger: logger,
      cancelToken: cancelToken,
    );
  }

  /// Make a POST request and return stream response
  Stream<Response> postStream(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async* {
    try {
      final fullEndpoint = _getEndpointWithAuth(endpoint);
      final response = await dio.post(
        fullEndpoint,
        data: data,
        queryParameters: queryParameters,
        options: options?.copyWith(responseType: ResponseType.stream) ??
            Options(responseType: ResponseType.stream),
      );
      yield response;
    } on DioException catch (e) {
      logger.severe('Stream request failed: ${e.message}');
      rethrow;
    }
  }

  /// Make a POST request and return raw stream for JSON array streaming
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async* {
    try {
      final fullEndpoint = _getEndpointWithAuth(endpoint);
      final response = await withDioCancelToken(
        cancelToken,
        (dioToken) => dio.post(
          fullEndpoint,
          data: data,
          cancelToken: dioToken,
          options: Options(
            responseType: ResponseType.stream,
            headers: {'Accept': 'application/json'},
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
      rethrow;
    }
  }
}
