part of 'openai_assistant_support.dart';

final class _OpenAIAssistantRequestSupport {
  const _OpenAIAssistantRequestSupport();

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

  DeleteAssistantResponse buildDeleteFailureResponse(String assistantId) {
    return DeleteAssistantResponse(
      id: assistantId,
      object: 'assistant.deleted',
      deleted: false,
    );
  }
}
