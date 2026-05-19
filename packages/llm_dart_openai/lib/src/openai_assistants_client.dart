import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_assistants_lifecycle_clients.dart';
import 'openai_assistants_lifecycle_models.dart';
import 'openai_assistants_thread_models.dart';
import 'openai_assistants_transport.dart';
import 'openai_family_profile.dart';
import 'openai_family_url_support.dart';
import 'openai_profile_boundary.dart';

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
  late final OpenAIAssistantsAssistantLifecycle _assistants =
      OpenAIAssistantsAssistantLifecycle(
    transport: transport,
    requestSupport: _requestSupport,
  );
  late final OpenAIAssistantsThreadLifecycle _threads =
      OpenAIAssistantsThreadLifecycle(
    transport: transport,
    requestSupport: _requestSupport,
  );
  late final OpenAIAssistantsMessageLifecycle _messages =
      OpenAIAssistantsMessageLifecycle(
    transport: transport,
    requestSupport: _requestSupport,
  );
  late final OpenAIAssistantsRunLifecycle _runs = OpenAIAssistantsRunLifecycle(
    transport: transport,
    requestSupport: _requestSupport,
  );
  late final OpenAIAssistantsRunStepLifecycle _runSteps =
      OpenAIAssistantsRunStepLifecycle(
    transport: transport,
    requestSupport: _requestSupport,
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

  Future<OpenAIAssistant> createAssistant(
    OpenAICreateAssistantRequest request, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    return _assistants.create(
      request,
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
    return _threads.create(
      request: request,
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
    return _threads.retrieve(
      threadId,
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
    return _threads.modify(
      threadId,
      request,
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
    return _threads.delete(
      threadId,
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
    return _messages.create(
      threadId,
      request,
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
    return _messages.list(
      threadId,
      query: query,
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
    return _messages.retrieve(
      threadId,
      messageId,
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
    return _messages.modify(
      threadId,
      messageId,
      request,
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
    return _messages.delete(
      threadId,
      messageId,
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
    return _runs.create(
      threadId,
      request,
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
    return _runs.createThreadAndRun(
      request,
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
    return _runs.list(
      threadId,
      query: query,
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
    return _runs.retrieve(
      threadId,
      runId,
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
    return _runs.modify(
      threadId,
      runId,
      request,
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
    return _runs.cancel(
      threadId,
      runId,
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
    return _runs.submitToolOutputs(
      threadId,
      runId,
      request,
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
    return _runSteps.list(
      threadId,
      runId,
      query: query,
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
    return _runSteps.retrieve(
      threadId,
      runId,
      stepId,
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
    return _assistants.list(
      query: query,
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
    return _assistants.retrieve(
      assistantId,
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
    return _assistants.modify(
      assistantId,
      request,
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
    return _assistants.delete(
      assistantId,
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }
}
