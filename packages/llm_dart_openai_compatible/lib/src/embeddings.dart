import 'package:llm_dart_core/llm_dart_core.dart';
import 'client.dart';
import 'openai_request_config.dart';

/// OpenAI Embeddings capability implementation
///
/// This module handles vector embedding generation for OpenAI providers.
class OpenAIEmbeddings
    implements EmbeddingCapability, EmbeddingCallOptionsCapability {
  final OpenAIClient client;
  final OpenAIRequestConfig config;

  OpenAIEmbeddings(this.client, this.config);

  @override
  Future<List<List<double>>> embed(
    List<String> input, {
    CancelToken? cancelToken,
  }) async {
    return embedWithCallOptions(
      input,
      callOptions: const LLMCallOptions(),
      cancelToken: cancelToken,
    );
  }

  @override
  Future<List<List<double>>> embedWithCallOptions(
    List<String> input, {
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) async {
    final requestBody = {
      'model': config.model,
      'input': input,
      'encoding_format': config.embeddingEncodingFormat ?? 'float',
      if (config.embeddingDimensions != null)
        'dimensions': config.embeddingDimensions,
    };
    final effectiveRequestBody = callOptions.mergeIntoRequestBody(requestBody);

    final responseData = await client.postJsonWithHeaders(
      'embeddings',
      effectiveRequestBody,
      headers: callOptions.headers,
      cancelToken: cancelToken,
    );
    final json = responseData.json;

    final data = json['data'] as List?;
    if (data == null) {
      throw ResponseFormatError(
        'Invalid embedding response format: missing data field',
        json.toString(),
      );
    }

    try {
      final embeddings = data.map((item) {
        if (item is! Map<String, dynamic>) {
          throw ResponseFormatError(
            'Invalid embedding item format: expected Map<String, dynamic>',
            item.toString(),
          );
        }

        final embedding = item['embedding'];
        if (embedding is! List) {
          throw ResponseFormatError(
            'Invalid embedding format: expected List',
            embedding.toString(),
          );
        }

        return embedding.cast<double>();
      }).toList();

      return embeddings;
    } catch (e) {
      if (e is LLMError) rethrow;
      throw ResponseFormatError(
        'Failed to parse embedding response: $e',
        json.toString(),
      );
    }
  }

  /// Get embedding dimensions for a model
  Future<int> getEmbeddingDimensions() async {
    final requestBody = {
      'model': config.model,
      'input': 'hi', // Simple test input
    };

    final responseData = await client.postJson('embeddings', requestBody);

    final data = responseData['data'] as List?;
    if (data == null || data.isEmpty) {
      throw const ResponseFormatError(
        'Invalid embedding response format',
        'Missing data field',
      );
    }

    final embedding =
        (data.first as Map<String, dynamic>)['embedding'] as List?;
    if (embedding == null) {
      throw const ResponseFormatError(
        'Invalid embedding response format',
        'Missing embedding field',
      );
    }

    return embedding.length;
  }
}
