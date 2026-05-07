import '../../../../core/llm_error.dart';

/// Parses Google embedding API responses into shared embedding vectors.
final class GoogleEmbeddingsResponseParser {
  const GoogleEmbeddingsResponseParser();

  List<double> parseSingleEmbeddingResponse(
    Map<String, dynamic> responseData,
  ) {
    final embedding = responseData['embedding'] as Map<String, dynamic>?;
    if (embedding == null) {
      throw ResponseFormatError(
        'Invalid embedding response format: missing embedding field',
        responseData.toString(),
      );
    }

    return _parseEmbeddingValues(embedding);
  }

  List<List<double>> parseBatchEmbeddingResponse(
    Map<String, dynamic> responseData,
  ) {
    final embeddings = responseData['embeddings'] as List?;
    if (embeddings == null) {
      throw ResponseFormatError(
        'Invalid batch embedding response format: missing embeddings field',
        responseData.toString(),
      );
    }

    try {
      return embeddings.map((item) {
        if (item is! Map<String, dynamic>) {
          throw ResponseFormatError(
            'Invalid embedding item format: expected Map<String, dynamic>',
            item.toString(),
          );
        }

        final embedding = item['embedding'] as Map<String, dynamic>?;
        if (embedding == null) {
          throw ResponseFormatError(
            'Invalid embedding item format: missing embedding field',
            item.toString(),
          );
        }

        return _parseEmbeddingValues(embedding);
      }).toList();
    } catch (e) {
      if (e is LLMError) rethrow;
      throw ResponseFormatError(
        'Failed to parse batch embedding response: $e',
        responseData.toString(),
      );
    }
  }

  List<double> _parseEmbeddingValues(Map<String, dynamic> embedding) {
    final values = embedding['values'] as List?;
    if (values == null) {
      throw ResponseFormatError(
        'Invalid embedding format: missing values field',
        embedding.toString(),
      );
    }

    try {
      return values.cast<double>();
    } catch (e) {
      throw ResponseFormatError(
        'Failed to parse embedding values: $e',
        values.toString(),
      );
    }
  }
}
