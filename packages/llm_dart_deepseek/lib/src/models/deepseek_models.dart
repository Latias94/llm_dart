import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../client/deepseek_client.dart';
import '../config/deepseek_config.dart';

/// DeepSeek Models capability implementation.
///
/// This module handles model listing functionality for DeepSeek providers.
class DeepSeekModels implements ModelListingCapability {
  final DeepSeekClient client;
  final DeepSeekConfig config;

  DeepSeekModels(this.client, this.config);

  String get modelsEndpoint => 'models';

  @override
  Future<List<AIModel>> models({CancellationToken? cancelToken}) async {
    try {
      final response = await client.dio.get(
        modelsEndpoint,
        cancelToken: CancellationUtils.toDioCancelToken(cancelToken),
      );
      final responseData = response.data as Map<String, dynamic>;

      final data = responseData['data'] as List?;
      if (data == null) {
        throw Exception('Invalid response format: missing data field');
      }

      return data
          .cast<Map<String, dynamic>>()
          .map((modelData) => _parseModelInfo(modelData))
          .toList();
    } catch (e) {
      client.logger.severe('Failed to list models: $e');
      rethrow;
    }
  }

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
