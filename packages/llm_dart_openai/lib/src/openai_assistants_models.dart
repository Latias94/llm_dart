import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_json_value.dart';
import 'openai_response_format.dart';

enum OpenAIAssistantToolType {
  codeInterpreter('code_interpreter'),
  fileSearch('file_search'),
  function('function'),
  raw('');

  const OpenAIAssistantToolType(this.value);

  final String value;

  static OpenAIAssistantToolType fromString(String value) {
    return switch (value) {
      'code_interpreter' => OpenAIAssistantToolType.codeInterpreter,
      'file_search' => OpenAIAssistantToolType.fileSearch,
      'function' => OpenAIAssistantToolType.function,
      _ => OpenAIAssistantToolType.raw,
    };
  }
}

abstract interface class OpenAIAssistantTool {
  OpenAIAssistantToolType get type;

  Map<String, Object?> toJson();
}

final class OpenAIAssistantCodeInterpreterTool implements OpenAIAssistantTool {
  const OpenAIAssistantCodeInterpreterTool();

  @override
  OpenAIAssistantToolType get type => OpenAIAssistantToolType.codeInterpreter;

  @override
  Map<String, Object?> toJson() {
    return {
      'type': type.value,
    };
  }
}

final class OpenAIAssistantFileSearchTool implements OpenAIAssistantTool {
  final int? maxNumResults;

  const OpenAIAssistantFileSearchTool({
    this.maxNumResults,
  });

  @override
  OpenAIAssistantToolType get type => OpenAIAssistantToolType.fileSearch;

  @override
  Map<String, Object?> toJson() {
    return {
      'type': type.value,
      if (maxNumResults != null)
        'file_search': {
          'max_num_results': maxNumResults,
        },
    };
  }
}

final class OpenAIAssistantFunctionTool implements OpenAIAssistantTool {
  final FunctionToolDefinition function;

  const OpenAIAssistantFunctionTool({
    required this.function,
  });

  @override
  OpenAIAssistantToolType get type => OpenAIAssistantToolType.function;

  @override
  Map<String, Object?> toJson() {
    return {
      'type': type.value,
      'function': _functionToolDefinitionToJson(function),
    };
  }
}

final class OpenAIAssistantRawTool implements OpenAIAssistantTool {
  final String rawType;
  final Map<String, Object?> json;

  OpenAIAssistantRawTool({
    required this.rawType,
    required Map<String, Object?> json,
  }) : json = Map.unmodifiable(json);

  @override
  OpenAIAssistantToolType get type => OpenAIAssistantToolType.raw;

  @override
  Map<String, Object?> toJson() {
    return {
      ...json,
      'type': rawType,
    };
  }
}

final class OpenAIAssistantToolResources {
  final OpenAIAssistantCodeInterpreterResources? codeInterpreter;
  final OpenAIAssistantFileSearchResources? fileSearch;

  const OpenAIAssistantToolResources({
    this.codeInterpreter,
    this.fileSearch,
  });

  factory OpenAIAssistantToolResources.fromJson(Map<String, Object?> json) {
    return OpenAIAssistantToolResources(
      codeInterpreter: json['code_interpreter'] == null
          ? null
          : OpenAIAssistantCodeInterpreterResources.fromJson(
              openAIRequiredMap(
                json['code_interpreter'],
                path: 'tool_resources.code_interpreter',
              ),
            ),
      fileSearch: json['file_search'] == null
          ? null
          : OpenAIAssistantFileSearchResources.fromJson(
              openAIRequiredMap(
                json['file_search'],
                path: 'tool_resources.file_search',
              ),
            ),
    );
  }

  Map<String, Object?> toJson() {
    return {
      if (codeInterpreter != null)
        'code_interpreter': codeInterpreter!.toJson(),
      if (fileSearch != null) 'file_search': fileSearch!.toJson(),
    };
  }
}

final class OpenAIAssistantCodeInterpreterResources {
  final List<String>? fileIds;

  const OpenAIAssistantCodeInterpreterResources({
    this.fileIds,
  });

  factory OpenAIAssistantCodeInterpreterResources.fromJson(
    Map<String, Object?> json,
  ) {
    return OpenAIAssistantCodeInterpreterResources(
      fileIds: openAIOptionalStringList(
        json['file_ids'],
        path: 'code_interpreter.file_ids',
      ),
    );
  }

  Map<String, Object?> toJson() {
    return {
      if (fileIds != null) 'file_ids': List<String>.unmodifiable(fileIds!),
    };
  }
}

final class OpenAIAssistantFileSearchResources {
  final List<String>? vectorStoreIds;
  final List<OpenAIAssistantVectorStoreRequest>? vectorStores;

  const OpenAIAssistantFileSearchResources({
    this.vectorStoreIds,
    this.vectorStores,
  });

  factory OpenAIAssistantFileSearchResources.fromJson(
    Map<String, Object?> json,
  ) {
    return OpenAIAssistantFileSearchResources(
      vectorStoreIds: openAIOptionalStringList(
        json['vector_store_ids'],
        path: 'file_search.vector_store_ids',
      ),
      vectorStores: openAIOptionalList(
        json['vector_stores'],
        path: 'file_search.vector_stores',
      )
          ?.asMap()
          .entries
          .map(
            (entry) => OpenAIAssistantVectorStoreRequest.fromJson(
              openAIRequiredMap(
                entry.value,
                path: 'file_search.vector_stores[${entry.key}]',
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Map<String, Object?> toJson() {
    return {
      if (vectorStoreIds != null)
        'vector_store_ids': List<String>.unmodifiable(vectorStoreIds!),
      if (vectorStores != null)
        'vector_stores': vectorStores!.map((store) => store.toJson()).toList(),
    };
  }
}

final class OpenAIAssistantVectorStoreRequest {
  final List<String>? fileIds;
  final Map<String, Object?>? chunkingStrategy;
  final Map<String, String>? metadata;

  const OpenAIAssistantVectorStoreRequest({
    this.fileIds,
    this.chunkingStrategy,
    this.metadata,
  });

  factory OpenAIAssistantVectorStoreRequest.fromJson(
    Map<String, Object?> json,
  ) {
    return OpenAIAssistantVectorStoreRequest(
      fileIds: openAIOptionalStringList(
        json['file_ids'],
        path: 'vector_store.file_ids',
      ),
      chunkingStrategy: json['chunking_strategy'] == null
          ? null
          : openAIRequiredMap(
              json['chunking_strategy'],
              path: 'vector_store.chunking_strategy',
            ),
      metadata: openAIOptionalStringMap(
        json['metadata'],
        path: 'vector_store.metadata',
      ),
    );
  }

  Map<String, Object?> toJson() {
    return {
      if (fileIds != null) 'file_ids': List<String>.unmodifiable(fileIds!),
      if (chunkingStrategy != null)
        'chunking_strategy': Map<String, Object?>.unmodifiable(
          chunkingStrategy!,
        ),
      if (metadata != null)
        'metadata': Map<String, String>.unmodifiable(
          metadata!,
        ),
    };
  }
}

final class OpenAIAssistantResponseFormat {
  final String type;
  final OpenAIJsonSchemaResponseFormat? jsonSchema;
  final Map<String, Object?> extra;

  const OpenAIAssistantResponseFormat({
    required this.type,
    this.jsonSchema,
    this.extra = const {},
  });

  const OpenAIAssistantResponseFormat.text()
      : type = 'text',
        jsonSchema = null,
        extra = const {};

  const OpenAIAssistantResponseFormat.jsonObject()
      : type = 'json_object',
        jsonSchema = null,
        extra = const {};

  const OpenAIAssistantResponseFormat.jsonSchema(
    this.jsonSchema, {
    this.extra = const {},
  }) : type = 'json_schema';

  factory OpenAIAssistantResponseFormat.fromJson(Map<String, Object?> json) {
    final type = openAIRequiredNonEmptyString(
      json['type'],
      path: 'assistant.response_format.type',
    );
    final rawJsonSchema = json['json_schema'];
    return OpenAIAssistantResponseFormat(
      type: type,
      jsonSchema: rawJsonSchema == null
          ? null
          : _openAIJsonSchemaResponseFormatFromJson(
              openAIRequiredMap(
                rawJsonSchema,
                path: 'assistant.response_format.json_schema',
              ),
            ),
      extra: Map.unmodifiable(
        Map<String, Object?>.from(json)
          ..remove('type')
          ..remove('json_schema'),
      ),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'type': type,
      if (jsonSchema != null) 'json_schema': jsonSchema!.toJsonSchema(),
      ...extra,
    };
  }
}

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
                (entry) => _assistantToolFromJson(
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
    final limit = this.limit;
    if (limit != null && limit < 1) {
      throw ArgumentError.value(
        limit,
        'limit',
        'OpenAI assistant list limit must be >= 1.',
      );
    }

    return {
      if (limit != null) 'limit': '$limit',
      if (order != null && order!.isNotEmpty) 'order': order!,
      if (after != null && after!.isNotEmpty) 'after': after!,
      if (before != null && before!.isNotEmpty) 'before': before!,
    };
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
              (entry) => _assistantToolFromJson(
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

Map<String, Object?> _functionToolDefinitionToJson(
  FunctionToolDefinition function,
) {
  return {
    'name': function.name,
    if (function.description != null) 'description': function.description,
    'parameters': function.inputSchema.toJson(),
    if (function.strict != null) 'strict': function.strict,
  };
}

OpenAIAssistantTool _assistantToolFromJson(Map<String, Object?> json) {
  final rawType = openAIRequiredNonEmptyString(
    json['type'],
    path: 'assistant_tool.type',
  );
  return switch (OpenAIAssistantToolType.fromString(rawType)) {
    OpenAIAssistantToolType.codeInterpreter =>
      const OpenAIAssistantCodeInterpreterTool(),
    OpenAIAssistantToolType.fileSearch => OpenAIAssistantFileSearchTool(
        maxNumResults: openAIOptionalInt(
          openAIOptionalMap(
            json['file_search'],
            path: 'assistant_tool.file_search',
          )?['max_num_results'],
          path: 'assistant_tool.file_search.max_num_results',
        ),
      ),
    OpenAIAssistantToolType.function => OpenAIAssistantFunctionTool(
        function: _functionToolDefinitionFromJson(
          openAIRequiredMap(json['function'], path: 'assistant_tool.function'),
        ),
      ),
    OpenAIAssistantToolType.raw => OpenAIAssistantRawTool(
        rawType: rawType,
        json: json,
      ),
  };
}

FunctionToolDefinition _functionToolDefinitionFromJson(
  Map<String, Object?> json,
) {
  final rawParameters = json['parameters'];
  return FunctionToolDefinition(
    name: openAIRequiredNonEmptyString(json['name'], path: 'function.name'),
    description: openAIOptionalString(
      json['description'],
      path: 'function.description',
    ),
    inputSchema: rawParameters == null
        ? ToolJsonSchema.object()
        : ToolJsonSchema.raw(
            openAIRequiredMap(rawParameters, path: 'function.parameters'),
          ),
    strict: openAIOptionalBool(json['strict'], path: 'function.strict'),
  );
}

OpenAIJsonSchemaResponseFormat _openAIJsonSchemaResponseFormatFromJson(
  Map<String, Object?> json,
) {
  return OpenAIJsonSchemaResponseFormat(
    name: openAIRequiredNonEmptyString(json['name'], path: 'json_schema.name'),
    description: openAIOptionalString(
      json['description'],
      path: 'json_schema.description',
    ),
    schema: json['schema'] == null
        ? null
        : openAIRequiredMap(json['schema'], path: 'json_schema.schema'),
    strict: openAIOptionalBool(json['strict'], path: 'json_schema.strict'),
  );
}
