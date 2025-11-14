import 'package:llm_dart_core/llm_dart_core.dart';

import '../client/ollama_client.dart';
import '../config/ollama_config.dart';

class OllamaModels implements ModelListingCapability {
  final OllamaClient client;
  final OllamaConfig config;

  OllamaModels(this.client, this.config);

  @override
  Future<List<AIModel>> models({CancelToken? cancelToken}) async {
    final json = await client.getJson('/v1/models', cancelToken: cancelToken);
    final models = json['data'] as List? ?? [];

    return models
        .whereType<Map<String, dynamic>>()
        .map(
          (m) => AIModel(
            id: m['id'] as String? ?? '',
            description: m['name'] as String?,
          ),
        )
        .toList();
  }
}
