/// OpenAI Built-in Tools for Responses API
///
/// This module defines the built-in tools available in OpenAI's Responses API,
/// including web search, file search, and computer use.
library;

import 'web_search_context_size.dart';

/// OpenAI built-in tool types
enum OpenAIBuiltInToolType {
  /// Web search preview tool (`web_search_preview`) for real-time information retrieval.
  ///
  /// Note: This enum value historically mapped to `web_search_preview`.
  webSearch,

  /// Web search tool (`web_search`) for real-time information retrieval.
  webSearchFull,

  /// File search tool for document retrieval from vector stores
  fileSearch,

  /// Computer use tool for browser and system automation
  computerUse,

  /// Code interpreter tool (`code_interpreter`).
  codeInterpreter,

  /// Image generation tool (`image_generation`).
  imageGeneration,

  /// MCP tool (`mcp`).
  mcp,

  /// Apply patch tool (`apply_patch`).
  applyPatch,

  /// Shell tool (`shell`).
  shell,

  /// Local shell tool (`local_shell`).
  localShell,
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
/// Powered by the same model used for ChatGPT search.
class OpenAIWebSearchTool implements OpenAIBuiltInTool {
  @override
  OpenAIBuiltInToolType get type => OpenAIBuiltInToolType.webSearch;

  /// Optional context size for search results (provider-native).
  ///
  /// OpenAI supports `search_context_size` for the `web_search_preview` tool.
  final OpenAIWebSearchContextSize? searchContextSize;

  const OpenAIWebSearchTool({this.searchContextSize});

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'web_search_preview',
      if (searchContextSize != null)
        'search_context_size': searchContextSize!.apiValue,
    };
  }

  @override
  String toString() =>
      'OpenAIWebSearchTool(searchContextSize: $searchContextSize)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OpenAIWebSearchTool &&
            other.searchContextSize == searchContextSize;
  }

  @override
  int get hashCode => Object.hash(type, searchContextSize);
}

/// Web search built-in tool (`web_search`).
///
/// This is distinct from [OpenAIWebSearchTool] which maps to `web_search_preview`.
class OpenAIWebSearchFullTool implements OpenAIBuiltInTool {
  @override
  OpenAIBuiltInToolType get type => OpenAIBuiltInToolType.webSearchFull;

  /// Optional domain allowlist, mapped to `filters.allowed_domains`.
  final List<String>? allowedDomains;

  /// Optional `external_web_access` flag.
  final bool? externalWebAccess;

  /// Optional context size for search results.
  final OpenAIWebSearchContextSize? searchContextSize;

  /// Optional `user_location` object (provider-specific shape).
  final Map<String, dynamic>? userLocation;

  /// Additional parameters for web search.
  final Map<String, dynamic>? parameters;

  const OpenAIWebSearchFullTool({
    this.allowedDomains,
    this.externalWebAccess,
    this.searchContextSize,
    this.userLocation,
    this.parameters,
  });

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'type': 'web_search',
      if (allowedDomains != null && allowedDomains!.isNotEmpty)
        'filters': {'allowed_domains': allowedDomains},
      if (externalWebAccess != null) 'external_web_access': externalWebAccess,
      if (searchContextSize != null)
        'search_context_size': searchContextSize!.apiValue,
      if (userLocation != null && userLocation!.isNotEmpty)
        'user_location': userLocation,
    };

    if (parameters != null && parameters!.isNotEmpty) {
      json.addAll(parameters!);
    }

    return json;
  }

  @override
  String toString() => 'OpenAIWebSearchFullTool('
      'allowedDomains: $allowedDomains, '
      'externalWebAccess: $externalWebAccess, '
      'searchContextSize: $searchContextSize, '
      'userLocation: $userLocation, '
      'parameters: $parameters'
      ')';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OpenAIWebSearchFullTool &&
        other.allowedDomains == allowedDomains &&
        other.externalWebAccess == externalWebAccess &&
        other.searchContextSize == searchContextSize &&
        other.userLocation == userLocation &&
        other.parameters == parameters;
  }

  @override
  int get hashCode => Object.hash(
        type,
        allowedDomains,
        externalWebAccess,
        searchContextSize,
        userLocation,
        parameters,
      );
}

/// File search built-in tool
///
/// Enables the model to search through documents in vector stores.
/// Supports multiple file types, query optimization, and metadata filtering.
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
/// Enables the model to interact with computers through mouse and keyboard actions.
/// Currently in research preview with limited availability.
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

/// Code interpreter built-in tool (`code_interpreter`).
class OpenAICodeInterpreterTool implements OpenAIBuiltInTool {
  @override
  OpenAIBuiltInToolType get type => OpenAIBuiltInToolType.codeInterpreter;

  /// Optional container configuration.
  ///
  /// Allowed shapes depend on the OpenAI API. This package intentionally keeps
  /// it flexible.
  final dynamic container;

  /// Additional parameters for code interpreter.
  final Map<String, dynamic>? parameters;

  const OpenAICodeInterpreterTool({
    this.container,
    this.parameters,
  });

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'type': 'code_interpreter',
      if (container != null) 'container': container,
    };

    if (parameters != null && parameters!.isNotEmpty) {
      json.addAll(parameters!);
    }

    return json;
  }

  @override
  String toString() =>
      'OpenAICodeInterpreterTool(container: $container, parameters: $parameters)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OpenAICodeInterpreterTool &&
        other.container == container &&
        other.parameters == parameters;
  }

  @override
  int get hashCode => Object.hash(type, container, parameters);
}

/// Image generation built-in tool (`image_generation`).
class OpenAIImageGenerationTool implements OpenAIBuiltInTool {
  @override
  OpenAIBuiltInToolType get type => OpenAIBuiltInToolType.imageGeneration;

  /// Additional parameters for image generation.
  final Map<String, dynamic>? parameters;

  const OpenAIImageGenerationTool({this.parameters});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'image_generation',
        ...?parameters,
      };

  @override
  String toString() => 'OpenAIImageGenerationTool(parameters: $parameters)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OpenAIImageGenerationTool && other.parameters == parameters;
  }

  @override
  int get hashCode => Object.hash(type, parameters);
}

/// MCP built-in tool (`mcp`).
class OpenAIMCPTool implements OpenAIBuiltInTool {
  @override
  OpenAIBuiltInToolType get type => OpenAIBuiltInToolType.mcp;

  /// Additional parameters for MCP tool.
  final Map<String, dynamic>? parameters;

  const OpenAIMCPTool({this.parameters});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'mcp',
        ...?parameters,
      };

  @override
  String toString() => 'OpenAIMCPTool(parameters: $parameters)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OpenAIMCPTool && other.parameters == parameters;
  }

  @override
  int get hashCode => Object.hash(type, parameters);
}

/// Apply patch built-in tool (`apply_patch`).
class OpenAIApplyPatchTool implements OpenAIBuiltInTool {
  @override
  OpenAIBuiltInToolType get type => OpenAIBuiltInToolType.applyPatch;

  const OpenAIApplyPatchTool();

  @override
  Map<String, dynamic> toJson() => const {'type': 'apply_patch'};

  @override
  String toString() => 'OpenAIApplyPatchTool()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OpenAIApplyPatchTool && other.type == type;

  @override
  int get hashCode => Object.hashAll([type]);
}

/// Shell built-in tool (`shell`).
class OpenAIShellTool implements OpenAIBuiltInTool {
  @override
  OpenAIBuiltInToolType get type => OpenAIBuiltInToolType.shell;

  const OpenAIShellTool();

  @override
  Map<String, dynamic> toJson() => const {'type': 'shell'};

  @override
  String toString() => 'OpenAIShellTool()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is OpenAIShellTool && other.type == type;

  @override
  int get hashCode => Object.hashAll([type]);
}

/// Local shell built-in tool (`local_shell`).
class OpenAILocalShellTool implements OpenAIBuiltInTool {
  @override
  OpenAIBuiltInToolType get type => OpenAIBuiltInToolType.localShell;

  const OpenAILocalShellTool();

  @override
  Map<String, dynamic> toJson() => const {'type': 'local_shell'};

  @override
  String toString() => 'OpenAILocalShellTool()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OpenAILocalShellTool && other.type == type;

  @override
  int get hashCode => Object.hashAll([type]);
}

/// Convenience factory methods for creating built-in tools
class OpenAIBuiltInTools {
  /// Create a web search tool
  static OpenAIWebSearchTool webSearch({
    OpenAIWebSearchContextSize? contextSize,
  }) =>
      OpenAIWebSearchTool(searchContextSize: contextSize);

  /// Create a web search tool (`web_search`).
  static OpenAIWebSearchFullTool webSearchFull({
    List<String>? allowedDomains,
    bool? externalWebAccess,
    OpenAIWebSearchContextSize? contextSize,
    Map<String, dynamic>? userLocation,
    Map<String, dynamic>? parameters,
  }) =>
      OpenAIWebSearchFullTool(
        allowedDomains: allowedDomains,
        externalWebAccess: externalWebAccess,
        searchContextSize: contextSize,
        userLocation: userLocation,
        parameters: parameters,
      );

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

  /// Create a code interpreter tool.
  static OpenAICodeInterpreterTool codeInterpreter({
    dynamic container,
    Map<String, dynamic>? parameters,
  }) =>
      OpenAICodeInterpreterTool(container: container, parameters: parameters);

  /// Create an image generation tool.
  static OpenAIImageGenerationTool imageGeneration({
    Map<String, dynamic>? parameters,
  }) =>
      OpenAIImageGenerationTool(parameters: parameters);

  /// Create an MCP tool.
  static OpenAIMCPTool mcp({Map<String, dynamic>? parameters}) =>
      OpenAIMCPTool(parameters: parameters);

  /// Create an apply_patch tool.
  static OpenAIApplyPatchTool applyPatch() => const OpenAIApplyPatchTool();

  /// Create a shell tool.
  static OpenAIShellTool shell() => const OpenAIShellTool();

  /// Create a local_shell tool.
  static OpenAILocalShellTool localShell() => const OpenAILocalShellTool();
}
