part of 'provider_compat.dart';

mixin OpenAIProviderAssistantsMixin implements AssistantCapability {
  OpenAIAssistants get _assistants;

  @override
  Future<Assistant> createAssistant(CreateAssistantRequest request) async {
    return _assistants.createAssistant(request);
  }

  @override
  Future<ListAssistantsResponse> listAssistants([
    ListAssistantsQuery? query,
  ]) async {
    return _assistants.listAssistants(query);
  }

  @override
  Future<Assistant> retrieveAssistant(String assistantId) async {
    return _assistants.retrieveAssistant(assistantId);
  }

  @override
  Future<Assistant> modifyAssistant(
    String assistantId,
    ModifyAssistantRequest request,
  ) async {
    return _assistants.modifyAssistant(assistantId, request);
  }

  @override
  Future<DeleteAssistantResponse> deleteAssistant(String assistantId) async {
    return _assistants.deleteAssistant(assistantId);
  }
}
