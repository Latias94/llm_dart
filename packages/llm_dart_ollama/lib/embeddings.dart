import 'package:dio/dio.dart' hide CancelToken;
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'client.dart';
import 'config.dart';

/// Ollama Embeddings capability implementation
///
/// This module handles embedding functionality for Ollama providers.
/// Ollama supports embeddings through the /api/embed endpoint.
class OllamaEmbeddings implements EmbeddingCapability {
  final OllamaClient client;
  final OllamaConfig config;

  OllamaEmbeddings(this.client, this.config);

  String get embeddingEndpoint => '/api/embed';

  @override
  Future<EmbeddingResponse> embed(
    List<String> input, {
    CancelToken? cancelToken,
  }) async {
    if (config.baseUrl.isEmpty) {
      throw const InvalidRequestError('Missing Ollama base URL');
    }

    try {
      final requestBody = _buildRequestBody(input);
      final responseData = await client.postJsonWithHeaders(
        embeddingEndpoint,
        requestBody,
        cancelToken: cancelToken,
      );
      final embeddings = _parseResponse(responseData.json);
      return EmbeddingResponse(
        embeddings: embeddings,
        response: EmbeddingCallResponse(
          headers: responseData.headers.isEmpty ? null : responseData.headers,
          body: responseData.json,
        ),
      );
    } on DioException catch (e) {
      throw await DioErrorHandler.handleDioError(e, 'Ollama');
    } catch (e) {
      throw GenericError('Unexpected error: $e');
    }
  }

  /// Build request body for Ollama embedding API
  Map<String, dynamic> _buildRequestBody(List<String> input) {
    return {
      'model': config.model,
      'input': input,
    };
  }

  /// Parse embedding response
  List<List<double>> _parseResponse(Map<String, dynamic> responseData) {
    final embeddings = responseData['embeddings'] as List?;

    if (embeddings == null) {
      throw const ProviderError('No embeddings returned by Ollama');
    }

    return embeddings.map((e) => List<double>.from(e as List)).toList();
  }
}
