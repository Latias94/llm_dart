enum OpenAIBuiltInToolType {
  webSearch,
  fileSearch,
  computerUse,
}

abstract interface class OpenAIBuiltInTool {
  OpenAIBuiltInToolType get type;

  Map<String, Object?> toJson();
}

final class OpenAIWebSearchTool implements OpenAIBuiltInTool {
  const OpenAIWebSearchTool();

  @override
  OpenAIBuiltInToolType get type => OpenAIBuiltInToolType.webSearch;

  @override
  Map<String, Object?> toJson() {
    return const {
      'type': 'web_search_preview',
    };
  }
}

final class OpenAIFileSearchTool implements OpenAIBuiltInTool {
  final List<String>? vectorStoreIds;
  final Map<String, Object?>? parameters;

  const OpenAIFileSearchTool({
    this.vectorStoreIds,
    this.parameters,
  });

  @override
  OpenAIBuiltInToolType get type => OpenAIBuiltInToolType.fileSearch;

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'file_search',
      if (vectorStoreIds != null && vectorStoreIds!.isNotEmpty)
        'vector_store_ids': List<String>.unmodifiable(vectorStoreIds!),
      if (parameters != null) ...parameters!,
    };
  }
}

final class OpenAIComputerUseTool implements OpenAIBuiltInTool {
  final int displayWidth;
  final int displayHeight;
  final String environment;
  final Map<String, Object?>? parameters;

  const OpenAIComputerUseTool({
    required this.displayWidth,
    required this.displayHeight,
    required this.environment,
    this.parameters,
  });

  @override
  OpenAIBuiltInToolType get type => OpenAIBuiltInToolType.computerUse;

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'computer_use_preview',
      'display_width': displayWidth,
      'display_height': displayHeight,
      'environment': environment,
      if (parameters != null) ...parameters!,
    };
  }
}

final class OpenAIBuiltInTools {
  static OpenAIWebSearchTool webSearch() => const OpenAIWebSearchTool();

  static OpenAIFileSearchTool fileSearch({
    List<String>? vectorStoreIds,
    Map<String, Object?>? parameters,
  }) {
    return OpenAIFileSearchTool(
      vectorStoreIds: vectorStoreIds,
      parameters: parameters,
    );
  }

  static OpenAIComputerUseTool computerUse({
    required int displayWidth,
    required int displayHeight,
    required String environment,
    Map<String, Object?>? parameters,
  }) {
    return OpenAIComputerUseTool(
      displayWidth: displayWidth,
      displayHeight: displayHeight,
      environment: environment,
      parameters: parameters,
    );
  }
}
