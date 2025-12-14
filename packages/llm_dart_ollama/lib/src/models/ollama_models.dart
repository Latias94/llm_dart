import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../client/ollama_client.dart';
import '../config/ollama_config.dart';

class OllamaModels implements ModelListingCapability {
  final OllamaClient client;
  final OllamaConfig config;

  OllamaModels(this.client, this.config);

  @override
  Future<List<AIModel>> models({CancellationToken? cancelToken}) async {
    // Native Ollama `/api/tags` endpoint for listing local models.
    final json = await client.getJson(
      '/api/tags',
      cancelToken: CancellationUtils.toDioCancelToken(cancelToken),
    );
    final models = json['models'] as List? ?? [];

    return models
        .whereType<Map<String, dynamic>>()
        .map(
          (m) => AIModel(
            // Use the full model identifier (e.g. "llama3.2:latest") as ID.
            id: m['model'] as String? ?? m['name'] as String? ?? '',
            description: m['name'] as String?,
          ),
        )
        .toList();
  }
}
