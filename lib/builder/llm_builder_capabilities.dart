part of 'llm_builder.dart';

/// Capability factory helpers for [LLMBuilder].
///
/// These methods build providers or adapters that implement specific
/// capability interfaces (audio, image generation, embeddings, reranking,
/// files, moderation, assistants, model listing).
extension LLMBuilderCapabilities on LLMBuilder {
  /// Builds a provider with [AudioCapability].
  ///
  /// Throws [UnsupportedCapabilityError] if the provider doesn't support audio.
  Future<AudioCapability> buildAudio() async {
    if (_providerId == null) {
      throw const GenericError('No provider specified');
    }

    try {
      // Use the typed factory helper so that audio-only providers like
      // ElevenLabs can be created without pretending to support chat.
      return LLMProviderRegistry.createProviderTyped<AudioCapability>(
        _providerId!,
        _config,
      );
    } on UnsupportedCapabilityError {
      throw UnsupportedCapabilityError('Provider "$_providerId" '
          'does not support audio capabilities. '
          'Supported providers include OpenAI (TTS) and ElevenLabs.');
    }
  }

  /// Builds a provider with [ImageGenerationCapability].
  ///
  /// Throws [UnsupportedCapabilityError] if image generation is unsupported.
  Future<ImageGenerationCapability> buildImageGeneration() async {
    final provider = await build();
    if (provider is! ImageGenerationCapability) {
      throw UnsupportedCapabilityError('Provider "$_providerId" '
          'does not support image generation capabilities. '
          'Supported providers: OpenAI (DALL-E)');
    }
    return provider as ImageGenerationCapability;
  }

  /// Builds a provider with [EmbeddingCapability].
  ///
  /// Throws [UnsupportedCapabilityError] if embeddings are unsupported.
  Future<EmbeddingCapability> buildEmbedding() async {
    final provider = await build();
    if (provider is! EmbeddingCapability) {
      throw UnsupportedCapabilityError('Provider "$_providerId" '
          'does not support embedding capabilities. '
          'Supported providers: OpenAI, Google, DeepSeek');
    }
    return provider as EmbeddingCapability;
  }

  /// Builds a provider with embedding middlewares applied.
  ///
  /// Wraps the underlying [EmbeddingCapability] in
  /// [_EmbeddingMiddlewareWrappedProvider] when middlewares are present.
  Future<EmbeddingCapability> buildEmbeddingWithMiddleware() async {
    final provider = await build();
    if (provider is! EmbeddingCapability) {
      throw UnsupportedCapabilityError('Provider "$_providerId" '
          'does not support embedding capabilities. '
          'Supported providers: OpenAI, Google, DeepSeek');
    }

    if (_embeddingMiddlewares.isEmpty) {
      return provider as EmbeddingCapability;
    }

    return _EmbeddingMiddlewareWrappedProvider(
      provider as EmbeddingCapability,
      _providerId ?? 'unknown',
      _config,
      List<EmbeddingMiddleware>.from(_embeddingMiddlewares),
    );
  }

  /// Builds a semantic reranking capability.
  ///
  /// Implemented on top of [EmbeddingCapability] as an adapter that
  /// computes cosine similarity between query and document embeddings.
  Future<RerankingCapability> buildReranker() async {
    final embeddingProvider = await buildEmbedding();
    return _EmbeddingRerankingCapability(embeddingProvider);
  }

  /// Builds a provider with [FileManagementCapability].
  ///
  /// Throws [UnsupportedCapabilityError] if file management is unsupported.
  Future<FileManagementCapability> buildFileManagement() async {
    final provider = await build();
    if (provider is! FileManagementCapability) {
      throw UnsupportedCapabilityError('Provider "$_providerId" '
          'does not support file management capabilities. '
          'Supported providers: OpenAI, Anthropic');
    }
    return provider as FileManagementCapability;
  }

  /// Builds a provider with [ModerationCapability].
  ///
  /// Throws [UnsupportedCapabilityError] if moderation is unsupported.
  Future<ModerationCapability> buildModeration() async {
    final provider = await build();
    if (provider is! ModerationCapability) {
      throw UnsupportedCapabilityError('Provider "$_providerId" '
          'does not support moderation capabilities. '
          'Supported providers: OpenAI');
    }
    return provider as ModerationCapability;
  }

  /// Builds a provider with [AssistantCapability].
  ///
  /// Throws [UnsupportedCapabilityError] if assistants are unsupported.
  Future<AssistantCapability> buildAssistant() async {
    final provider = await build();
    if (provider is! AssistantCapability) {
      throw UnsupportedCapabilityError('Provider "$_providerId" '
          'does not support assistant capabilities. '
          'Supported providers: OpenAI');
    }
    return provider as AssistantCapability;
  }

  /// Builds an assistant-capable provider with chat middlewares applied.
  Future<AssistantCapability> buildAssistantWithMiddleware() async {
    final provider = await buildWithMiddleware();
    if (provider is! AssistantCapability) {
      throw UnsupportedCapabilityError('Provider "$_providerId" '
          'does not support assistant capabilities. '
          'Supported providers: OpenAI');
    }
    return provider as AssistantCapability;
  }

  /// Builds a provider with [ModelListingCapability].
  ///
  /// Throws [UnsupportedCapabilityError] if model listing is unsupported.
  Future<ModelListingCapability> buildModelListing() async {
    final provider = await build();
    if (provider is! ModelListingCapability) {
      throw UnsupportedCapabilityError('Provider "$_providerId" '
          'does not support model listing capabilities. '
          'Supported providers: OpenAI, Anthropic, DeepSeek, Ollama');
    }
    return provider as ModelListingCapability;
  }
}
