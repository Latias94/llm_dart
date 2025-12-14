import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../client/openai_compatible_client.dart';
import '../config/openai_compatible_config.dart';

/// OpenAI-compatible embeddings capability implementation.
///
/// This module handles vector embedding generation for providers that
/// expose an OpenAI-style `/embeddings` endpoint.
class OpenAICompatibleEmbeddings implements EmbeddingCapability {
  final OpenAICompatibleClient client;
  final OpenAICompatibleConfig config;

  OpenAICompatibleEmbeddings(this.client, this.config);

  @override
  Future<List<List<double>>> embed(
    List<String> input, {
    CancellationToken? cancelToken,
  }) async {
    final requestBody = <String, dynamic>{
      'model': config.model,
      'input': input,
    };

    final responseData = await client.postJson(
      'embeddings',
      requestBody,
      cancelToken: CancellationUtils.toDioCancelToken(cancelToken),
    );

    final data = responseData['data'] as List?;
    if (data == null) {
      throw ResponseFormatError(
        'Invalid embedding response format: missing data field',
        responseData.toString(),
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
        responseData.toString(),
      );
    }
  }
}
