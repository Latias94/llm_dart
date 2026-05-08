part of 'openai_builder.dart';

mixin _OpenAIBuilderBuilds {
  LLMBuilder get _baseBuilder;

  OpenAIBuilder useResponsesAPI([bool use = true]);

  /// Builds and returns a configured LLM provider instance.
  Future<ChatCapability> build() async {
    return _baseBuilder.build();
  }

  /// Builds a provider with AudioCapability.
  Future<AudioCapability> buildAudio() async {
    return _baseBuilder.buildAudio();
  }

  /// Builds a provider with ImageGenerationCapability.
  Future<ImageGenerationCapability> buildImageGeneration() async {
    return _baseBuilder.buildImageGeneration();
  }

  /// Builds a provider with EmbeddingCapability.
  Future<EmbeddingCapability> buildEmbedding() async {
    return _baseBuilder.buildEmbedding();
  }

  /// Builds a provider with FileManagementCapability.
  Future<FileManagementCapability> buildFileManagement() async {
    return _baseBuilder.buildFileManagement();
  }

  /// Builds a provider with ModerationCapability.
  Future<ModerationCapability> buildModeration() async {
    return _baseBuilder.buildModeration();
  }

  /// Builds a provider with OpenAI assistant capability.
  Future<AssistantCapability> buildAssistant() async {
    return _baseBuilder.buildAssistant();
  }

  /// Builds a provider with ModelListingCapability.
  Future<ModelListingCapability> buildModelListing() async {
    return _baseBuilder.buildModelListing();
  }

  /// Builds an OpenAI provider with Responses API enabled.
  Future<OpenAIProvider> buildOpenAIResponses() async {
    final options = legacyProviderOptionView(
      _baseBuilder.currentConfig,
      LegacyProviderOptionNamespaces.openai,
    );
    final isResponsesApiEnabled =
        options.get<bool>(LegacyExtensionKeys.useResponsesApi) ?? false;
    if (!isResponsesApiEnabled) {
      useResponsesAPI(true);
    }

    final provider = await build();

    if (provider is! OpenAIProvider) {
      throw StateError(
        'Expected OpenAIProvider but got ${provider.runtimeType}. '
        'This should not happen when using buildOpenAIResponses().',
      );
    }

    if (provider.responses == null) {
      throw StateError(
        'OpenAI Responses API not properly initialized. '
        'This should not happen when using buildOpenAIResponses().',
      );
    }

    return provider;
  }
}
