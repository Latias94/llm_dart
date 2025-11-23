/// OpenAI Built-in Tools for Responses API
///
/// This module defines the built-in tools available in OpenAI's Responses API,
/// including web search, file search, and computer use.
library;

import 'package:llm_dart_core/llm_dart_core.dart';

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
///
/// This maps to OpenAI's `web_search` Responses API tool and follows the
/// same argument structure as the Vercel AI SDK `openai.tools.webSearch`:
/// - `filters.allowed_domains` (allowedDomains)
/// - `search_context_size` (contextSize)
/// - `user_location` (location)
class OpenAIWebSearchTool implements OpenAIBuiltInTool {
  /// Allowed domains for the search (filters.allowed_domains).
  final List<String>? allowedDomains;

  /// Search context size hint for the provider.
  final WebSearchContextSize? contextSize;

  /// Approximate user location for localized results.
  final WebSearchLocation? location;

  @override
  OpenAIBuiltInToolType get type => OpenAIBuiltInToolType.webSearch;

  const OpenAIWebSearchTool({
    this.allowedDomains,
    this.contextSize,
    this.location,
  });

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'type': 'web_search',
    };

    if (allowedDomains != null && allowedDomains!.isNotEmpty) {
      json['filters'] = {
        'allowed_domains': allowedDomains,
      };
    }

    if (contextSize != null) {
      final size = switch (contextSize!) {
        WebSearchContextSize.low => 'low',
        WebSearchContextSize.medium => 'medium',
        WebSearchContextSize.high => 'high',
      };
      json['search_context_size'] = size;
    }

    if (location != null) {
      json['user_location'] = {
        'type': location!.type ?? 'approximate',
        if (location!.country != null) 'country': location!.country,
        if (location!.city != null) 'city': location!.city,
        if (location!.region != null) 'region': location!.region,
        if (location!.timezone != null) 'timezone': location!.timezone,
      };
    }

    return json;
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
  static OpenAIWebSearchTool webSearch({
    List<String>? allowedDomains,
    WebSearchContextSize? contextSize,
    WebSearchLocation? location,
  }) =>
      OpenAIWebSearchTool(
        allowedDomains: allowedDomains,
        contextSize: contextSize,
        location: location,
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
}
