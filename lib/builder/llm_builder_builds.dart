part of 'llm_builder.dart';

extension LLMBuilderBuilds on LLMBuilder {
  /// Builds and returns a configured LLM provider instance
  Future<ChatCapability> build() async {
    if (_providerId == null) {
      throw const GenericError('No provider specified');
    }

    final compatProvider = tryCreateCompatProvider(
      providerId: _providerId!,
      config: _config,
    );
    if (compatProvider != null) {
      return compatProvider;
    }

    return LLMProviderRegistry.createProvider(_providerId!, _config);
  }

  /// Builds a provider with AudioCapability
  Future<AudioCapability> buildAudio() {
    return _buildCapability<AudioCapability>(
      unsupportedMessage:
          'Provider "$_providerId" does not support audio capabilities. '
          'Supported providers: OpenAI, ElevenLabs',
    );
  }

  /// Builds a provider with ImageGenerationCapability
  Future<ImageGenerationCapability> buildImageGeneration() {
    return _buildCapability<ImageGenerationCapability>(
      unsupportedMessage:
          'Provider "$_providerId" does not support image generation capabilities. '
          'Supported providers: OpenAI (DALL-E)',
    );
  }

  /// Builds a provider with EmbeddingCapability
  Future<EmbeddingCapability> buildEmbedding() {
    return _buildCapability<EmbeddingCapability>(
      unsupportedMessage:
          'Provider "$_providerId" does not support embedding capabilities. '
          'Supported providers: OpenAI, Google, DeepSeek',
    );
  }

  /// Builds a provider with FileManagementCapability
  Future<FileManagementCapability> buildFileManagement() {
    return _buildCapability<FileManagementCapability>(
      unsupportedMessage:
          'Provider "$_providerId" does not support file management capabilities. '
          'Supported providers: OpenAI, Anthropic',
    );
  }

  /// Builds a provider with ModerationCapability
  Future<ModerationCapability> buildModeration() {
    return _buildCapability<ModerationCapability>(
      unsupportedMessage:
          'Provider "$_providerId" does not support moderation capabilities. '
          'Supported providers: OpenAI',
    );
  }

  /// Builds a provider with AssistantCapability
  Future<AssistantCapability> buildAssistant() {
    return _buildCapability<AssistantCapability>(
      unsupportedMessage:
          'Provider "$_providerId" does not support assistant capabilities. '
          'Supported providers: OpenAI',
    );
  }

  /// Builds a provider with ModelListingCapability
  Future<ModelListingCapability> buildModelListing() {
    return _buildCapability<ModelListingCapability>(
      unsupportedMessage:
          'Provider "$_providerId" does not support model listing capabilities. '
          'Supported providers: OpenAI, Anthropic, DeepSeek, Ollama',
    );
  }
}
