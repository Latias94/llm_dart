import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_assistants_lifecycle_client_support.dart';
import 'openai_assistants_thread_models.dart';
import 'openai_assistants_transport.dart';

final class OpenAIAssistantsRunLifecycle {
  final TransportClient transport;
  final OpenAIAssistantsTransportSupport requestSupport;

  const OpenAIAssistantsRunLifecycle({
    required this.transport,
    required this.requestSupport,
  });

  Future<OpenAIThreadRun> create(
    String threadId,
    OpenAICreateRunRequest request, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) {
    return sendOpenAIAssistantsJsonModel(
      transport: transport,
      requestSupport: requestSupport,
      uri: requestSupport.threadRunsUri(threadId),
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
  }) {
    return sendOpenAIAssistantsJsonModel(
      transport: transport,
      requestSupport: requestSupport,
      uri: requestSupport.createThreadAndRunUri(),
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

  Future<OpenAIListRunsResponse> list(
    String threadId, {
    OpenAIListRunsQuery? query,
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) {
    return sendOpenAIAssistantsJsonModel(
      transport: transport,
      requestSupport: requestSupport,
      uri: requestSupport.threadRunsUri(threadId, query),
      method: TransportMethod.get,
      responseName: 'thread run list response',
      decode: (json) => OpenAIListRunsResponse.fromJson(json),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<OpenAIThreadRun> retrieve(
    String threadId,
    String runId, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) {
    return sendOpenAIAssistantsJsonModel(
      transport: transport,
      requestSupport: requestSupport,
      uri: requestSupport.threadRunUri(threadId, runId),
      method: TransportMethod.get,
      responseName: 'thread run retrieve response',
      decode: (json) => OpenAIThreadRun.fromJson(json),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<OpenAIThreadRun> modify(
    String threadId,
    String runId,
    OpenAIModifyRunRequest request, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) {
    return sendOpenAIAssistantsJsonModel(
      transport: transport,
      requestSupport: requestSupport,
      uri: requestSupport.threadRunUri(threadId, runId),
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

  Future<OpenAIThreadRun> cancel(
    String threadId,
    String runId, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) {
    return sendOpenAIAssistantsJsonModel(
      transport: transport,
      requestSupport: requestSupport,
      uri: requestSupport.cancelThreadRunUri(threadId, runId),
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

  Future<OpenAIThreadRun> submitToolOutputs(
    String threadId,
    String runId,
    OpenAISubmitToolOutputsRequest request, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) {
    return sendOpenAIAssistantsJsonModel(
      transport: transport,
      requestSupport: requestSupport,
      uri: requestSupport.submitThreadRunToolOutputsUri(threadId, runId),
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
}
