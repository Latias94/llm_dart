part of 'models.dart';

final class _OpenAIModelsQuerySupport {
  final Future<List<AIModel>> Function() listModels;
  final Future<AIModel?> Function(String modelId) getModel;

  const _OpenAIModelsQuerySupport({
    required this.listModels,
    required this.getModel,
  });

  Future<bool> modelExists(String modelId) async {
    final model = await getModel(modelId);
    return model != null;
  }

  Future<List<AIModel>> getModelsByOwner(String owner) async {
    final allModels = await listModels();
    return allModels.where((model) => model.ownedBy == owner).toList();
  }

  Future<List<AIModel>> getOpenAIModels() async {
    return getModelsByOwner('openai');
  }

  Future<List<AIModel>> getFineTunedModels() async {
    final allModels = await listModels();
    return allModels
        .where(
          (model) => model.ownedBy != 'openai' && model.ownedBy != 'system',
        )
        .toList();
  }

  Future<List<AIModel>> getChatModels() async {
    final allModels = await listModels();
    return allModels
        .where(
          (model) =>
              model.id.contains('gpt') ||
              model.id.contains('chat') ||
              model.id.contains('turbo'),
        )
        .toList();
  }

  Future<List<AIModel>> getEmbeddingModels() async {
    final allModels = await listModels();
    return allModels
        .where(
          (model) => model.id.contains('embedding') || model.id.contains('ada'),
        )
        .toList();
  }

  Future<List<AIModel>> getImageModels() async {
    final allModels = await listModels();
    return allModels
        .where(
          (model) => model.id.contains('dall-e') || model.id.contains('dalle'),
        )
        .toList();
  }

  Future<List<AIModel>> getAudioModels() async {
    final allModels = await listModels();
    return allModels
        .where(
          (model) => model.id.contains('whisper') || model.id.contains('tts'),
        )
        .toList();
  }

  Future<bool> modelSupportsCapability(
    String modelId,
    String capability,
  ) async {
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

  Future<AIModel?> getRecommendedModel(String useCase) async {
    final allModels = await listModels();

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
}
