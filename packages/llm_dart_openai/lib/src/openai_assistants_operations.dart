import 'openai_assistants_client.dart';
import 'openai_assistants_lifecycle_models.dart';
import 'openai_assistants_tool_models.dart';
import 'openai_assistants_tool_resources_models.dart';

extension OpenAIAssistantsOperations on OpenAIAssistantsClient {
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
    return openAISearchAssistants(
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
      openAIAssistantCreateRequestFromImportConfig(
        config,
        importedAt: DateTime.now().toUtc().toIso8601String(),
      ),
    );
  }
}

String _copyName(String? name) {
  if (name == null || name.isEmpty) {
    return 'Assistant Copy';
  }
  return '$name Copy';
}
