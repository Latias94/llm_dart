import '../../../../core/capability.dart';
import '../../../../core/llm_error.dart';
import '../../../../models/chat_models.dart';
import 'client.dart';
import '../../../../providers/openai/config.dart';

part 'openai_models_fetch_support.dart';
part 'openai_models_pricing_support.dart';
part 'openai_models_query_support.dart';

/// OpenAI Model Listing capability implementation
///
/// This module handles model listing and information retrieval
/// for OpenAI providers.
class OpenAIModels implements ModelListingCapability {
  final OpenAIClient client;
  final OpenAIConfig config;
  late final _OpenAIModelsFetchSupport _fetchSupport =
      _OpenAIModelsFetchSupport(client);
  late final _OpenAIModelsQuerySupport _querySupport =
      _OpenAIModelsQuerySupport(
    listModels: () => models(),
    getModel: getModel,
  );
  final _OpenAIModelsPricingSupport _pricingSupport =
      const _OpenAIModelsPricingSupport();

  OpenAIModels(this.client, this.config);

  @override
  Future<List<AIModel>> models({TransportCancellation? cancelToken}) {
    return _fetchSupport.models(cancelToken: cancelToken);
  }

  /// Get a specific model by ID
  Future<AIModel?> getModel(String modelId) {
    return _fetchSupport.getModel(modelId);
  }

  /// Check if a model exists and is accessible
  Future<bool> modelExists(String modelId) {
    return _querySupport.modelExists(modelId);
  }

  /// Get models by owner
  Future<List<AIModel>> getModelsByOwner(String owner) {
    return _querySupport.getModelsByOwner(owner);
  }

  /// Get OpenAI models only
  Future<List<AIModel>> getOpenAIModels() {
    return _querySupport.getOpenAIModels();
  }

  /// Get fine-tuned models
  Future<List<AIModel>> getFineTunedModels() {
    return _querySupport.getFineTunedModels();
  }

  /// Get models suitable for chat
  Future<List<AIModel>> getChatModels() {
    return _querySupport.getChatModels();
  }

  /// Get models suitable for embeddings
  Future<List<AIModel>> getEmbeddingModels() {
    return _querySupport.getEmbeddingModels();
  }

  /// Get models suitable for image generation
  Future<List<AIModel>> getImageModels() {
    return _querySupport.getImageModels();
  }

  /// Get models suitable for audio/speech
  Future<List<AIModel>> getAudioModels() {
    return _querySupport.getAudioModels();
  }

  /// Check if a model supports a specific capability
  Future<bool> modelSupportsCapability(
    String modelId,
    String capability,
  ) {
    return _querySupport.modelSupportsCapability(modelId, capability);
  }

  /// Get recommended model for a specific use case
  Future<AIModel?> getRecommendedModel(String useCase) {
    return _querySupport.getRecommendedModel(useCase);
  }

  /// Get model pricing information (if available)
  Map<String, dynamic> getModelPricing(String modelId) {
    return _pricingSupport.getModelPricing(modelId);
  }
}
