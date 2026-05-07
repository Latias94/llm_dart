import '../../../../core/capability.dart';
import 'client.dart';
import '../../../../providers/openai/config.dart';
import 'assistant_models.dart';
import 'openai_assistant_support.dart';

/// OpenAI Assistant Management capability implementation
///
/// This module handles assistant creation, management, and interaction
/// for OpenAI providers.
class OpenAIAssistants implements AssistantCapability {
  final OpenAIClient client;
  final OpenAIConfig config;
  final OpenAIAssistantSupport _support = const OpenAIAssistantSupport();

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
    final endpoint = _support.buildListEndpoint(query);
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
    return _support.findAssistantByName(response.data, name);
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
    return _support.filterByModel(response.data, model);
  }

  /// Clone an assistant with modifications
  Future<Assistant> cloneAssistant(
    String assistantId, {
    String? newName,
    String? newDescription,
    Map<String, String>? additionalMetadata,
  }) async {
    final original = await retrieveAssistant(assistantId);
    final createRequest = _support.buildCloneRequest(
      original,
      assistantId: assistantId,
      newName: newName,
      newDescription: newDescription,
      additionalMetadata: additionalMetadata,
    );
    return await createAssistant(createRequest);
  }

  /// Update assistant instructions
  Future<Assistant> updateInstructions(
    String assistantId,
    String newInstructions,
  ) async {
    final modifyRequest = _support.buildInstructionsUpdateRequest(
      newInstructions,
    );
    return await modifyAssistant(assistantId, modifyRequest);
  }

  /// Add tools to assistant
  Future<Assistant> addTools(
    String assistantId,
    List<AssistantTool> tools,
  ) async {
    final current = await retrieveAssistant(assistantId);
    final updatedTools = _support.mergeTools(current.tools, tools);
    final modifyRequest = _support.buildToolsUpdateRequest(
      updatedTools,
    );
    return await modifyAssistant(assistantId, modifyRequest);
  }

  /// Remove tools from assistant
  Future<Assistant> removeTools(
    String assistantId,
    List<String> toolTypes,
  ) async {
    final current = await retrieveAssistant(assistantId);
    final updatedTools = _support.removeToolsByType(
      current.tools,
      toolTypes,
    );
    final modifyRequest = _support.buildToolsUpdateRequest(
      updatedTools,
    );
    return await modifyAssistant(assistantId, modifyRequest);
  }

  /// Update assistant tool resources
  Future<Assistant> updateToolResources(
    String assistantId,
    ToolResources toolResources,
  ) async {
    final modifyRequest = _support.buildToolResourcesUpdateRequest(
      toolResources,
    );
    return await modifyAssistant(assistantId, modifyRequest);
  }

  /// Update assistant metadata
  Future<Assistant> updateMetadata(
    String assistantId,
    Map<String, String> metadata,
  ) async {
    final modifyRequest = _support.buildMetadataUpdateRequest(
      metadata,
    );
    return await modifyAssistant(assistantId, modifyRequest);
  }

  /// Get assistant usage statistics (if available in metadata)
  Map<String, dynamic> getAssistantStats(Assistant assistant) {
    return _support.getAssistantStats(assistant);
  }

  /// Search assistants by criteria
  Future<List<Assistant>> searchAssistants({
    String? namePattern,
    String? model,
    List<String>? requiredTools,
    Map<String, String>? metadataFilters,
  }) async {
    final response = await listAssistants();
    return _support.searchAssistants(
      response.data,
      namePattern: namePattern,
      model: model,
      requiredTools: requiredTools,
      metadataFilters: metadataFilters,
    );
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
        results.add(_support.buildDeleteFailureResponse(assistantId));
      }
    }

    return results;
  }

  /// Export assistant configuration
  Map<String, dynamic> exportAssistant(Assistant assistant) {
    return _support.exportAssistant(assistant);
  }

  /// Import assistant from configuration
  Future<Assistant> importAssistant(Map<String, dynamic> config) async {
    final createRequest = _support.buildImportRequest(config);
    return await createAssistant(createRequest);
  }
}
