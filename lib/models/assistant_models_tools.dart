part of 'assistant_models.dart';

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
