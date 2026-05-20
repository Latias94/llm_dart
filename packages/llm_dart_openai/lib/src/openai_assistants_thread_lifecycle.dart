import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_assistants_lifecycle_client_support.dart';
import 'openai_assistants_thread_delete_model.dart';
import 'openai_assistants_thread_request_models.dart';
import 'openai_assistants_thread_response_model.dart';
import 'openai_assistants_transport.dart';

final class OpenAIAssistantsThreadLifecycle {
  final TransportClient transport;
  final OpenAIAssistantsTransportSupport requestSupport;

  const OpenAIAssistantsThreadLifecycle({
    required this.transport,
    required this.requestSupport,
  });

  Future<OpenAIThread> create({
    OpenAICreateThreadRequest request = const OpenAICreateThreadRequest(),
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) {
    return sendOpenAIAssistantsJsonModel(
      transport: transport,
      requestSupport: requestSupport,
      uri: requestSupport.threadsUri,
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

  Future<OpenAIThread> retrieve(
    String threadId, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) {
    return sendOpenAIAssistantsJsonModel(
      transport: transport,
      requestSupport: requestSupport,
      uri: requestSupport.threadUri(threadId),
      method: TransportMethod.get,
      responseName: 'thread retrieve response',
      decode: (json) => OpenAIThread.fromJson(json),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<OpenAIThread> modify(
    String threadId,
    OpenAIModifyThreadRequest request, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) {
    return sendOpenAIAssistantsJsonModel(
      transport: transport,
      requestSupport: requestSupport,
      uri: requestSupport.threadUri(threadId),
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

  Future<OpenAIThreadDeleteResult> delete(
    String threadId, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) {
    return sendOpenAIAssistantsJsonModel(
      transport: transport,
      requestSupport: requestSupport,
      uri: requestSupport.threadUri(threadId),
      method: TransportMethod.delete,
      responseName: 'thread delete response',
      decode: (json) => OpenAIThreadDeleteResult.fromJson(json),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }
}
