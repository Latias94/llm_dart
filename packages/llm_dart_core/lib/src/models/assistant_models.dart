import 'dart:convert';
import 'tool_models.dart';

/// Assistant tool types
enum AssistantToolType {
  codeInterpreter('code_interpreter'),
  fileSearch('file_search'),
  function('function');

  const AssistantToolType(this.value);
  final String value;

  static AssistantToolType fromString(String value) {
    switch (value) {
      case 'code_interpreter':
        return AssistantToolType.codeInterpreter;
      case 'file_search':
        return AssistantToolType.fileSearch;
      case 'function':
        return AssistantToolType.function;
      default:
        throw ArgumentError('Unknown assistant tool type: $value');
    }
  }
}

/// Base class for assistant tools
abstract class AssistantTool {
  AssistantToolType get type;
  Map<String, dynamic> toJson();
}

/// Code interpreter tool for assistants
class CodeInterpreterTool implements AssistantTool {
  @override
  AssistantToolType get type => AssistantToolType.codeInterpreter;

  const CodeInterpreterTool();

  @override
  Map<String, dynamic> toJson() {
    return {'type': type.value};
  }

  factory CodeInterpreterTool.fromJson(Map<String, dynamic> json) {
    return const CodeInterpreterTool();
  }
}

/// File search tool for assistants
class FileSearchTool implements AssistantTool {
  @override
  AssistantToolType get type => AssistantToolType.fileSearch;

  /// The maximum number of results the file search tool should output.
  final int? maxNumResults;

  const FileSearchTool({this.maxNumResults});

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'type': type.value};
    if (maxNumResults != null) {
      json['file_search'] = <String, dynamic>{'max_num_results': maxNumResults};
    }
    return json;
  }

  factory FileSearchTool.fromJson(Map<String, dynamic> json) {
    final fileSearchData = json['file_search'] as Map<String, dynamic>?;
    return FileSearchTool(
      maxNumResults: fileSearchData?['max_num_results'] as int?,
    );
  }
}

/// Function tool for assistants
class AssistantFunctionTool implements AssistantTool {
  @override
  AssistantToolType get type => AssistantToolType.function;

  /// The function definition
  final FunctionObject function;

  const AssistantFunctionTool({required this.function});

  @override
  Map<String, dynamic> toJson() {
    return {'type': type.value, 'function': function.toJson()};
  }

  factory AssistantFunctionTool.fromJson(Map<String, dynamic> json) {
    return AssistantFunctionTool(
      function: FunctionObject.fromJson(
        json['function'] as Map<String, dynamic>,
      ),
    );
  }
}

/// Tool resources for assistants
class ToolResources {
  /// Resources for the code interpreter tool
  final CodeInterpreterResources? codeInterpreter;

  /// Resources for the file search tool
  final FileSearchResources? fileSearch;

  const ToolResources({this.codeInterpreter, this.fileSearch});

  factory ToolResources.fromJson(Map<String, dynamic> json) {
    return ToolResources(
      codeInterpreter: json['code_interpreter'] != null
          ? CodeInterpreterResources.fromJson(
              json['code_interpreter'] as Map<String, dynamic>,
            )
          : null,
      fileSearch: json['file_search'] != null
          ? FileSearchResources.fromJson(
              json['file_search'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (codeInterpreter != null) {
      json['code_interpreter'] = codeInterpreter!.toJson();
    }
    if (fileSearch != null) {
      json['file_search'] = fileSearch!.toJson();
    }
    return json;
  }
}

/// Code interpreter resources
class CodeInterpreterResources {
  /// A list of file IDs made available to the code_interpreter tool.
  final List<String>? fileIds;

  const CodeInterpreterResources({this.fileIds});

  factory CodeInterpreterResources.fromJson(Map<String, dynamic> json) {
    return CodeInterpreterResources(
      fileIds: (json['file_ids'] as List?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (fileIds != null) {
      json['file_ids'] = fileIds;
    }
    return json;
  }
}

/// File search resources
class FileSearchResources {
  /// The vector store attached to this assistant.
  final List<String>? vectorStoreIds;

  /// A helper to create a vector store with file_ids and attach it to this assistant.
  final List<VectorStoreRequest>? vectorStores;

  const FileSearchResources({this.vectorStoreIds, this.vectorStores});

  factory FileSearchResources.fromJson(Map<String, dynamic> json) {
    return FileSearchResources(
      vectorStoreIds: (json['vector_store_ids'] as List?)?.cast<String>(),
      vectorStores: (json['vector_stores'] as List?)
          ?.map(
            (item) => VectorStoreRequest.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (vectorStoreIds != null) {
      json['vector_store_ids'] = vectorStoreIds;
    }
    if (vectorStores != null) {
      json['vector_stores'] = vectorStores!.map((vs) => vs.toJson()).toList();
    }
    return json;
  }
}

/// Vector store request for creating vector stores
class VectorStoreRequest {
  /// A list of file IDs to add to the vector store.
  final List<String>? fileIds;

  /// The chunking strategy used to chunk the file(s).
  final Map<String, dynamic>? chunkingStrategy;

  /// Set of 16 key-value pairs that can be attached to a vector store.
  final Map<String, String>? metadata;

  const VectorStoreRequest({
    this.fileIds,
    this.chunkingStrategy,
    this.metadata,
  });

  factory VectorStoreRequest.fromJson(Map<String, dynamic> json) {
    return VectorStoreRequest(
      fileIds: (json['file_ids'] as List?)?.cast<String>(),
      chunkingStrategy: json['chunking_strategy'] as Map<String, dynamic>?,
      metadata:
          (json['metadata'] as Map<String, dynamic>?)?.cast<String, String>(),
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (fileIds != null) {
      json['file_ids'] = fileIds;
    }
    if (chunkingStrategy != null) {
      json['chunking_strategy'] = chunkingStrategy;
    }
    if (metadata != null) {
      json['metadata'] = metadata;
    }
    return json;
  }
}

/// Response format for assistants
class AssistantResponseFormat {
  /// Must be one of text or json_object or json_schema.
  final String type;

  /// The JSON schema for the response format.
  final Map<String, dynamic>? jsonSchema;

  const AssistantResponseFormat({required this.type, this.jsonSchema});

  factory AssistantResponseFormat.fromJson(Map<String, dynamic> json) {
    return AssistantResponseFormat(
      type: json['type'] as String,
      jsonSchema: json['json_schema'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'type': type};
    if (jsonSchema != null) {
      json['json_schema'] = jsonSchema!;
    }
    return json;
  }
}

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
      tools: _parseTools(json['tools'] as List?),
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

  static List<AssistantTool> _parseTools(List? toolsJson) {
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

/// Response for listing assistants
class ListAssistantsResponse {
  /// The object type, which is always "list".
  final String object;

  /// The list of assistants.
  final List<Assistant> data;

  /// The identifier of the first assistant in the list.
  final String? firstId;

  /// The identifier of the last assistant in the list.
  final String? lastId;

  /// Whether there are more assistants available.
  final bool hasMore;

  const ListAssistantsResponse({
    this.object = 'list',
    required this.data,
    this.firstId,
    this.lastId,
    required this.hasMore,
  });

  factory ListAssistantsResponse.fromJson(Map<String, dynamic> json) {
    return ListAssistantsResponse(
      object: json['object'] as String? ?? 'list',
      data: (json['data'] as List)
          .map((item) => Assistant.fromJson(item as Map<String, dynamic>))
          .toList(),
      firstId: json['first_id'] as String?,
      lastId: json['last_id'] as String?,
      hasMore: json['has_more'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'object': object,
      'data': data.map((assistant) => assistant.toJson()).toList(),
      if (firstId != null) 'first_id': firstId,
      if (lastId != null) 'last_id': lastId,
      'has_more': hasMore,
    };
  }
}

/// Response for deleting an assistant
class DeleteAssistantResponse {
  /// The identifier of the deleted assistant.
  final String id;

  /// The object type, which is always "assistant.deleted".
  final String object;

  /// Whether the assistant was successfully deleted.
  final bool deleted;

  const DeleteAssistantResponse({
    required this.id,
    this.object = 'assistant.deleted',
    required this.deleted,
  });

  factory DeleteAssistantResponse.fromJson(Map<String, dynamic> json) {
    return DeleteAssistantResponse(
      id: json['id'] as String,
      object: json['object'] as String? ?? 'assistant.deleted',
      deleted: json['deleted'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'object': object, 'deleted': deleted};
  }
}

/// Query parameters for listing assistants
class ListAssistantsQuery {
  /// A limit on the number of objects to be returned.
  final int? limit;

  /// Sort order by the created_at timestamp of the objects.
  final String? order;

  /// A cursor for use in pagination.
  final String? after;

  /// A cursor for use in pagination.
  final String? before;

  const ListAssistantsQuery({this.limit, this.order, this.after, this.before});

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};

    if (limit != null) params['limit'] = limit;
    if (order != null) params['order'] = order;
    if (after != null) params['after'] = after;
    if (before != null) params['before'] = before;

    return params;
  }
}
