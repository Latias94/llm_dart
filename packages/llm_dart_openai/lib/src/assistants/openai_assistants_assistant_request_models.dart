import 'openai_assistants_response_format_models.dart';
import 'openai_assistants_tool_models.dart';
import 'openai_assistants_tool_resources_models.dart';
import '../common/openai_json_value.dart';

final class OpenAICreateAssistantRequest {
  final String model;
  final String? name;
  final String? description;
  final String? instructions;
  final List<OpenAIAssistantTool> tools;
  final OpenAIAssistantToolResources? toolResources;
  final Map<String, String>? metadata;
  final double? temperature;
  final double? topP;
  final OpenAIAssistantResponseFormat? responseFormat;

  const OpenAICreateAssistantRequest({
    required this.model,
    this.name,
    this.description,
    this.instructions,
    this.tools = const [],
    this.toolResources,
    this.metadata,
    this.temperature,
    this.topP,
    this.responseFormat,
  });

  Map<String, Object?> toJson() {
    return {
      'model': model,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (instructions != null) 'instructions': instructions,
      if (tools.isNotEmpty)
        'tools': tools.map((tool) => tool.toJson()).toList(growable: false),
      if (toolResources != null) 'tool_resources': toolResources!.toJson(),
      if (metadata != null)
        'metadata': Map<String, String>.unmodifiable(
          metadata!,
        ),
      if (temperature != null) 'temperature': temperature,
      if (topP != null) 'top_p': topP,
      if (responseFormat != null) 'response_format': responseFormat!.toJson(),
    };
  }
}

final class OpenAIModifyAssistantRequest {
  final String? model;
  final String? name;
  final String? description;
  final String? instructions;
  final List<OpenAIAssistantTool>? tools;
  final OpenAIAssistantToolResources? toolResources;
  final Map<String, String>? metadata;
  final double? temperature;
  final double? topP;
  final OpenAIAssistantResponseFormat? responseFormat;

  const OpenAIModifyAssistantRequest({
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

  Map<String, Object?> toJson() {
    return {
      if (model != null) 'model': model,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (instructions != null) 'instructions': instructions,
      if (tools != null)
        'tools': tools!.map((tool) => tool.toJson()).toList(growable: false),
      if (toolResources != null) 'tool_resources': toolResources!.toJson(),
      if (metadata != null)
        'metadata': Map<String, String>.unmodifiable(
          metadata!,
        ),
      if (temperature != null) 'temperature': temperature,
      if (topP != null) 'top_p': topP,
      if (responseFormat != null) 'response_format': responseFormat!.toJson(),
    };
  }
}

OpenAICreateAssistantRequest openAIAssistantCreateRequestFromImportConfig(
  Map<String, Object?> config, {
  required String importedAt,
}) {
  return OpenAICreateAssistantRequest(
    model: openAIRequiredNonEmptyString(
      config['model'],
      path: 'assistant_import.model',
    ),
    name: openAIOptionalString(config['name'], path: 'assistant_import.name'),
    description: openAIOptionalString(
      config['description'],
      path: 'assistant_import.description',
    ),
    instructions: openAIOptionalString(
      config['instructions'],
      path: 'assistant_import.instructions',
    ),
    tools: openAIOptionalList(config['tools'], path: 'assistant_import.tools')
            ?.asMap()
            .entries
            .map(
              (entry) => openAIAssistantToolFromJson(
                openAIRequiredMap(
                  entry.value,
                  path: 'assistant_import.tools[${entry.key}]',
                ),
              ),
            )
            .toList(growable: false) ??
        const [],
    toolResources: config['tool_resources'] == null
        ? null
        : OpenAIAssistantToolResources.fromJson(
            openAIRequiredMap(
              config['tool_resources'],
              path: 'assistant_import.tool_resources',
            ),
          ),
    metadata: {
      ...?openAIOptionalStringMap(
        config['metadata'],
        path: 'assistant_import.metadata',
      ),
      'imported_at': importedAt,
    },
    temperature: openAIOptionalDouble(
      config['temperature'],
      path: 'assistant_import.temperature',
    ),
    topP: openAIOptionalDouble(config['top_p'], path: 'assistant_import.top_p'),
    responseFormat: config['response_format'] == null
        ? null
        : OpenAIAssistantResponseFormat.fromJson(
            openAIRequiredMap(
              config['response_format'],
              path: 'assistant_import.response_format',
            ),
          ),
  );
}
