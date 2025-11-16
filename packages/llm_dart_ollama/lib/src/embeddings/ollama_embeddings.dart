import 'package:llm_dart_core/llm_dart_core.dart';

import '../client/ollama_client.dart';
import '../config/ollama_config.dart';

class OllamaEmbeddings implements EmbeddingCapability {
  final OllamaClient client;
  final OllamaConfig config;

  OllamaEmbeddings(this.client, this.config);

  @override
  Future<List<List<double>>> embed(
    List<String> input, {
    CancelToken? cancelToken,
  }) async {
    // TODO(ollama-native): this uses the OpenAI-compatible `/v1/embeddings`
    // endpoint; consider migrating to the native `/api/embeddings` and
    // adjusting the request/response mapping accordingly.
    final embeddings = <List<double>>[];

    for (final text in input) {
      final body = <String, dynamic>{
        'model': config.model,
        'input': text,
      };

      final json = await client.postJson('/v1/embeddings', body,
          cancelToken: cancelToken);
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
