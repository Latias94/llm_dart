part of 'openai_builder.dart';

mixin _OpenAIBuilderResponsesTools {
  LLMBuilder get _baseBuilder;

  void _setOpenAIProviderOption(String key, dynamic value);

  /// Enables the Responses API instead of Chat Completions API.
  OpenAIBuilder useResponsesAPI([bool use = true]) {
    _setOpenAIProviderOption(LegacyExtensionKeys.useResponsesApi, use);
    return this as OpenAIBuilder;
  }

  /// Sets previous response ID for chaining responses.
  OpenAIBuilder previousResponseId(String responseId) {
    _setOpenAIProviderOption(
      LegacyExtensionKeys.previousResponseId,
      responseId,
    );
    return this as OpenAIBuilder;
  }

  /// Adds web search built-in tool.
  OpenAIBuilder webSearchTool() {
    final tools = _getBuiltInTools();
    tools.add(OpenAIBuiltInTools.webSearch());
    _setOpenAIProviderOption(LegacyExtensionKeys.builtInTools, tools);
    return this as OpenAIBuilder;
  }

  /// Adds file search built-in tool.
  OpenAIBuilder fileSearchTool({
    List<String>? vectorStoreIds,
    Map<String, dynamic>? parameters,
  }) {
    final tools = _getBuiltInTools();
    tools.add(
      OpenAIBuiltInTools.fileSearch(
        vectorStoreIds: vectorStoreIds,
        parameters: parameters,
      ),
    );
    _setOpenAIProviderOption(LegacyExtensionKeys.builtInTools, tools);
    return this as OpenAIBuilder;
  }

  /// Adds computer use built-in tool.
  OpenAIBuilder computerUseTool({
    required int displayWidth,
    required int displayHeight,
    required String environment,
    Map<String, dynamic>? parameters,
  }) {
    final tools = _getBuiltInTools();
    tools.add(
      OpenAIBuiltInTools.computerUse(
        displayWidth: displayWidth,
        displayHeight: displayHeight,
        environment: environment,
        parameters: parameters,
      ),
    );
    _setOpenAIProviderOption(LegacyExtensionKeys.builtInTools, tools);
    return this as OpenAIBuilder;
  }

  List<OpenAIBuiltInTool> _getBuiltInTools() {
    final existingTools = getLegacyProviderOption<List<OpenAIBuiltInTool>>(
      _baseBuilder.currentConfig,
      LegacyProviderOptionNamespaces.openai,
      LegacyExtensionKeys.builtInTools,
    );
    return existingTools != null
        ? List.from(existingTools)
        : <OpenAIBuiltInTool>[];
  }

  /// Configures web search for OpenAI models.
  OpenAIBuilder webSearch({
    WebSearchContextSize contextSize = WebSearchContextSize.medium,
  }) {
    _setOpenAIProviderOption(
      LegacyExtensionKeys.webSearchConfig,
      CompatWebSearchPresets.openai(
        contextSize: contextSize,
      ),
    );
    return this as OpenAIBuilder;
  }
}
