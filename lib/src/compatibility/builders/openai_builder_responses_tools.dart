part of 'openai_builder.dart';

mixin _OpenAIBuilderResponsesTools {
  LegacyBuilderProviderOptionWriter get _providerOptions;

  /// Enables the Responses API instead of Chat Completions API.
  OpenAIBuilder useResponsesAPI([bool use = true]) {
    _providerOptions.set(LegacyExtensionKeys.useResponsesApi, use);
    return this as OpenAIBuilder;
  }

  /// Sets previous response ID for chaining responses.
  OpenAIBuilder previousResponseId(String responseId) {
    _providerOptions.set(
      LegacyExtensionKeys.previousResponseId,
      responseId,
    );
    return this as OpenAIBuilder;
  }

  /// Adds web search built-in tool.
  OpenAIBuilder webSearchTool() {
    final tools = _getBuiltInTools();
    tools.add(OpenAIBuiltInTools.webSearch());
    _providerOptions.set(LegacyExtensionKeys.builtInTools, tools);
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
    _providerOptions.set(LegacyExtensionKeys.builtInTools, tools);
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
    _providerOptions.set(LegacyExtensionKeys.builtInTools, tools);
    return this as OpenAIBuilder;
  }

  List<OpenAIBuiltInTool> _getBuiltInTools() {
    final existingTools = _providerOptions.get<List<OpenAIBuiltInTool>>(
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
    _providerOptions.set(
      LegacyExtensionKeys.webSearchConfig,
      CompatWebSearchPresets.openai(
        contextSize: contextSize,
      ),
    );
    return this as OpenAIBuilder;
  }
}
