import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_assistants_lifecycle_client_support.dart';
import 'openai_assistants_message_delete_model.dart';
import 'openai_assistants_message_list_models.dart';
import 'openai_assistants_message_request_models.dart';
import 'openai_assistants_message_response_model.dart';
import 'openai_assistants_transport.dart';

final class OpenAIAssistantsMessageLifecycle {
  final TransportClient transport;
  final OpenAIAssistantsTransportSupport requestSupport;

  const OpenAIAssistantsMessageLifecycle({
    required this.transport,
    required this.requestSupport,
  });

  Future<OpenAIThreadMessage> create(
    String threadId,
    OpenAICreateThreadMessageRequest request, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) {
    return sendOpenAIAssistantsJsonModel(
      transport: transport,
      requestSupport: requestSupport,
      uri: requestSupport.threadMessagesUri(threadId),
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

  Future<OpenAIListThreadMessagesResponse> list(
    String threadId, {
    OpenAIListThreadMessagesQuery? query,
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) {
    return sendOpenAIAssistantsJsonModel(
      transport: transport,
      requestSupport: requestSupport,
      uri: requestSupport.threadMessagesUri(threadId, query),
      method: TransportMethod.get,
      responseName: 'thread message list response',
      decode: (json) => OpenAIListThreadMessagesResponse.fromJson(json),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<OpenAIThreadMessage> retrieve(
    String threadId,
    String messageId, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) {
    return sendOpenAIAssistantsJsonModel(
      transport: transport,
      requestSupport: requestSupport,
      uri: requestSupport.threadMessageUri(threadId, messageId),
      method: TransportMethod.get,
      responseName: 'thread message retrieve response',
      decode: (json) => OpenAIThreadMessage.fromJson(json),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<OpenAIThreadMessage> modify(
    String threadId,
    String messageId,
    OpenAIModifyThreadMessageRequest request, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) {
    return sendOpenAIAssistantsJsonModel(
      transport: transport,
      requestSupport: requestSupport,
      uri: requestSupport.threadMessageUri(threadId, messageId),
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

  Future<OpenAIThreadMessageDeleteResult> delete(
    String threadId,
    String messageId, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) {
    return sendOpenAIAssistantsJsonModel(
      transport: transport,
      requestSupport: requestSupport,
      uri: requestSupport.threadMessageUri(threadId, messageId),
      method: TransportMethod.delete,
      responseName: 'thread message delete response',
      decode: (json) => OpenAIThreadMessageDeleteResult.fromJson(json),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }
}
