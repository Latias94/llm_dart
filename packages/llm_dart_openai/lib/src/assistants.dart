import 'package:llm_dart_core/core/capability.dart';
import 'package:llm_dart_core/models/assistant_models.dart';
import 'package:llm_dart_core/models/tool_models.dart';
import 'client.dart';
import 'config.dart';

/// OpenAI Assistant Management capability implementation
///
/// This module handles assistant creation, management, and interaction
/// for OpenAI providers.
class OpenAIAssistants implements AssistantCapability {
  final OpenAIClient client;
  final OpenAIConfig config;

  OpenAIAssistants(this.client, this.config);

  @override
  Future<Assistant> createAssistant(CreateAssistantRequest request) async {
    final requestBody = request.toJson();
    final responseData = await client.postJson('assistants', requestBody);
    return Assistant.fromJson(responseData);
  }

  @override
  Future<ListAssistantsResponse> listAssistants(
      [ListAssistantsQuery? query]) async {
    String endpoint = 'assistants';

    if (query != null) {
      final queryParams = <String, String>{};
      if (query.limit != null) queryParams['limit'] = query.limit.toString();
      if (query.order != null) queryParams['order'] = query.order!;
      if (query.after != null) queryParams['after'] = query.after!;
      if (query.before != null) queryParams['before'] = query.before!;

      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
            .join('&');
        endpoint = '$endpoint?$queryString';
      }
    }

    final responseData = await client.get(endpoint);
    return ListAssistantsResponse.fromJson(responseData);
  }

  @override
  Future<Assistant> retrieveAssistant(String assistantId) async {
    final responseData = await client.get('assistants/$assistantId');
    return Assistant.fromJson(responseData);
  }

  @override
  Future<Assistant> modifyAssistant(
    String assistantId,
    ModifyAssistantRequest request,
  ) async {
    final requestBody = request.toJson();
    final responseData =
        await client.postJson('assistants/$assistantId', requestBody);
    return Assistant.fromJson(responseData);
  }

  @override
  Future<DeleteAssistantResponse> deleteAssistant(String assistantId) async {
    final responseData = await client.delete('assistants/$assistantId');
    return DeleteAssistantResponse.fromJson(responseData);
  }

  /// Get assistant by name
  Future<Assistant?> getAssistantByName(String name) async {
    final response = await listAssistants();

    for (final assistant in response.data) {
      if (assistant.name == name) {
        return assistant;
      }
    }

    return null;
  }

  /// Check if assistant exists
  Future<bool> assistantExists(String assistantId) async {
    try {
      await retrieveAssistant(assistantId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get assistants by model
  Future<List<Assistant>> getAssistantsByModel(String model) async {
    final response = await listAssistants();
    return response.data
        .where((assistant) => assistant.model == model)
        .toList();
  }

  /// Clone an assistant with modifications
  Future<Assistant> cloneAssistant(
    String assistantId, {
    String? newName,
    String? newDescription,
    Map<String, String>? additionalMetadata,
  }) async {
    final original = await retrieveAssistant(assistantId);

    final createRequest = CreateAssistantRequest(
      model: original.model,
      name: newName ?? '${original.name} (Copy)',
      description: newDescription ?? original.description,
      instructions: original.instructions,
      tools: original.tools,
      toolResources: original.toolResources,
      metadata: {
        ...?original.metadata,
        ...?additionalMetadata,
        'cloned_from': assistantId,
        'cloned_at': DateTime.now().toIso8601String(),
      },
    );

    return await createAssistant(createRequest);
  }

  /// Update assistant instructions
  Future<Assistant> updateInstructions(
    String assistantId,
    String newInstructions,
  ) async {
    final modifyRequest = ModifyAssistantRequest(
      instructions: newInstructions,
    );

    return await modifyAssistant(assistantId, modifyRequest);
  }

  /// Add tools to assistant
  Future<Assistant> addTools(
    String assistantId,
    List<AssistantTool> tools,
  ) async {
    final current = await retrieveAssistant(assistantId);
    final updatedTools = [...current.tools, ...tools];

    final modifyRequest = ModifyAssistantRequest(
      tools: updatedTools,
    );

    return await modifyAssistant(assistantId, modifyRequest);
  }

  /// Remove tools from assistant
  Future<Assistant> removeTools(
    String assistantId,
    List<String> toolTypes,
  ) async {
    final current = await retrieveAssistant(assistantId);
    final updatedTools = current.tools
        .where(
          (tool) => !toolTypes.contains(tool.type.value),
        )
        .toList();

    final modifyRequest = ModifyAssistantRequest(
      tools: updatedTools,
    );

    return await modifyAssistant(assistantId, modifyRequest);
  }

  /// Update assistant tool resources
  Future<Assistant> updateToolResources(
    String assistantId,
    ToolResources toolResources,
  ) async {
    final modifyRequest = ModifyAssistantRequest(
      toolResources: toolResources,
    );

    return await modifyAssistant(assistantId, modifyRequest);
  }

  /// Update assistant metadata
  Future<Assistant> updateMetadata(
    String assistantId,
    Map<String, String> metadata,
  ) async {
    final modifyRequest = ModifyAssistantRequest(
      metadata: metadata,
    );

    return await modifyAssistant(assistantId, modifyRequest);
  }

  /// Get assistant usage statistics (if available in metadata)
  Map<String, dynamic> getAssistantStats(Assistant assistant) {
    final metadata = assistant.metadata ?? {};

    return {
      'created_at': assistant.createdAt,
      'total_conversations':
          int.tryParse(metadata['total_conversations'] ?? '0') ?? 0,
      'total_messages': int.tryParse(metadata['total_messages'] ?? '0') ?? 0,
      'last_used': metadata['last_used'],
      'usage_count': int.tryParse(metadata['usage_count'] ?? '0') ?? 0,
      'average_response_time':
          double.tryParse(metadata['avg_response_time'] ?? '0') ?? 0.0,
    };
  }

  /// Search assistants by criteria
  Future<List<Assistant>> searchAssistants({
    String? namePattern,
    String? model,
    List<String>? requiredTools,
    Map<String, String>? metadataFilters,
  }) async {
    final response = await listAssistants();
    var assistants = response.data;

    // Filter by name pattern
    if (namePattern != null) {
      final regex = RegExp(namePattern, caseSensitive: false);
      assistants = assistants
          .where((a) => a.name != null && regex.hasMatch(a.name!))
          .toList();
    }

    // Filter by model
    if (model != null) {
      assistants = assistants.where((a) => a.model == model).toList();
    }

    // Filter by required tools
    if (requiredTools != null && requiredTools.isNotEmpty) {
      assistants = assistants.where((a) {
        final assistantTools = a.tools.map((t) => t.type.value).toSet();
        return requiredTools.every((tool) => assistantTools.contains(tool));
      }).toList();
    }

    // Filter by metadata
    if (metadataFilters != null && metadataFilters.isNotEmpty) {
      assistants = assistants.where((a) {
        final metadata = a.metadata ?? <String, String>{};
        return metadataFilters.entries
            .every((filter) => metadata[filter.key] == filter.value);
      }).toList();
    }

    return assistants;
  }

  /// Batch delete assistants
  Future<List<DeleteAssistantResponse>> deleteAssistants(
    List<String> assistantIds,
  ) async {
    final results = <DeleteAssistantResponse>[];

    for (final assistantId in assistantIds) {
      try {
        final result = await deleteAssistant(assistantId);
        results.add(result);
      } catch (e) {
        // Continue with other assistants even if one fails
        results.add(DeleteAssistantResponse(
          id: assistantId,
          object: 'assistant.deleted',
          deleted: false,
        ));
      }
    }

    return results;
  }

  /// Export assistant configuration
  Map<String, dynamic> exportAssistant(Assistant assistant) {
    return {
      'name': assistant.name,
      'description': assistant.description,
      'model': assistant.model,
      'instructions': assistant.instructions,
      'tools': assistant.tools.map((t) => t.toJson()).toList(),
      'tool_resources': assistant.toolResources?.toJson(),
      'metadata': assistant.metadata,
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  /// Import assistant from configuration
  Future<Assistant> importAssistant(Map<String, dynamic> config) async {
    final createRequest = CreateAssistantRequest(
      model: config['model'] as String,
      name: config['name'] as String?,
      description: config['description'] as String?,
      instructions: config['instructions'] as String?,
      tools: (config['tools'] as List?)
          ?.map((t) => _parseToolFromJson(t as Map<String, dynamic>))
          .toList(),
      toolResources: config['tool_resources'] != null
          ? ToolResources.fromJson(
              config['tool_resources'] as Map<String, dynamic>)
          : null,
      metadata: {
        ...?(config['metadata'] as Map<String, String>?),
        'imported_at': DateTime.now().toIso8601String(),
      },
    );

    return await createAssistant(createRequest);
  }

  /// Helper method to parse tool from JSON
  AssistantTool _parseToolFromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'code_interpreter':
        return const CodeInterpreterTool();
      case 'file_search':
        return const FileSearchTool();
      case 'function':
        final functionData = json['function'] as Map<String, dynamic>;
        return AssistantFunctionTool(
          function: FunctionObject.fromJson(functionData),
        );
      default:
        throw ArgumentError('Unknown tool type: $type');
    }
  }
}
