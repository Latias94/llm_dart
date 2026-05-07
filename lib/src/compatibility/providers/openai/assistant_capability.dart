import '../../../../models/assistant_models.dart';

/// Assistant management capability for OpenAI providers.
abstract class AssistantCapability {
  /// Create an assistant.
  Future<Assistant> createAssistant(CreateAssistantRequest request);

  /// List assistants.
  Future<ListAssistantsResponse> listAssistants([ListAssistantsQuery? query]);

  /// Retrieve an assistant.
  Future<Assistant> retrieveAssistant(String assistantId);

  /// Modify an assistant.
  Future<Assistant> modifyAssistant(
    String assistantId,
    ModifyAssistantRequest request,
  );

  /// Delete an assistant.
  Future<DeleteAssistantResponse> deleteAssistant(String assistantId);
}
