import '../../../../models/tool_models.dart';
import 'assistant_models.dart';

/// Local utility support for the OpenAI Assistants compatibility shell.
///
/// This keeps endpoint-adjacent but non-transport logic out of the capability
/// shell so the shell can stay focused on API orchestration.
final class OpenAIAssistantSupport {
  const OpenAIAssistantSupport();

  String buildListEndpoint(ListAssistantsQuery? query) {
    if (query == null) {
      return 'assistants';
    }

    final queryParams = query.toQueryParameters();
    if (queryParams.isEmpty) {
      return 'assistants';
    }

    final queryString = queryParams.entries
        .map((entry) => '${entry.key}=${Uri.encodeComponent('${entry.value}')}')
        .join('&');
    return 'assistants?$queryString';
  }

  Assistant? findAssistantByName(
    List<Assistant> assistants,
    String name,
  ) {
    for (final assistant in assistants) {
      if (assistant.name == name) {
        return assistant;
      }
    }

    return null;
  }

  List<Assistant> filterByModel(
    List<Assistant> assistants,
    String model,
  ) {
    return assistants.where((assistant) => assistant.model == model).toList();
  }

  CreateAssistantRequest buildCloneRequest(
    Assistant original, {
    required String assistantId,
    String? newName,
    String? newDescription,
    Map<String, String>? additionalMetadata,
  }) {
    return CreateAssistantRequest(
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
  }

  ModifyAssistantRequest buildInstructionsUpdateRequest(
    String newInstructions,
  ) {
    return ModifyAssistantRequest(
      instructions: newInstructions,
    );
  }

  ModifyAssistantRequest buildToolsUpdateRequest(
    List<AssistantTool> tools,
  ) {
    return ModifyAssistantRequest(
      tools: tools,
    );
  }

  ModifyAssistantRequest buildToolResourcesUpdateRequest(
    ToolResources toolResources,
  ) {
    return ModifyAssistantRequest(
      toolResources: toolResources,
    );
  }

  ModifyAssistantRequest buildMetadataUpdateRequest(
    Map<String, String> metadata,
  ) {
    return ModifyAssistantRequest(
      metadata: metadata,
    );
  }

  List<AssistantTool> mergeTools(
    List<AssistantTool> currentTools,
    List<AssistantTool> toolsToAdd,
  ) {
    return [...currentTools, ...toolsToAdd];
  }

  List<AssistantTool> removeToolsByType(
    List<AssistantTool> currentTools,
    List<String> toolTypes,
  ) {
    return currentTools
        .where(
          (tool) => !toolTypes.contains(tool.type.value),
        )
        .toList();
  }

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

  List<Assistant> searchAssistants(
    List<Assistant> assistants, {
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
      }).toList();
    }

    if (model != null) {
      filtered =
          filtered.where((assistant) => assistant.model == model).toList();
    }

    if (requiredTools != null && requiredTools.isNotEmpty) {
      filtered = filtered.where((assistant) {
        final assistantTools = assistant.tools.map((tool) => tool.type.value);
        return requiredTools.every(assistantTools.contains);
      }).toList();
    }

    if (metadataFilters != null && metadataFilters.isNotEmpty) {
      filtered = filtered.where((assistant) {
        final metadata = assistant.metadata ?? <String, String>{};
        return metadataFilters.entries
            .every((filter) => metadata[filter.key] == filter.value);
      }).toList();
    }

    return filtered;
  }

  DeleteAssistantResponse buildDeleteFailureResponse(String assistantId) {
    return DeleteAssistantResponse(
      id: assistantId,
      object: 'assistant.deleted',
      deleted: false,
    );
  }

  Map<String, dynamic> exportAssistant(Assistant assistant) {
    return {
      'name': assistant.name,
      'description': assistant.description,
      'model': assistant.model,
      'instructions': assistant.instructions,
      'tools': assistant.tools.map((tool) => tool.toJson()).toList(),
      'tool_resources': assistant.toolResources?.toJson(),
      'metadata': assistant.metadata,
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  CreateAssistantRequest buildImportRequest(Map<String, dynamic> config) {
    return CreateAssistantRequest(
      model: config['model'] as String,
      name: config['name'] as String?,
      description: config['description'] as String?,
      instructions: config['instructions'] as String?,
      tools: (config['tools'] as List?)
          ?.map(
            (tool) => parseToolFromJson(
              tool as Map<String, dynamic>,
            ),
          )
          .toList(),
      toolResources: config['tool_resources'] != null
          ? ToolResources.fromJson(
              config['tool_resources'] as Map<String, dynamic>,
            )
          : null,
      metadata: {
        ...?(config['metadata'] as Map<String, String>?),
        'imported_at': DateTime.now().toIso8601String(),
      },
    );
  }

  AssistantTool parseToolFromJson(Map<String, dynamic> json) {
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
