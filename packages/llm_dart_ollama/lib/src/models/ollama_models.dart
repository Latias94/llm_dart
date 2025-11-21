import 'package:llm_dart_core/llm_dart_core.dart';

import '../client/ollama_client.dart';
import '../config/ollama_config.dart';

class OllamaModels implements ModelListingCapability {
  final OllamaClient client;
  final OllamaConfig config;

  OllamaModels(this.client, this.config);

  @override
  Future<List<AIModel>> models({CancelToken? cancelToken}) async {
    // Native Ollama `/api/tags` endpoint for listing local models.
    final json = await client.getJson('/api/tags', cancelToken: cancelToken);
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
