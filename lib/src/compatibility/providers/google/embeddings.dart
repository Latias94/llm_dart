import 'package:llm_dart_transport/dio.dart';

import '../../../../core/capability.dart';
import '../../../../core/llm_error.dart';
import 'client.dart';
import '../../../../providers/google/config.dart';
import 'google_embeddings_request_builder.dart';
import 'google_embeddings_response_parser.dart';

/// Google Embeddings capability implementation
///
/// This module handles embedding generation functionality for Google providers.
/// Google provides text embedding models through the Gemini API.
/// Reference: https://ai.google.dev/api/embeddings
class GoogleEmbeddings implements EmbeddingCapability {
  final GoogleClient client;
  final GoogleConfig config;
  final GoogleEmbeddingsRequestBuilder _requestBuilder;
  final GoogleEmbeddingsResponseParser _responseParser;

  GoogleEmbeddings(this.client, this.config)
      : _requestBuilder = GoogleEmbeddingsRequestBuilder(config),
        _responseParser = const GoogleEmbeddingsResponseParser();

  String get embeddingEndpoint => 'models/${config.model}:embedContent';
  String get batchEmbeddingEndpoint =>
      'models/${config.model}:batchEmbedContents';

  @override
  Future<List<List<double>>> embed(
    List<String> input, {
    TransportCancellation? cancelToken,
  }) async {
    if (config.apiKey.isEmpty) {
      throw const AuthError('Missing Google API key');
    }

    try {
      // For single input or small batches, use single endpoint
      if (input.length == 1) {
        final requestBody =
            _requestBuilder.buildSingleEmbeddingRequest(input.first);
        final responseData = await client.postJson(
          embeddingEndpoint,
          requestBody,
          cancelToken: cancelToken,
        );
        return [_responseParser.parseSingleEmbeddingResponse(responseData)];
      } else {
        // For multiple inputs, use batch endpoint
        final requestBody = _requestBuilder.buildBatchEmbeddingRequest(input);
        final responseData = await client.postJson(
          batchEmbeddingEndpoint,
          requestBody,
          cancelToken: cancelToken,
        );
        return _responseParser.parseBatchEmbeddingResponse(responseData);
      }
    } on DioException catch (e) {
      throw await DioErrorHandler.handleDioError(e, 'Google');
    } catch (e) {
      throw GenericError('Unexpected error: $e');
    }
  }

  /// Get embedding dimensions for a model
  Future<int> getEmbeddingDimensions() async {
    final requestBody = _requestBuilder.buildSingleEmbeddingRequest('test');
    final responseData = await client.postJson(embeddingEndpoint, requestBody);
    final embedding = _responseParser.parseSingleEmbeddingResponse(
      responseData,
    );
    return embedding.length;
  }
}
