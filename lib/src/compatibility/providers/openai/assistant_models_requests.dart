import 'assistant_models_tools.dart';

/// Request for creating an assistant
class CreateAssistantRequest {
  /// ID of the model to use.
  final String model;

  /// The name of the assistant.
  final String? name;

  /// The description of the assistant.
  final String? description;

  /// The system instructions that the assistant uses.
  final String? instructions;

  /// A list of tool enabled on the assistant.
  final List<AssistantTool>? tools;

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

  const CreateAssistantRequest({
    required this.model,
    this.name,
    this.description,
    this.instructions,
    this.tools,
    this.toolResources,
    this.metadata,
    this.temperature,
    this.topP,
    this.responseFormat,
  });

  Map<String, dynamic> toJson() {
    return {
      'model': model,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (instructions != null) 'instructions': instructions,
      if (tools != null) 'tools': tools!.map((tool) => tool.toJson()).toList(),
      if (toolResources != null) 'tool_resources': toolResources!.toJson(),
      if (metadata != null) 'metadata': metadata,
      if (temperature != null) 'temperature': temperature,
      if (topP != null) 'top_p': topP,
      if (responseFormat != null) 'response_format': responseFormat!.toJson(),
    };
  }
}

/// Request for modifying an assistant
class ModifyAssistantRequest {
  /// ID of the model to use.
  final String? model;

  /// The name of the assistant.
  final String? name;

  /// The description of the assistant.
  final String? description;

  /// The system instructions that the assistant uses.
  final String? instructions;

  /// A list of tool enabled on the assistant.
  final List<AssistantTool>? tools;

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

  const ModifyAssistantRequest({
    this.model,
    this.name,
    this.description,
    this.instructions,
    this.tools,
    this.toolResources,
    this.metadata,
    this.temperature,
    this.topP,
    this.responseFormat,
  });

  Map<String, dynamic> toJson() {
    return {
      if (model != null) 'model': model,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (instructions != null) 'instructions': instructions,
      if (tools != null) 'tools': tools!.map((tool) => tool.toJson()).toList(),
      if (toolResources != null) 'tool_resources': toolResources!.toJson(),
      if (metadata != null) 'metadata': metadata,
      if (temperature != null) 'temperature': temperature,
      if (topP != null) 'top_p': topP,
      if (responseFormat != null) 'response_format': responseFormat!.toJson(),
    };
  }
}
