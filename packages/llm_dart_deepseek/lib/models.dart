import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/client.dart';

import 'config.dart';

/// DeepSeek Models capability implementation
///
/// This module handles model listing functionality for DeepSeek providers.
/// Reference: https://api-docs.deepseek.com/api/list-models
class DeepSeekModels {
  final OpenAIClient client;
  final DeepSeekConfig config;

  DeepSeekModels(this.client, this.config);

  String get modelsEndpoint => 'models';

  Future<List<AIModel>> models({CancelToken? cancelToken}) async {
    final responseData = await client.getJson(
      modelsEndpoint,
      cancelToken: cancelToken,
    );

    final data = responseData['data'] as List?;
    if (data == null) {
      throw Exception('Invalid response format: missing data field');
    }

    return data
        .cast<Map<String, dynamic>>()
        .map((modelData) => _parseModelInfo(modelData))
        .toList();
  }

  /// Parse model info from DeepSeek API response
  AIModel _parseModelInfo(Map<String, dynamic> modelData) {
    final id = modelData['id'] as String;
    final ownedBy = modelData['owned_by'] as String? ?? 'deepseek';

    return AIModel(
      id: id,
      description: _getModelDescription(id),
      object: modelData['object'] as String? ?? 'model',
      ownedBy: ownedBy,
    );
  }

  /// Get model description based on model ID
  String _getModelDescription(String modelId) {
    switch (modelId) {
      case 'deepseek-chat':
        return 'DeepSeek Chat model for general conversation and tasks';
      case 'deepseek-reasoner':
        return 'DeepSeek Reasoner model with advanced reasoning capabilities';
      default:
        return 'DeepSeek model: $modelId';
    }
  }
}
