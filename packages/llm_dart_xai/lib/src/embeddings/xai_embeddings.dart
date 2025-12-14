import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../client/xai_client.dart';
import '../config/xai_config.dart';

class XAIEmbeddings implements EmbeddingCapability {
  final XAIClient client;
  final XAIConfig config;

  XAIEmbeddings(this.client, this.config);

  @override
  Future<List<List<double>>> embed(
    List<String> input, {
    CancellationToken? cancelToken,
  }) async {
    final embeddings = <List<double>>[];

    for (final text in input) {
      final body = {
        'model': config.model,
        'input': text,
        if (config.embeddingEncodingFormat != null)
          'encoding_format': config.embeddingEncodingFormat,
        if (config.embeddingDimensions != null)
          'dimensions': config.embeddingDimensions,
      };

      final json = await client.postJson(
        'embeddings',
        body,
        cancelToken: CancellationUtils.toDioCancelToken(cancelToken),
      );
      final data = json['data'] as List?;
      if (data == null || data.isEmpty) {
        throw const ResponseFormatError(
          'Invalid embedding response format: missing data',
          '',
        );
      }
      final first = data.first as Map<String, dynamic>;
      final values = first['embedding'] as List?;
      if (values == null) {
        throw const ResponseFormatError(
          'Invalid embedding response format: missing embedding field',
          '',
        );
      }
      embeddings.add(values.cast<double>());
    }

    return embeddings;
  }
}
