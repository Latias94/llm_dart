import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../client/ollama_client.dart';
import '../config/ollama_config.dart';

class OllamaEmbeddings implements EmbeddingCapability {
  final OllamaClient client;
  final OllamaConfig config;

  OllamaEmbeddings(this.client, this.config);

  @override
  Future<List<List<double>>> embed(
    List<String> input, {
    CancellationToken? cancelToken,
  }) async {
    // Native Ollama `/api/embed` embeddings endpoint.
    final body = <String, dynamic>{
      'model': config.model,
      // Ollama accepts either a single string or a list of strings.
      'input': input.length == 1 ? input.first : input,
    };

    // Advanced parameters: keep_alive and options.
    if (config.keepAlive != null) {
      body['keep_alive'] = config.keepAlive;
    }

    final options = <String, dynamic>{};
    if (config.temperature != null) {
      options['temperature'] = config.temperature;
    }
    if (config.maxTokens != null) {
      options['num_predict'] = config.maxTokens;
    }
    if (config.topP != null) {
      options['top_p'] = config.topP;
    }
    if (config.topK != null) {
      options['top_k'] = config.topK;
    }
    if (config.numCtx != null) {
      options['num_ctx'] = config.numCtx;
    }
    if (config.numGpu != null) {
      options['num_gpu'] = config.numGpu;
    }
    if (config.numThread != null) {
      options['num_thread'] = config.numThread;
    }
    if (config.numBatch != null) {
      options['num_batch'] = config.numBatch;
    }
    if (config.numa != null) {
      options['numa'] = config.numa;
    }

    if (options.isNotEmpty) {
      body['options'] = options;
    }

    final json = await client.postJson(
      '/api/embed',
      body,
      cancelToken: CancellationUtils.toDioCancelToken(cancelToken),
    );

    final data = json['embeddings'] as List?;
    if (data == null || data.isEmpty) {
      throw const ResponseFormatError(
        'Invalid embedding response format: missing embeddings',
        '',
      );
    }

    return data.map((e) => (e as List).cast<double>()).toList(growable: false);
  }
}
