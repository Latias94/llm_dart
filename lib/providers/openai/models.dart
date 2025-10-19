import 'package:dio/dio.dart';

import '../../core/capability.dart';
import '../../core/llm_error.dart';
import '../../models/chat_models.dart';
import 'client.dart';
import 'config.dart';

/// OpenAI Model Listing capability implementation
///
/// This module handles model listing and information retrieval
/// for OpenAI providers.
class OpenAIModels implements ModelListingCapability {
  final OpenAIClient client;
  final OpenAIConfig config;

  OpenAIModels(this.client, this.config);

  @override
  Future<List<AIModel>> models({CancelToken? cancelToken}) async {
    final responseData = await client.get('models', cancelToken: cancelToken);

    // responseData is already Map<String, dynamic> from client.get()

    final modelsData = responseData['data'] as List?;
    if (modelsData == null) {
      return [];
    }

    // Convert OpenAI model format to AIModel
    final models = modelsData
        .map((modelData) {
          if (modelData is! Map<String, dynamic>) return null;

          try {
            return AIModel(
              id: modelData['id'] as String,
              description: modelData['description'] as String?,
              object: modelData['object'] as String? ?? 'model',
              ownedBy: modelData['owned_by'] as String?,
            );
          } catch (e) {
            client.logger.warning('Failed to parse model: $e');
            return null;
          }
        })
        .where((model) => model != null)
        .cast<AIModel>()
        .toList();

    client.logger.fine('Retrieved ${models.length} models from OpenAI');
    return models;
  }

  /// Get a specific model by ID
  Future<AIModel?> getModel(String modelId) async {
    try {
      final responseData = await client.get('models/$modelId');

      return AIModel(
        id: responseData['id'] as String,
        description: responseData['description'] as String?,
        object: responseData['object'] as String? ?? 'model',
        ownedBy: responseData['owned_by'] as String?,
      );
    } catch (e) {
      if (e is ResponseFormatError && e.message.contains('404')) {
        return null;
      }
      rethrow;
    }
  }

  /// Check if a model exists and is accessible
  Future<bool> modelExists(String modelId) async {
    final model = await getModel(modelId);
    return model != null;
  }

  /// Get models by owner
  Future<List<AIModel>> getModelsByOwner(String owner) async {
    final allModels = await models();
    return allModels.where((model) => model.ownedBy == owner).toList();
  }

  /// Get OpenAI models only
  Future<List<AIModel>> getOpenAIModels() async {
    return getModelsByOwner('openai');
  }

  /// Get fine-tuned models
  Future<List<AIModel>> getFineTunedModels() async {
    final allModels = await models();
    return allModels
        .where(
            (model) => model.ownedBy != 'openai' && model.ownedBy != 'system')
        .toList();
  }

  /// Get models suitable for chat
  Future<List<AIModel>> getChatModels() async {
    final allModels = await models();
    return allModels
        .where((model) =>
            model.id.contains('gpt') ||
            model.id.contains('chat') ||
            model.id.contains('turbo'))
        .toList();
  }

  /// Get models suitable for embeddings
  Future<List<AIModel>> getEmbeddingModels() async {
    final allModels = await models();
    return allModels
        .where((model) =>
            model.id.contains('embedding') || model.id.contains('ada'))
        .toList();
  }

  /// Get models suitable for image generation
  Future<List<AIModel>> getImageModels() async {
    final allModels = await models();
    return allModels
        .where((model) =>
            model.id.contains('dall-e') || model.id.contains('dalle'))
        .toList();
  }

  /// Get models suitable for audio/speech
  Future<List<AIModel>> getAudioModels() async {
    final allModels = await models();
    return allModels
        .where(
            (model) => model.id.contains('whisper') || model.id.contains('tts'))
        .toList();
  }

  /// Check if a model supports a specific capability
  Future<bool> modelSupportsCapability(
      String modelId, String capability) async {
    final model = await getModel(modelId);
    if (model == null) return false;

    switch (capability.toLowerCase()) {
      case 'chat':
        return model.id.contains('gpt') ||
            model.id.contains('chat') ||
            model.id.contains('turbo');
      case 'embedding':
        return model.id.contains('embedding') || model.id.contains('ada');
      case 'image':
        return model.id.contains('dall-e') || model.id.contains('dalle');
      case 'audio':
      case 'speech':
        return model.id.contains('whisper') || model.id.contains('tts');
      case 'reasoning':
        return model.id.contains('o1') || model.id.contains('reasoning');
      default:
        return false;
    }
  }

  /// Get recommended model for a specific use case
  Future<AIModel?> getRecommendedModel(String useCase) async {
    final allModels = await models();

    switch (useCase.toLowerCase()) {
      case 'chat':
      case 'conversation':
        return allModels.firstWhere(
          (model) => model.id == 'gpt-4' || model.id == 'gpt-4-turbo',
          orElse: () => allModels.firstWhere(
            (model) => model.id.contains('gpt-4'),
            orElse: () => allModels.first,
          ),
        );
      case 'embedding':
        return allModels.firstWhere(
          (model) => model.id.contains('text-embedding-3'),
          orElse: () => allModels.firstWhere(
            (model) => model.id.contains('embedding'),
            orElse: () => allModels.first,
          ),
        );
      case 'image':
        return allModels.firstWhere(
          (model) => model.id.contains('dall-e-3'),
          orElse: () => allModels.firstWhere(
            (model) => model.id.contains('dall-e'),
            orElse: () => allModels.first,
          ),
        );
      case 'reasoning':
        return allModels.firstWhere(
          (model) => model.id.contains('o1-preview'),
          orElse: () => allModels.firstWhere(
            (model) => model.id.contains('o1'),
            orElse: () => allModels.first,
          ),
        );
      default:
        return allModels.isNotEmpty ? allModels.first : null;
    }
  }

  /// Get model pricing information (if available)
  Map<String, dynamic> getModelPricing(String modelId) {
    // This is a simplified pricing map - in a real implementation,
    // you might fetch this from an API or configuration
    const pricingMap = {
      'gpt-4': {'input': 0.03, 'output': 0.06, 'unit': 'per 1K tokens'},
      'gpt-4-turbo': {'input': 0.01, 'output': 0.03, 'unit': 'per 1K tokens'},
      'gpt-3.5-turbo': {
        'input': 0.0015,
        'output': 0.002,
        'unit': 'per 1K tokens'
      },
      'text-embedding-3-large': {'input': 0.00013, 'unit': 'per 1K tokens'},
      'text-embedding-3-small': {'input': 0.00002, 'unit': 'per 1K tokens'},
      'dall-e-3': {'price': 0.04, 'unit': 'per image (1024×1024)'},
      'dall-e-2': {'price': 0.02, 'unit': 'per image (1024×1024)'},
      'whisper-1': {'price': 0.006, 'unit': 'per minute'},
      'tts-1': {'price': 0.015, 'unit': 'per 1K characters'},
    };

    return pricingMap[modelId] ?? {'price': 'Unknown', 'unit': 'Unknown'};
  }
}
