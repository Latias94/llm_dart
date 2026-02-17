import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_azure/provider_tools.dart';

/// Azure OpenAI-specific LLM builder with provider-specific configuration methods.
///
/// This wrapper is provided by the **umbrella** `llm_dart` package. Provider
/// subpackages do not depend on `llm_dart_builder`.
class AzureBuilder {
  final LLMBuilder _baseBuilder;

  AzureBuilder(this._baseBuilder);

  void _assertResponsesProviderSelected() {
    if (_baseBuilder.providerId == 'azure') return;
    throw UnsupportedCapabilityError(
      'This Azure OpenAI feature requires the Responses API. '
      'Use providerId "azure" (or call .azure()) instead of "${_baseBuilder.providerId}".',
    );
  }

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

  /// Enable Azure/OpenAI web search preview tool (provider-native).
  AzureBuilder webSearchPreviewTool() {
    _assertResponsesProviderSelected();
    _baseBuilder.providerTool(AzureOpenAIProviderTools.webSearchPreview());
    return this;
  }

  /// Enable Azure/OpenAI file search tool (provider-native).
  AzureBuilder fileSearchTool({List<String>? vectorStoreIds}) {
    _assertResponsesProviderSelected();
    _baseBuilder.providerTool(
      AzureOpenAIProviderTools.fileSearch(vectorStoreIds: vectorStoreIds),
    );
    return this;
  }

  /// Enable Azure/OpenAI code interpreter tool (provider-native).
  AzureBuilder codeInterpreterTool() {
    _assertResponsesProviderSelected();
    _baseBuilder.providerTool(AzureOpenAIProviderTools.codeInterpreter());
    return this;
  }

  /// Enable Azure/OpenAI image generation tool (provider-native).
  AzureBuilder imageGenerationTool() {
    _assertResponsesProviderSelected();
    _baseBuilder.providerTool(AzureOpenAIProviderTools.imageGeneration());
    return this;
  }
}
