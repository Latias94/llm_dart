import '../../../../models/assistant_models.dart';
import '../../../../models/tool_models.dart';

part 'openai_assistant_query_support.dart';
part 'openai_assistant_request_support.dart';
part 'openai_assistant_serialization_support.dart';
part 'openai_assistant_tool_support.dart';

/// Local utility support for the OpenAI Assistants compatibility shell.
///
/// This keeps endpoint-adjacent but non-transport logic out of the capability
/// shell so the shell can stay focused on API orchestration.
final class OpenAIAssistantSupport {
  static const _querySupport = _OpenAIAssistantQuerySupport();
  static const _requestSupport = _OpenAIAssistantRequestSupport();
  static const _toolSupport = _OpenAIAssistantToolSupport();
  static const _serializationSupport = _OpenAIAssistantSerializationSupport();

  const OpenAIAssistantSupport();

  String buildListEndpoint(ListAssistantsQuery? query) {
    return _querySupport.buildListEndpoint(query);
  }

  Assistant? findAssistantByName(
    List<Assistant> assistants,
    String name,
  ) {
    return _querySupport.findAssistantByName(assistants, name);
  }

  List<Assistant> filterByModel(
    List<Assistant> assistants,
    String model,
  ) {
    return _querySupport.filterByModel(assistants, model);
  }

  CreateAssistantRequest buildCloneRequest(
    Assistant original, {
    required String assistantId,
    String? newName,
    String? newDescription,
    Map<String, String>? additionalMetadata,
  }) {
    return _requestSupport.buildCloneRequest(
      original,
      assistantId: assistantId,
      newName: newName,
      newDescription: newDescription,
      additionalMetadata: additionalMetadata,
    );
  }

  ModifyAssistantRequest buildInstructionsUpdateRequest(
    String newInstructions,
  ) {
    return _requestSupport.buildInstructionsUpdateRequest(
      newInstructions,
    );
  }

  ModifyAssistantRequest buildToolsUpdateRequest(
    List<AssistantTool> tools,
  ) {
    return _requestSupport.buildToolsUpdateRequest(tools);
  }

  ModifyAssistantRequest buildToolResourcesUpdateRequest(
    ToolResources toolResources,
  ) {
    return _requestSupport.buildToolResourcesUpdateRequest(
      toolResources,
    );
  }

  ModifyAssistantRequest buildMetadataUpdateRequest(
    Map<String, String> metadata,
  ) {
    return _requestSupport.buildMetadataUpdateRequest(metadata);
  }

  List<AssistantTool> mergeTools(
    List<AssistantTool> currentTools,
    List<AssistantTool> toolsToAdd,
  ) {
    return _toolSupport.mergeTools(currentTools, toolsToAdd);
  }

  List<AssistantTool> removeToolsByType(
    List<AssistantTool> currentTools,
    List<String> toolTypes,
  ) {
    return _toolSupport.removeToolsByType(currentTools, toolTypes);
  }

  Map<String, dynamic> getAssistantStats(Assistant assistant) {
    return _serializationSupport.getAssistantStats(assistant);
  }

  List<Assistant> searchAssistants(
    List<Assistant> assistants, {
    String? namePattern,
    String? model,
    List<String>? requiredTools,
    Map<String, String>? metadataFilters,
  }) {
    return _querySupport.searchAssistants(
      assistants,
      namePattern: namePattern,
      model: model,
      requiredTools: requiredTools,
      metadataFilters: metadataFilters,
    );
  }

  DeleteAssistantResponse buildDeleteFailureResponse(String assistantId) {
    return _requestSupport.buildDeleteFailureResponse(assistantId);
  }

  Map<String, dynamic> exportAssistant(Assistant assistant) {
    return _serializationSupport.exportAssistant(assistant);
  }

  CreateAssistantRequest buildImportRequest(Map<String, dynamic> config) {
    return _serializationSupport.buildImportRequest(config);
  }

  AssistantTool parseToolFromJson(Map<String, dynamic> json) {
    return _toolSupport.parseToolFromJson(json);
  }
}
