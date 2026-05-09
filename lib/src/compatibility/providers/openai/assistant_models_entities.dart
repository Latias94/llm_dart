import 'dart:convert';

import 'assistant_models_tools.dart';

/// Represents an assistant that can call the model and use tools.
class Assistant {
  /// The identifier, which can be referenced in API endpoints.
  final String id;

  /// The object type, which is always assistant.
  final String object;

  /// The Unix timestamp (in seconds) for when the assistant was created.
  final int createdAt;

  /// The name of the assistant.
  final String? name;

  /// The description of the assistant.
  final String? description;

  /// ID of the model to use.
  final String model;

  /// The system instructions that the assistant uses.
  final String? instructions;

  /// A list of tool enabled on the assistant.
  final List<AssistantTool> tools;

  /// A set of resources that are used by the assistant's tools.
  final ToolResources? toolResources;

  /// Set of 16 key-value pairs that can be attached to an object.
  final Map<String, String>? metadata;

  /// What sampling temperature to use, between 0 and 2.
  final double? temperature;

  /// An alternative to sampling with temperature, called nucleus sampling.
  final double? topP;

  /// Specifies the format that the model must output.
  final AssistantResponseFormat? responseFormat;

  const Assistant({
    required this.id,
    this.object = 'assistant',
    required this.createdAt,
    this.name,
    this.description,
    required this.model,
    this.instructions,
    this.tools = const [],
    this.toolResources,
    this.metadata,
    this.temperature,
    this.topP,
    this.responseFormat,
  });

  factory Assistant.fromJson(Map<String, dynamic> json) {
    return Assistant(
      id: json['id'] as String,
      object: json['object'] as String? ?? 'assistant',
      createdAt: json['created_at'] as int,
      name: json['name'] as String?,
      description: json['description'] as String?,
      model: json['model'] as String,
      instructions: json['instructions'] as String?,
      tools: _parseAssistantTools(json['tools'] as List?),
      toolResources: json['tool_resources'] != null
          ? ToolResources.fromJson(
              json['tool_resources'] as Map<String, dynamic>,
            )
          : null,
      metadata:
          (json['metadata'] as Map<String, dynamic>?)?.cast<String, String>(),
      temperature: (json['temperature'] as num?)?.toDouble(),
      topP: (json['top_p'] as num?)?.toDouble(),
      responseFormat: json['response_format'] != null
          ? AssistantResponseFormat.fromJson(
              json['response_format'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'object': object,
      'created_at': createdAt,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      'model': model,
      if (instructions != null) 'instructions': instructions,
      'tools': tools.map((tool) => tool.toJson()).toList(),
      if (toolResources != null) 'tool_resources': toolResources!.toJson(),
      if (metadata != null) 'metadata': metadata,
      if (temperature != null) 'temperature': temperature,
      if (topP != null) 'top_p': topP,
      if (responseFormat != null) 'response_format': responseFormat!.toJson(),
    };
  }

  @override
  String toString() => jsonEncode(toJson());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Assistant && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

List<AssistantTool> _parseAssistantTools(List? toolsJson) {
  if (toolsJson == null) return [];

  return toolsJson.map((toolJson) {
    final tool = toolJson as Map<String, dynamic>;
    final type = AssistantToolType.fromString(tool['type'] as String);

    switch (type) {
      case AssistantToolType.codeInterpreter:
        return CodeInterpreterTool.fromJson(tool);
      case AssistantToolType.fileSearch:
        return FileSearchTool.fromJson(tool);
      case AssistantToolType.function:
        return AssistantFunctionTool.fromJson(tool);
    }
  }).toList();
}
