import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_assistants_models.dart';
import 'openai_assistants_thread_models.dart';
import 'openai_assistants_transport.dart';
import 'openai_family_profile.dart';
import 'openai_family_url_support.dart';
import 'openai_json_support.dart';
import 'openai_profile_boundary.dart';

export 'openai_assistants_models.dart'
    show
        OpenAIAssistant,
        OpenAIAssistantCodeInterpreterResources,
        OpenAIAssistantCodeInterpreterTool,
        OpenAIAssistantFileSearchResources,
        OpenAIAssistantFileSearchTool,
        OpenAIAssistantFunctionTool,
        OpenAIAssistantRawTool,
        OpenAIAssistantResponseFormat,
        OpenAIAssistantTool,
        OpenAIAssistantToolResources,
        OpenAIAssistantToolType,
        OpenAIAssistantVectorStoreRequest,
        OpenAICreateAssistantRequest,
        OpenAIDeleteAssistantResponse,
        OpenAIListAssistantsQuery,
        OpenAIListAssistantsResponse,
        OpenAIModifyAssistantRequest;
export 'openai_assistants_thread_models.dart'
    show
        OpenAICreateRunRequest,
        OpenAICreateThreadAndRunRequest,
        OpenAICreateThreadMessageRequest,
        OpenAICreateThreadRequest,
        OpenAIListRunStepsQuery,
        OpenAIListRunStepsResponse,
        OpenAIListRunsQuery,
        OpenAIListRunsResponse,
        OpenAIListThreadMessagesQuery,
        OpenAIListThreadMessagesResponse,
        OpenAIModifyRunRequest,
        OpenAIModifyThreadMessageRequest,
        OpenAIModifyThreadRequest,
        OpenAIRunStep,
        OpenAIRunToolOutput,
        OpenAISubmitToolOutputsRequest,
        OpenAIThread,
        OpenAIThreadDeleteResult,
        OpenAIThreadMessage,
        OpenAIThreadMessageDeleteResult,
        OpenAIThreadRun;
export 'openai_assistants_transport.dart' show OpenAIAssistantsSettings;

final class OpenAIAssistantsClient {
  final String apiKey;
  final String baseUrl;
  final OpenAIFamilyProfile profile;
  final TransportClient transport;
  final OpenAIAssistantsSettings settings;

  late final OpenAIAssistantsTransportSupport _requestSupport =
      OpenAIAssistantsTransportSupport(
    apiKey: apiKey,
    baseUrl: baseUrl,
    profile: profile,
    settings: settings,
  );

  OpenAIAssistantsClient({
    required this.apiKey,
    required this.profile,
    required this.transport,
    this.settings = const OpenAIAssistantsSettings(),
    String? baseUrl,
  }) : baseUrl = normalizeOpenAIFamilyBaseUrl(baseUrl, profile) {
    requireOpenAIProfile(profile, featureName: 'OpenAI assistants client');
  }

  Uri assistantsUri([OpenAIListAssistantsQuery? query]) {
    return _requestSupport.assistantsUri(query);
  }

  Uri assistantUri(String assistantId) {
    return _requestSupport.assistantUri(assistantId);
  }

  Uri get threadsUri => _requestSupport.threadsUri;

  Uri threadUri(String threadId) {
    return _requestSupport.threadUri(threadId);
  }

  Uri threadMessagesUri(
    String threadId, [
    OpenAIListThreadMessagesQuery? query,
  ]) {
    return _requestSupport.threadMessagesUri(threadId, query);
  }

  Uri threadMessageUri(String threadId, String messageId) {
    return _requestSupport.threadMessageUri(threadId, messageId);
  }

  Uri threadRunsUri(String threadId, [OpenAIListRunsQuery? query]) {
    return _requestSupport.threadRunsUri(threadId, query);
  }

  Uri threadRunUri(String threadId, String runId) {
    return _requestSupport.threadRunUri(threadId, runId);
  }

  Uri threadRunStepsUri(
    String threadId,
    String runId, [
    OpenAIListRunStepsQuery? query,
  ]) {
    return _requestSupport.threadRunStepsUri(threadId, runId, query);
  }

  Uri threadRunStepUri(String threadId, String runId, String stepId) {
    return _requestSupport.threadRunStepUri(threadId, runId, stepId);
  }

  Future<T> _sendJsonModel<T>({
    required Uri uri,
    required TransportMethod method,
    required String responseName,
    required T Function(Map<String, Object?> json) decode,
    Object? body,
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
    bool contentType = false,
  }) async {
    final response = await transport.send(
      _requestSupport.jsonRequest(
        uri: uri,
        method: method,
        extraHeaders: headers,
        contentType: contentType,
        body: body,
        timeout: timeout,
        maxRetries: maxRetries,
        cancellation: cancellation,
      ),
    );

    return decode(
      decodeOpenAIJsonObject(response.body, responseName: responseName),
    );
  }

  Future<OpenAIAssistant> createAssistant(
    OpenAICreateAssistantRequest request, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    return _sendJsonModel(
      uri: assistantsUri(),
      method: TransportMethod.post,
      responseName: 'assistant create response',
      decode: (json) => OpenAIAssistant.fromJson(json),
      contentType: true,
      body: request.toJson(),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<OpenAIThread> createThread({
    OpenAICreateThreadRequest request = const OpenAICreateThreadRequest(),
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    return _sendJsonModel(
      uri: threadsUri,
      method: TransportMethod.post,
      responseName: 'thread create response',
      decode: (json) => OpenAIThread.fromJson(json),
      contentType: true,
      body: request.toJson(),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<OpenAIThread> retrieveThread(
    String threadId, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    return _sendJsonModel(
      uri: threadUri(threadId),
      method: TransportMethod.get,
      responseName: 'thread retrieve response',
      decode: (json) => OpenAIThread.fromJson(json),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<OpenAIThread> modifyThread(
    String threadId,
    OpenAIModifyThreadRequest request, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    return _sendJsonModel(
      uri: threadUri(threadId),
      method: TransportMethod.post,
      responseName: 'thread modify response',
      decode: (json) => OpenAIThread.fromJson(json),
      contentType: true,
      body: request.toJson(),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<OpenAIThreadDeleteResult> deleteThread(
    String threadId, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    return _sendJsonModel(
      uri: threadUri(threadId),
      method: TransportMethod.delete,
      responseName: 'thread delete response',
      decode: (json) => OpenAIThreadDeleteResult.fromJson(json),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<OpenAIThreadMessage> createThreadMessage(
    String threadId,
    OpenAICreateThreadMessageRequest request, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    return _sendJsonModel(
      uri: threadMessagesUri(threadId),
      method: TransportMethod.post,
      responseName: 'thread message create response',
      decode: (json) => OpenAIThreadMessage.fromJson(json),
      contentType: true,
      body: request.toJson(),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<OpenAIListThreadMessagesResponse> listThreadMessages(
    String threadId, {
    OpenAIListThreadMessagesQuery? query,
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    return _sendJsonModel(
      uri: threadMessagesUri(threadId, query),
      method: TransportMethod.get,
      responseName: 'thread message list response',
      decode: (json) => OpenAIListThreadMessagesResponse.fromJson(json),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<OpenAIThreadMessage> retrieveThreadMessage(
    String threadId,
    String messageId, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    return _sendJsonModel(
      uri: threadMessageUri(threadId, messageId),
      method: TransportMethod.get,
      responseName: 'thread message retrieve response',
      decode: (json) => OpenAIThreadMessage.fromJson(json),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<OpenAIThreadMessage> modifyThreadMessage(
    String threadId,
    String messageId,
    OpenAIModifyThreadMessageRequest request, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    return _sendJsonModel(
      uri: threadMessageUri(threadId, messageId),
      method: TransportMethod.post,
      responseName: 'thread message modify response',
      decode: (json) => OpenAIThreadMessage.fromJson(json),
      contentType: true,
      body: request.toJson(),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<OpenAIThreadMessageDeleteResult> deleteThreadMessage(
    String threadId,
    String messageId, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    return _sendJsonModel(
      uri: threadMessageUri(threadId, messageId),
      method: TransportMethod.delete,
      responseName: 'thread message delete response',
      decode: (json) => OpenAIThreadMessageDeleteResult.fromJson(json),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<OpenAIThreadRun> createThreadRun(
    String threadId,
    OpenAICreateRunRequest request, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    return _sendJsonModel(
      uri: threadRunsUri(threadId),
      method: TransportMethod.post,
      responseName: 'thread run create response',
      decode: (json) => OpenAIThreadRun.fromJson(json),
      contentType: true,
      body: request.toJson(),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<OpenAIThreadRun> createThreadAndRun(
    OpenAICreateThreadAndRunRequest request, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    return _sendJsonModel(
      uri: _requestSupport.createThreadAndRunUri(),
      method: TransportMethod.post,
      responseName: 'thread and run create response',
      decode: (json) => OpenAIThreadRun.fromJson(json),
      contentType: true,
      body: request.toJson(),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<OpenAIListRunsResponse> listThreadRuns(
    String threadId, {
    OpenAIListRunsQuery? query,
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    return _sendJsonModel(
      uri: threadRunsUri(threadId, query),
      method: TransportMethod.get,
      responseName: 'thread run list response',
      decode: (json) => OpenAIListRunsResponse.fromJson(json),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<OpenAIThreadRun> retrieveThreadRun(
    String threadId,
    String runId, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    return _sendJsonModel(
      uri: threadRunUri(threadId, runId),
      method: TransportMethod.get,
      responseName: 'thread run retrieve response',
      decode: (json) => OpenAIThreadRun.fromJson(json),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<OpenAIThreadRun> modifyThreadRun(
    String threadId,
    String runId,
    OpenAIModifyRunRequest request, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    return _sendJsonModel(
      uri: threadRunUri(threadId, runId),
      method: TransportMethod.post,
      responseName: 'thread run modify response',
      decode: (json) => OpenAIThreadRun.fromJson(json),
      contentType: true,
      body: request.toJson(),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<OpenAIThreadRun> cancelThreadRun(
    String threadId,
    String runId, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    return _sendJsonModel(
      uri: _requestSupport.cancelThreadRunUri(threadId, runId),
      method: TransportMethod.post,
      responseName: 'thread run cancel response',
      decode: (json) => OpenAIThreadRun.fromJson(json),
      contentType: true,
      body: const <String, Object?>{},
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<OpenAIThreadRun> submitThreadRunToolOutputs(
    String threadId,
    String runId,
    OpenAISubmitToolOutputsRequest request, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    return _sendJsonModel(
      uri: _requestSupport.submitThreadRunToolOutputsUri(threadId, runId),
      method: TransportMethod.post,
      responseName: 'thread run submit tool outputs response',
      decode: (json) => OpenAIThreadRun.fromJson(json),
      contentType: true,
      body: request.toJson(),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<OpenAIListRunStepsResponse> listThreadRunSteps(
    String threadId,
    String runId, {
    OpenAIListRunStepsQuery? query,
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    return _sendJsonModel(
      uri: threadRunStepsUri(threadId, runId, query),
      method: TransportMethod.get,
      responseName: 'thread run step list response',
      decode: (json) => OpenAIListRunStepsResponse.fromJson(json),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<OpenAIRunStep> retrieveThreadRunStep(
    String threadId,
    String runId,
    String stepId, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    return _sendJsonModel(
      uri: threadRunStepUri(threadId, runId, stepId),
      method: TransportMethod.get,
      responseName: 'thread run step retrieve response',
      decode: (json) => OpenAIRunStep.fromJson(json),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<OpenAIListAssistantsResponse> listAssistants({
    OpenAIListAssistantsQuery? query,
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    return _sendJsonModel(
      uri: assistantsUri(query),
      method: TransportMethod.get,
      responseName: 'assistant list response',
      decode: (json) => OpenAIListAssistantsResponse.fromJson(json),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<OpenAIAssistant> retrieveAssistant(
    String assistantId, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    return _sendJsonModel(
      uri: assistantUri(assistantId),
      method: TransportMethod.get,
      responseName: 'assistant retrieve response',
      decode: (json) => OpenAIAssistant.fromJson(json),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
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
    return _sendJsonModel(
      uri: assistantUri(assistantId),
      method: TransportMethod.post,
      responseName: 'assistant modify response',
      decode: (json) => OpenAIAssistant.fromJson(json),
      contentType: true,
      body: request.toJson(),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<OpenAIDeleteAssistantResponse> deleteAssistant(
    String assistantId, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    return _sendJsonModel(
      uri: assistantUri(assistantId),
      method: TransportMethod.delete,
      responseName: 'assistant delete response',
      decode: (json) => OpenAIDeleteAssistantResponse.fromJson(json),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
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
