import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_assistants_lifecycle_client_support.dart';
import 'openai_assistants_lifecycle_models.dart';
import 'openai_assistants_transport.dart';

final class OpenAIAssistantsAssistantLifecycle {
  final TransportClient transport;
  final OpenAIAssistantsTransportSupport requestSupport;

  const OpenAIAssistantsAssistantLifecycle({
    required this.transport,
    required this.requestSupport,
  });

  Future<OpenAIAssistant> create(
    OpenAICreateAssistantRequest request, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) {
    return sendOpenAIAssistantsJsonModel(
      transport: transport,
      requestSupport: requestSupport,
      uri: requestSupport.assistantsUri(),
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

  Future<OpenAIListAssistantsResponse> list({
    OpenAIListAssistantsQuery? query,
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) {
    return sendOpenAIAssistantsJsonModel(
      transport: transport,
      requestSupport: requestSupport,
      uri: requestSupport.assistantsUri(query),
      method: TransportMethod.get,
      responseName: 'assistant list response',
      decode: (json) => OpenAIListAssistantsResponse.fromJson(json),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<OpenAIAssistant> retrieve(
    String assistantId, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) {
    return sendOpenAIAssistantsJsonModel(
      transport: transport,
      requestSupport: requestSupport,
      uri: requestSupport.assistantUri(assistantId),
      method: TransportMethod.get,
      responseName: 'assistant retrieve response',
      decode: (json) => OpenAIAssistant.fromJson(json),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<OpenAIAssistant> modify(
    String assistantId,
    OpenAIModifyAssistantRequest request, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) {
    return sendOpenAIAssistantsJsonModel(
      transport: transport,
      requestSupport: requestSupport,
      uri: requestSupport.assistantUri(assistantId),
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

  Future<OpenAIDeleteAssistantResponse> delete(
    String assistantId, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) {
    return sendOpenAIAssistantsJsonModel(
      transport: transport,
      requestSupport: requestSupport,
      uri: requestSupport.assistantUri(assistantId),
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
