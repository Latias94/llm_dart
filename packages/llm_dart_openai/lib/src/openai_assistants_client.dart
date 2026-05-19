import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_assistants_lifecycle_models.dart';
import 'openai_assistants_thread_models.dart';
import 'openai_assistants_transport.dart';
import 'openai_family_profile.dart';
import 'openai_family_url_support.dart';
import 'openai_json_support.dart';
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
}
