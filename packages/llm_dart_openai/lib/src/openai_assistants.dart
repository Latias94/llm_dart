import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_family_profile.dart';
import 'openai_json_support.dart';
import 'openai_non_text_model_support.dart';
import 'openai_profile_boundary.dart';
import 'openai_response_format.dart';

final class OpenAIAssistantsSettings {
  final String? organization;
  final String? project;
  final Map<String, String> headers;

  const OpenAIAssistantsSettings({
    this.organization,
    this.project,
    this.headers = const {},
  });
}

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
              _requiredMap(
                json['code_interpreter'],
                path: 'tool_resources.code_interpreter',
              ),
            ),
      fileSearch: json['file_search'] == null
          ? null
          : OpenAIAssistantFileSearchResources.fromJson(
              _requiredMap(
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
      fileIds: _optionalStringList(
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
      vectorStoreIds: _optionalStringList(
        json['vector_store_ids'],
        path: 'file_search.vector_store_ids',
      ),
      vectorStores: _optionalList(
        json['vector_stores'],
        path: 'file_search.vector_stores',
      )
          ?.asMap()
          .entries
          .map(
            (entry) => OpenAIAssistantVectorStoreRequest.fromJson(
              _requiredMap(
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
      fileIds: _optionalStringList(
        json['file_ids'],
        path: 'vector_store.file_ids',
      ),
      chunkingStrategy: json['chunking_strategy'] == null
          ? null
          : _requiredMap(
              json['chunking_strategy'],
              path: 'vector_store.chunking_strategy',
            ),
      metadata: _optionalStringMap(
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
    final type = _requiredNonEmptyString(
      json['type'],
      path: 'assistant.response_format.type',
    );
    final rawJsonSchema = json['json_schema'];
    return OpenAIAssistantResponseFormat(
      type: type,
      jsonSchema: rawJsonSchema == null
          ? null
          : _openAIJsonSchemaResponseFormatFromJson(
              _requiredMap(
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
    final rawTools = _optionalList(json['tools'], path: 'assistant.tools');
    return OpenAIAssistant(
      id: _requiredNonEmptyString(json['id'], path: 'assistant.id'),
      object: _optionalString(json['object'], path: 'assistant.object') ??
          'assistant',
      createdAt: _requiredEpochSecondsDateTime(
        json['created_at'],
        path: 'assistant.created_at',
      ),
      name: _optionalString(json['name'], path: 'assistant.name'),
      description: _optionalString(
        json['description'],
        path: 'assistant.description',
      ),
      model: _requiredNonEmptyString(json['model'], path: 'assistant.model'),
      instructions: _optionalString(
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
                  _requiredMap(
                    entry.value,
                    path: 'assistant.tools[${entry.key}]',
                  ),
                ),
              )
              .toList(growable: false),
      toolResources: json['tool_resources'] == null
          ? null
          : OpenAIAssistantToolResources.fromJson(
              _requiredMap(
                json['tool_resources'],
                path: 'assistant.tool_resources',
              ),
            ),
      metadata: _optionalStringMap(
        json['metadata'],
        path: 'assistant.metadata',
      ),
      temperature: _optionalDouble(
        json['temperature'],
        path: 'assistant.temperature',
      ),
      topP: _optionalDouble(json['top_p'], path: 'assistant.top_p'),
      responseFormat: json['response_format'] == null
          ? null
          : OpenAIAssistantResponseFormat.fromJson(
              _requiredMap(
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
      object:
          _optionalString(json['object'], path: 'assistants.object') ?? 'list',
      data: _requiredList(json['data'], path: 'assistants.data')
          .asMap()
          .entries
          .map(
            (entry) => OpenAIAssistant.fromJson(
              _requiredMap(
                entry.value,
                path: 'assistants.data[${entry.key}]',
              ),
            ),
          )
          .toList(growable: false),
      firstId: _optionalString(json['first_id'], path: 'assistants.first_id'),
      lastId: _optionalString(json['last_id'], path: 'assistants.last_id'),
      hasMore: _requiredBool(json['has_more'], path: 'assistants.has_more'),
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
      id: _requiredNonEmptyString(json['id'], path: 'assistant_delete.id'),
      object:
          _optionalString(json['object'], path: 'assistant_delete.object') ??
              'assistant.deleted',
      deleted: _requiredBool(json['deleted'], path: 'assistant_delete.deleted'),
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

final class OpenAIAssistantsClient {
  final String apiKey;
  final String baseUrl;
  final OpenAIFamilyProfile profile;
  final TransportClient transport;
  final OpenAIAssistantsSettings settings;

  OpenAIAssistantsClient({
    required this.apiKey,
    required this.profile,
    required this.transport,
    this.settings = const OpenAIAssistantsSettings(),
    String? baseUrl,
  }) : baseUrl = baseUrl ?? profile.defaultBaseUrl {
    requireOpenAIProfile(profile, featureName: 'OpenAI assistants client');
  }

  Uri assistantsUri([OpenAIListAssistantsQuery? query]) {
    final uri = Uri.parse('$baseUrl/assistants');
    final queryParameters = query?.toQueryParameters() ?? const {};
    if (queryParameters.isEmpty) {
      return uri;
    }
    return uri.replace(queryParameters: queryParameters);
  }

  Uri assistantUri(String assistantId) {
    return Uri.parse(
      '$baseUrl/assistants/${Uri.encodeComponent(_requireNonEmptyId(
        assistantId,
        parameterName: 'assistantId',
      ))}',
    );
  }

  Future<OpenAIAssistant> createAssistant(
    OpenAICreateAssistantRequest request, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    final response = await transport.send(
      TransportRequest(
        uri: assistantsUri(),
        method: TransportMethod.post,
        headers: _buildHeaders(extraHeaders: headers, contentType: true),
        body: request.toJson(),
        timeout: timeout,
        maxRetries: maxRetries,
        cancellation: cancellation,
        responseType: TransportResponseType.json,
      ),
    );

    return OpenAIAssistant.fromJson(
      decodeOpenAIJsonObject(
        response.body,
        responseName: 'assistant create response',
      ),
    );
  }

  Future<OpenAIListAssistantsResponse> listAssistants({
    OpenAIListAssistantsQuery? query,
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    final response = await transport.send(
      TransportRequest(
        uri: assistantsUri(query),
        method: TransportMethod.get,
        headers: _buildHeaders(extraHeaders: headers),
        timeout: timeout,
        maxRetries: maxRetries,
        cancellation: cancellation,
        responseType: TransportResponseType.json,
      ),
    );

    return OpenAIListAssistantsResponse.fromJson(
      decodeOpenAIJsonObject(
        response.body,
        responseName: 'assistant list response',
      ),
    );
  }

  Future<OpenAIAssistant> retrieveAssistant(
    String assistantId, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    final response = await transport.send(
      TransportRequest(
        uri: assistantUri(assistantId),
        method: TransportMethod.get,
        headers: _buildHeaders(extraHeaders: headers),
        timeout: timeout,
        maxRetries: maxRetries,
        cancellation: cancellation,
        responseType: TransportResponseType.json,
      ),
    );

    return OpenAIAssistant.fromJson(
      decodeOpenAIJsonObject(
        response.body,
        responseName: 'assistant retrieve response',
      ),
    );
  }

  Future<OpenAIAssistant> modifyAssistant(
    String assistantId,
    OpenAIModifyAssistantRequest request, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    final response = await transport.send(
      TransportRequest(
        uri: assistantUri(assistantId),
        method: TransportMethod.post,
        headers: _buildHeaders(extraHeaders: headers, contentType: true),
        body: request.toJson(),
        timeout: timeout,
        maxRetries: maxRetries,
        cancellation: cancellation,
        responseType: TransportResponseType.json,
      ),
    );

    return OpenAIAssistant.fromJson(
      decodeOpenAIJsonObject(
        response.body,
        responseName: 'assistant modify response',
      ),
    );
  }

  Future<OpenAIDeleteAssistantResponse> deleteAssistant(
    String assistantId, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    final response = await transport.send(
      TransportRequest(
        uri: assistantUri(assistantId),
        method: TransportMethod.delete,
        headers: _buildHeaders(extraHeaders: headers),
        timeout: timeout,
        maxRetries: maxRetries,
        cancellation: cancellation,
        responseType: TransportResponseType.json,
      ),
    );

    return OpenAIDeleteAssistantResponse.fromJson(
      decodeOpenAIJsonObject(
        response.body,
        responseName: 'assistant delete response',
      ),
    );
  }

  Future<OpenAIAssistant?> getAssistantByName(String name) async {
    final response = await listAssistants();
    for (final assistant in response.data) {
      if (assistant.name == name) {
        return assistant;
      }
    }
    return null;
  }

  Future<bool> assistantExists(String assistantId) async {
    try {
      await retrieveAssistant(assistantId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<OpenAIAssistant>> getAssistantsByModel(String model) async {
    final response = await listAssistants();
    return response.data
        .where((assistant) => assistant.model == model)
        .toList(growable: false);
  }

  Future<OpenAIAssistant> cloneAssistant(
    String assistantId, {
    String? newName,
    String? newDescription,
    Map<String, String>? additionalMetadata,
  }) async {
    final original = await retrieveAssistant(assistantId);
    return createAssistant(
      OpenAICreateAssistantRequest(
        model: original.model,
        name: newName ?? _copyName(original.name),
        description: newDescription ?? original.description,
        instructions: original.instructions,
        tools: original.tools,
        toolResources: original.toolResources,
        metadata: {
          ...?original.metadata,
          ...?additionalMetadata,
          'cloned_from': assistantId,
          'cloned_at': DateTime.now().toUtc().toIso8601String(),
        },
        temperature: original.temperature,
        topP: original.topP,
        responseFormat: original.responseFormat,
      ),
    );
  }

  Future<OpenAIAssistant> updateInstructions(
    String assistantId,
    String instructions,
  ) {
    return modifyAssistant(
      assistantId,
      OpenAIModifyAssistantRequest(instructions: instructions),
    );
  }

  Future<OpenAIAssistant> addTools(
    String assistantId,
    List<OpenAIAssistantTool> tools,
  ) async {
    final current = await retrieveAssistant(assistantId);
    return modifyAssistant(
      assistantId,
      OpenAIModifyAssistantRequest(
        tools: [...current.tools, ...tools],
      ),
    );
  }

  Future<OpenAIAssistant> removeTools(
    String assistantId,
    List<String> toolTypes,
  ) async {
    final current = await retrieveAssistant(assistantId);
    return modifyAssistant(
      assistantId,
      OpenAIModifyAssistantRequest(
        tools: current.tools
            .where((tool) => !toolTypes.contains(tool.toJson()['type']))
            .toList(growable: false),
      ),
    );
  }

  Future<OpenAIAssistant> updateToolResources(
    String assistantId,
    OpenAIAssistantToolResources toolResources,
  ) {
    return modifyAssistant(
      assistantId,
      OpenAIModifyAssistantRequest(toolResources: toolResources),
    );
  }

  Future<OpenAIAssistant> updateMetadata(
    String assistantId,
    Map<String, String> metadata,
  ) {
    return modifyAssistant(
      assistantId,
      OpenAIModifyAssistantRequest(metadata: metadata),
    );
  }

  Future<List<OpenAIAssistant>> searchAssistants({
    String? namePattern,
    String? model,
    List<String>? requiredTools,
    Map<String, String>? metadataFilters,
  }) async {
    final response = await listAssistants();
    return _searchAssistants(
      response.data,
      namePattern: namePattern,
      model: model,
      requiredTools: requiredTools,
      metadataFilters: metadataFilters,
    );
  }

  Future<List<OpenAIDeleteAssistantResponse>> deleteAssistants(
    List<String> assistantIds,
  ) async {
    final results = <OpenAIDeleteAssistantResponse>[];
    for (final assistantId in assistantIds) {
      try {
        results.add(await deleteAssistant(assistantId));
      } catch (_) {
        results.add(
          OpenAIDeleteAssistantResponse(
            id: assistantId,
            deleted: false,
          ),
        );
      }
    }
    return results;
  }

  Map<String, Object?> exportAssistant(OpenAIAssistant assistant) {
    return {
      if (assistant.name != null) 'name': assistant.name,
      if (assistant.description != null) 'description': assistant.description,
      'model': assistant.model,
      if (assistant.instructions != null)
        'instructions': assistant.instructions,
      'tools': assistant.tools.map((tool) => tool.toJson()).toList(),
      if (assistant.toolResources != null)
        'tool_resources': assistant.toolResources!.toJson(),
      if (assistant.metadata != null) 'metadata': assistant.metadata,
      if (assistant.temperature != null) 'temperature': assistant.temperature,
      if (assistant.topP != null) 'top_p': assistant.topP,
      if (assistant.responseFormat != null)
        'response_format': assistant.responseFormat!.toJson(),
      'exported_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Future<OpenAIAssistant> importAssistant(Map<String, Object?> config) {
    return createAssistant(
      OpenAICreateAssistantRequest(
        model: _requiredNonEmptyString(
          config['model'],
          path: 'assistant_import.model',
        ),
        name: _optionalString(config['name'], path: 'assistant_import.name'),
        description: _optionalString(
          config['description'],
          path: 'assistant_import.description',
        ),
        instructions: _optionalString(
          config['instructions'],
          path: 'assistant_import.instructions',
        ),
        tools: _optionalList(config['tools'], path: 'assistant_import.tools')
                ?.asMap()
                .entries
                .map(
                  (entry) => _assistantToolFromJson(
                    _requiredMap(
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
                _requiredMap(
                  config['tool_resources'],
                  path: 'assistant_import.tool_resources',
                ),
              ),
        metadata: {
          ...?_optionalStringMap(
            config['metadata'],
            path: 'assistant_import.metadata',
          ),
          'imported_at': DateTime.now().toUtc().toIso8601String(),
        },
        temperature: _optionalDouble(
          config['temperature'],
          path: 'assistant_import.temperature',
        ),
        topP: _optionalDouble(config['top_p'], path: 'assistant_import.top_p'),
        responseFormat: config['response_format'] == null
            ? null
            : OpenAIAssistantResponseFormat.fromJson(
                _requiredMap(
                  config['response_format'],
                  path: 'assistant_import.response_format',
                ),
              ),
      ),
    );
  }

  Map<String, String> _buildHeaders({
    Map<String, String>? extraHeaders,
    bool contentType = false,
  }) {
    return buildOpenAIFamilyDefaultHeaders(
      profile: profile,
      apiKey: apiKey,
      organization: settings.organization,
      project: settings.project,
      headers: {
        ...settings.headers,
        if (contentType) 'content-type': 'application/json',
        'accept': 'application/json',
        if (extraHeaders != null) ...extraHeaders,
      },
    );
  }
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
  final rawType = _requiredNonEmptyString(
    json['type'],
    path: 'assistant_tool.type',
  );
  return switch (OpenAIAssistantToolType.fromString(rawType)) {
    OpenAIAssistantToolType.codeInterpreter =>
      const OpenAIAssistantCodeInterpreterTool(),
    OpenAIAssistantToolType.fileSearch => OpenAIAssistantFileSearchTool(
        maxNumResults: _optionalInt(
          _optionalMap(json['file_search'],
              path: 'assistant_tool.file_search')?['max_num_results'],
          path: 'assistant_tool.file_search.max_num_results',
        ),
      ),
    OpenAIAssistantToolType.function => OpenAIAssistantFunctionTool(
        function: _functionToolDefinitionFromJson(
          _requiredMap(json['function'], path: 'assistant_tool.function'),
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
    name: _requiredNonEmptyString(json['name'], path: 'function.name'),
    description: _optionalString(
      json['description'],
      path: 'function.description',
    ),
    inputSchema: rawParameters == null
        ? ToolJsonSchema.object()
        : ToolJsonSchema.raw(
            _requiredMap(rawParameters, path: 'function.parameters'),
          ),
    strict: _optionalBool(json['strict'], path: 'function.strict'),
  );
}

OpenAIJsonSchemaResponseFormat _openAIJsonSchemaResponseFormatFromJson(
  Map<String, Object?> json,
) {
  return OpenAIJsonSchemaResponseFormat(
    name: _requiredNonEmptyString(json['name'], path: 'json_schema.name'),
    description: _optionalString(
      json['description'],
      path: 'json_schema.description',
    ),
    schema: json['schema'] == null
        ? null
        : _requiredMap(json['schema'], path: 'json_schema.schema'),
    strict: _optionalBool(json['strict'], path: 'json_schema.strict'),
  );
}

List<OpenAIAssistant> _searchAssistants(
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

String _copyName(String? name) {
  if (name == null || name.isEmpty) {
    return 'Assistant Copy';
  }
  return '$name Copy';
}

String _requireNonEmptyId(
  String value, {
  required String parameterName,
}) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(
      value,
      parameterName,
      'Expected a non-empty OpenAI assistant ID.',
    );
  }
  return normalized;
}

Map<String, Object?> _requiredMap(
  Object? value, {
  required String path,
}) {
  if (value is Map<String, Object?>) {
    return value;
  }

  if (value is Map) {
    return Map<String, Object?>.from(value);
  }

  throw FormatException('Expected a JSON object at $path.');
}

Map<String, Object?>? _optionalMap(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }
  return _requiredMap(value, path: path);
}

List<Object?> _requiredList(
  Object? value, {
  required String path,
}) {
  if (value is List<Object?>) {
    return value;
  }

  if (value is List) {
    return List<Object?>.from(value);
  }

  throw FormatException('Expected a list at $path.');
}

List<Object?>? _optionalList(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }
  return _requiredList(value, path: path);
}

String _requiredNonEmptyString(
  Object? value, {
  required String path,
}) {
  final string = _optionalString(value, path: path);
  if (string == null || string.isEmpty) {
    throw FormatException('Expected a non-empty string at $path.');
  }
  return string;
}

String? _optionalString(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }

  if (value is String) {
    return value;
  }

  throw FormatException('Expected a string at $path.');
}

int _requiredInt(
  Object? value, {
  required String path,
}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  throw FormatException('Expected an int at $path.');
}

int? _optionalInt(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }
  return _requiredInt(value, path: path);
}

double? _optionalDouble(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  throw FormatException('Expected a number at $path.');
}

bool _requiredBool(
  Object? value, {
  required String path,
}) {
  if (value is bool) {
    return value;
  }
  throw FormatException('Expected a bool at $path.');
}

bool? _optionalBool(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }
  return _requiredBool(value, path: path);
}

Map<String, String>? _optionalStringMap(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }

  final map = _requiredMap(value, path: path);
  return map.map((key, value) {
    if (value is! String) {
      throw FormatException('Expected a string value at $path.$key.');
    }
    return MapEntry(key, value);
  });
}

List<String>? _optionalStringList(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }

  final list = _requiredList(value, path: path);
  return List<String>.generate(
    list.length,
    (index) {
      final item = list[index];
      if (item is! String) {
        throw FormatException('Expected a string at $path[$index].');
      }
      return item;
    },
    growable: false,
  );
}

DateTime _requiredEpochSecondsDateTime(
  Object? value, {
  required String path,
}) {
  return DateTime.fromMillisecondsSinceEpoch(
    _requiredInt(value, path: path) * 1000,
    isUtc: true,
  );
}
