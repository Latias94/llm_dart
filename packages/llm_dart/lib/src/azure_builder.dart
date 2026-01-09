import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_openai/provider_tools.dart';

/// Azure OpenAI-specific LLM builder with provider-specific configuration methods.
///
/// This wrapper is provided by the **umbrella** `llm_dart` package. Provider
/// subpackages do not depend on `llm_dart_builder`.
class AzureBuilder {
  final LLMBuilder _baseBuilder;

  AzureBuilder(this._baseBuilder);

  /// Set the Azure OpenAI `api-version` query parameter.
  AzureBuilder apiVersion(String apiVersion) {
    _baseBuilder.providerOption('azure', 'apiVersion', apiVersion);
    return this;
  }

  /// Use deployment-based URLs for Azure OpenAI requests.
  ///
  /// When enabled, requests use:
  /// `.../deployments/{deployment}{path}?api-version=...`
  AzureBuilder useDeploymentBasedUrls([bool enabled = true]) {
    _baseBuilder.providerOption('azure', 'useDeploymentBasedUrls', enabled);
    return this;
  }

  /// Use the OpenAI Responses API module for chat operations.
  ///
  /// When disabled, chat calls fall back to Chat Completions API.
  AzureBuilder useResponsesAPI([bool enabled = true]) {
    _baseBuilder.providerOption('azure', 'useResponsesAPI', enabled);
    return this;
  }

  /// Enable Azure/OpenAI web search preview tool (provider-native).
  AzureBuilder webSearchPreviewTool() {
    useResponsesAPI(true);
    _baseBuilder.providerTool(OpenAIProviderTools.webSearch());
    return this;
  }

  /// Enable Azure/OpenAI file search tool (provider-native).
  AzureBuilder fileSearchTool({List<String>? vectorStoreIds}) {
    useResponsesAPI(true);
    _baseBuilder.providerTool(
      OpenAIProviderTools.fileSearch(vectorStoreIds: vectorStoreIds),
    );
    return this;
  }

  /// Enable Azure/OpenAI code interpreter tool (provider-native).
  AzureBuilder codeInterpreterTool() {
    useResponsesAPI(true);
    _baseBuilder.providerTool(OpenAIProviderTools.codeInterpreter());
    return this;
  }

  /// Enable Azure/OpenAI image generation tool (provider-native).
  AzureBuilder imageGenerationTool() {
    useResponsesAPI(true);
    _baseBuilder.providerTool(OpenAIProviderTools.imageGeneration());
    return this;
  }
}

