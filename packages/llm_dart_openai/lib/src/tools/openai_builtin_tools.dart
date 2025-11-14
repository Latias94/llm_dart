/// OpenAI Built-in Tools for Responses API
///
/// This module defines the built-in tools available in OpenAI's Responses API,
/// including web search, file search, and computer use.
library;

/// OpenAI built-in tool types
enum OpenAIBuiltInToolType {
  /// Web search tool for real-time information retrieval
  webSearch,

  /// File search tool for document retrieval from vector stores
  fileSearch,

  /// Computer use tool for browser and system automation
  computerUse,
}

/// Base class for OpenAI built-in tools
abstract class OpenAIBuiltInTool {
  /// The type of built-in tool
  OpenAIBuiltInToolType get type;

  /// Convert tool to JSON format for API requests
  Map<String, dynamic> toJson();
}

/// Web search built-in tool
///
/// Enables the model to search the web for real-time information.
class OpenAIWebSearchTool implements OpenAIBuiltInTool {
  @override
  OpenAIBuiltInToolType get type => OpenAIBuiltInToolType.webSearch;

  const OpenAIWebSearchTool();

  @override
  Map<String, dynamic> toJson() {
    return {'type': 'web_search_preview'};
  }

  @override
  String toString() => 'OpenAIWebSearchTool()';

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is OpenAIWebSearchTool;
  }

  @override
  int get hashCode => type.hashCode;
}

/// File search built-in tool
///
/// Enables the model to search through documents in vector stores.
class OpenAIFileSearchTool implements OpenAIBuiltInTool {
  /// Vector store IDs to search through
  final List<String>? vectorStoreIds;

  /// Additional parameters for file search
  final Map<String, dynamic>? parameters;

  @override
  OpenAIBuiltInToolType get type => OpenAIBuiltInToolType.fileSearch;

  const OpenAIFileSearchTool({
    this.vectorStoreIds,
    this.parameters,
  });

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'type': 'file_search'};

    if (vectorStoreIds != null && vectorStoreIds!.isNotEmpty) {
      json['vector_store_ids'] = vectorStoreIds;
    }

    if (parameters != null) {
      json.addAll(parameters!);
    }

    return json;
  }

  @override
  String toString() {
    return 'OpenAIFileSearchTool(vectorStoreIds: $vectorStoreIds, parameters: $parameters)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OpenAIFileSearchTool &&
        other.vectorStoreIds == vectorStoreIds &&
        other.parameters == parameters;
  }

  @override
  int get hashCode => Object.hash(vectorStoreIds, parameters);
}

/// Computer use built-in tool
///
/// Enables the model to interact with computers through mouse and keyboard
/// actions.
class OpenAIComputerUseTool implements OpenAIBuiltInTool {
  /// Display width for computer use
  final int displayWidth;

  /// Display height for computer use
  final int displayHeight;

  /// Environment type (e.g., 'browser', 'desktop')
  final String environment;

  /// Additional parameters for computer use
  final Map<String, dynamic>? parameters;

  @override
  OpenAIBuiltInToolType get type => OpenAIBuiltInToolType.computerUse;

  const OpenAIComputerUseTool({
    required this.displayWidth,
    required this.displayHeight,
    required this.environment,
    this.parameters,
  });

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'type': 'computer_use_preview',
      'display_width': displayWidth,
      'display_height': displayHeight,
      'environment': environment,
    };

    if (parameters != null) {
      json.addAll(parameters!);
    }

    return json;
  }

  @override
  String toString() {
    return 'OpenAIComputerUseTool(displayWidth: $displayWidth, displayHeight: $displayHeight, environment: $environment, parameters: $parameters)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OpenAIComputerUseTool &&
        other.displayWidth == displayWidth &&
        other.displayHeight == displayHeight &&
        other.environment == environment &&
        other.parameters == parameters;
  }

  @override
  int get hashCode =>
      Object.hash(displayWidth, displayHeight, environment, parameters);
}

/// Convenience factory methods for creating built-in tools
class OpenAIBuiltInTools {
  /// Create a web search tool
  static OpenAIWebSearchTool webSearch() => const OpenAIWebSearchTool();

  /// Create a file search tool
  static OpenAIFileSearchTool fileSearch({
    List<String>? vectorStoreIds,
    Map<String, dynamic>? parameters,
  }) =>
      OpenAIFileSearchTool(
        vectorStoreIds: vectorStoreIds,
        parameters: parameters,
      );

  /// Create a computer use tool
  static OpenAIComputerUseTool computerUse({
    required int displayWidth,
    required int displayHeight,
    required String environment,
    Map<String, dynamic>? parameters,
  }) =>
      OpenAIComputerUseTool(
        displayWidth: displayWidth,
        displayHeight: displayHeight,
        environment: environment,
        parameters: parameters,
      );
}
