import 'openai_assistants_lifecycle_model_support.dart';
import 'openai_assistants_response_format_models.dart';
import 'openai_assistants_tool_models.dart';
import 'openai_assistants_tool_resources_models.dart';
import 'openai_json_value.dart';

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

final class OpenAIListAssistantsQuery {
  final int? limit;
  final String? order;
  final String? after;
  final String? before;

  const OpenAIListAssistantsQuery({
    this.limit,
    this.order,
    this.after,
    this.before,
  });

  Map<String, String> toQueryParameters() {
    return openAIAssistantsPaginationQueryParameters(
      limit: limit,
      order: order,
      after: after,
      before: before,
      limitParameterName: 'limit',
      limitErrorMessage: 'OpenAI assistant list limit must be >= 1.',
    );
  }
}

final class OpenAIListAssistantsResponse {
  final String object;
  final List<OpenAIAssistant> data;
  final String? firstId;
  final String? lastId;
  final bool hasMore;

  const OpenAIListAssistantsResponse({
    this.object = 'list',
    required this.data,
    this.firstId,
    this.lastId,
    required this.hasMore,
  });

  factory OpenAIListAssistantsResponse.fromJson(Map<String, Object?> json) {
    return OpenAIListAssistantsResponse(
      object: openAIOptionalString(json['object'], path: 'assistants.object') ??
          'list',
      data: openAIRequiredList(json['data'], path: 'assistants.data')
          .asMap()
          .entries
          .map(
            (entry) => OpenAIAssistant.fromJson(
              openAIRequiredMap(
                entry.value,
                path: 'assistants.data[${entry.key}]',
              ),
            ),
          )
          .toList(growable: false),
      firstId:
          openAIOptionalString(json['first_id'], path: 'assistants.first_id'),
      lastId: openAIOptionalString(json['last_id'], path: 'assistants.last_id'),
      hasMore:
          openAIRequiredBool(json['has_more'], path: 'assistants.has_more'),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'object': object,
      'data': data.map((assistant) => assistant.toJson()).toList(),
      if (firstId != null) 'first_id': firstId,
      if (lastId != null) 'last_id': lastId,
      'has_more': hasMore,
    };
  }
}

final class OpenAIDeleteAssistantResponse {
  final String id;
  final String object;
  final bool deleted;

  const OpenAIDeleteAssistantResponse({
    required this.id,
    this.object = 'assistant.deleted',
    required this.deleted,
  });

  factory OpenAIDeleteAssistantResponse.fromJson(Map<String, Object?> json) {
    return OpenAIDeleteAssistantResponse(
      id: openAIRequiredNonEmptyString(json['id'], path: 'assistant_delete.id'),
      object: openAIOptionalString(
            json['object'],
            path: 'assistant_delete.object',
          ) ??
          'assistant.deleted',
      deleted:
          openAIRequiredBool(json['deleted'], path: 'assistant_delete.deleted'),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'object': object,
      'deleted': deleted,
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

List<OpenAIAssistant> openAISearchAssistants(
  List<OpenAIAssistant> assistants, {
  String? namePattern,
  String? model,
  List<String>? requiredTools,
  Map<String, String>? metadataFilters,
}) {
  var filtered = assistants;

  if (namePattern != null) {
    final regex = RegExp(namePattern, caseSensitive: false);
    filtered = filtered.where((assistant) {
      final name = assistant.name;
      return name != null && regex.hasMatch(name);
    }).toList(growable: false);
  }

  if (model != null) {
    filtered = filtered
        .where((assistant) => assistant.model == model)
        .toList(growable: false);
  }

  if (requiredTools != null && requiredTools.isNotEmpty) {
    filtered = filtered.where((assistant) {
      final toolTypes = assistant.tools
          .map((tool) => tool.toJson()['type'])
          .whereType<String>()
          .toSet();
      return requiredTools.every(toolTypes.contains);
    }).toList(growable: false);
  }

  if (metadataFilters != null && metadataFilters.isNotEmpty) {
    filtered = filtered.where((assistant) {
      final metadata = assistant.metadata ?? const <String, String>{};
      return metadataFilters.entries
          .every((filter) => metadata[filter.key] == filter.value);
    }).toList(growable: false);
  }

  return filtered;
}
