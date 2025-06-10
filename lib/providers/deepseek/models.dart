import '../../core/capability.dart';
import '../../models/chat_models.dart';
import 'client.dart';
import 'config.dart';

/// DeepSeek Models capability implementation
///
/// This module handles model listing functionality for DeepSeek providers.
/// Reference: https://api-docs.deepseek.com/api/list-models
class DeepSeekModels implements ModelListingCapability {
  final DeepSeekClient client;
  final DeepSeekConfig config;

  DeepSeekModels(this.client, this.config);

  String get modelsEndpoint => 'models';

  @override
  Future<List<AIModel>> models() async {
    try {
      final response = await client.dio.get(modelsEndpoint);
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
