import 'openai_assistants_response_format_models.dart';
import 'openai_assistants_tool_models.dart';
import 'openai_assistants_tool_resources_models.dart';
import '../common/openai_json_value.dart';

final class OpenAIAssistant {
  final String id;
  final String object;
  final DateTime createdAt;
  final String? name;
  final String? description;
  final String model;
  final String? instructions;
  final List<OpenAIAssistantTool> tools;
  final OpenAIAssistantToolResources? toolResources;
  final Map<String, String>? metadata;
  final double? temperature;
  final double? topP;
  final OpenAIAssistantResponseFormat? responseFormat;

  const OpenAIAssistant({
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

  factory OpenAIAssistant.fromJson(Map<String, Object?> json) {
    final rawTools = openAIOptionalList(json['tools'], path: 'assistant.tools');
    return OpenAIAssistant(
      id: openAIRequiredNonEmptyString(json['id'], path: 'assistant.id'),
      object: openAIOptionalString(json['object'], path: 'assistant.object') ??
          'assistant',
      createdAt: openAIRequiredEpochSecondsDateTime(
        json['created_at'],
        path: 'assistant.created_at',
      ),
      name: openAIOptionalString(json['name'], path: 'assistant.name'),
      description: openAIOptionalString(
        json['description'],
        path: 'assistant.description',
      ),
      model:
          openAIRequiredNonEmptyString(json['model'], path: 'assistant.model'),
      instructions: openAIOptionalString(
        json['instructions'],
        path: 'assistant.instructions',
      ),
      tools: rawTools == null
          ? const []
          : rawTools
              .asMap()
              .entries
              .map(
                (entry) => openAIAssistantToolFromJson(
                  openAIRequiredMap(
                    entry.value,
                    path: 'assistant.tools[${entry.key}]',
                  ),
                ),
              )
              .toList(growable: false),
      toolResources: json['tool_resources'] == null
          ? null
          : OpenAIAssistantToolResources.fromJson(
              openAIRequiredMap(
                json['tool_resources'],
                path: 'assistant.tool_resources',
              ),
            ),
      metadata: openAIOptionalStringMap(
        json['metadata'],
        path: 'assistant.metadata',
      ),
      temperature: openAIOptionalDouble(
        json['temperature'],
        path: 'assistant.temperature',
      ),
      topP: openAIOptionalDouble(json['top_p'], path: 'assistant.top_p'),
      responseFormat: json['response_format'] == null
          ? null
          : OpenAIAssistantResponseFormat.fromJson(
              openAIRequiredMap(
                json['response_format'],
                path: 'assistant.response_format',
              ),
            ),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'object': object,
      'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      'model': model,
      if (instructions != null) 'instructions': instructions,
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
