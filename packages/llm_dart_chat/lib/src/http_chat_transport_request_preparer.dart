import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'chat_transport.dart';
import 'http_chat_transport_request_json_codec.dart';
import 'http_chat_transport_request_payload.dart';
import 'http_chat_transport_request_support.dart';
import 'http_chat_transport_resume_state.dart';
import 'http_chat_transport_stream_protocol.dart';

final class HttpChatTransportPreparedPayloadRequest {
  final Uri endpoint;
  final Map<String, String> headers;
  final Duration? requestTimeout;
  final int? maxRetries;
  final ProviderCancellation? cancellation;
  final Map<String, Object?> payload;

  const HttpChatTransportPreparedPayloadRequest({
    required this.endpoint,
    required this.headers,
    required this.requestTimeout,
    required this.maxRetries,
    required this.cancellation,
    required this.payload,
  });
}

final class HttpChatTransportRequestPreparer {
  final Uri endpoint;
  final Map<String, String> headers;
  final Duration? requestTimeout;
  final HttpChatTransportRequestJsonCodec requestCodec;
  final HttpChatTransportStreamProtocol streamProtocol;
  final HttpChatTransportProviderOptionsEncoder? providerOptionsEncoder;
  final PrepareSendMessagesRequest? prepareSendMessagesRequest;
  final PrepareReconnectRequest? prepareReconnectRequest;

  const HttpChatTransportRequestPreparer({
    required this.endpoint,
    required this.headers,
    required this.requestTimeout,
    required this.requestCodec,
    required this.streamProtocol,
    required this.providerOptionsEncoder,
    required this.prepareSendMessagesRequest,
    required this.prepareReconnectRequest,
  });

  HttpChatTransportResumeState createSendMessagesState(
    ChatTransportRequest request,
  ) {
    validateSerializableHttpChatRequestOptions(request.options);

    final callOptionsPayload = serializeHttpChatTransportCallOptions(
      request.options.callOptions,
      providerOptionsEncoder: providerOptionsEncoder,
    );
    final baseRequestTimeout =
        request.options.callOptions.timeout ?? requestTimeout;

    return HttpChatTransportResumeState(
      callOptionsPayload: callOptionsPayload,
      requestTimeout: baseRequestTimeout,
      maxRetries: request.options.callOptions.maxRetries,
      cancellation: request.options.callOptions.cancellation,
    );
  }

  Future<HttpChatTransportPreparedPayloadRequest> prepareSendMessages({
    required ChatTransportRequest request,
    required HttpChatTransportResumeState state,
  }) async {
    final baseHeaders = buildHttpChatTransportBaseHeaders(headers);
    final basePayload = HttpChatTransportRequestPayload(
      chatId: request.chatId,
      prompt: request.prompt,
      generateOptions: request.options.generateOptions,
      tools: request.options.tools,
      toolChoice: request.options.toolChoice,
      callOptions: state.callOptionsPayload,
      streamProtocol: streamProtocol,
      metadata: request.options.metadata,
    );
    final preparedRequest = await prepareSendMessagesRequest?.call(
      HttpChatTransportSendMessagesRequestContext(
        request: request,
        endpoint: endpoint,
        headers: Map.unmodifiable(baseHeaders),
        requestTimeout: state.requestTimeout,
        payload: basePayload,
      ),
    );

    return HttpChatTransportPreparedPayloadRequest(
      endpoint: preparedRequest?.endpoint ?? endpoint,
      headers: preparedRequest?.headers ?? baseHeaders,
      requestTimeout: preparedRequest?.overrideRequestTimeout == true
          ? preparedRequest!.requestTimeout
          : state.requestTimeout,
      maxRetries: state.maxRetries,
      cancellation: state.cancellation,
      payload: requestCodec.encodeRequest(
        preparedRequest?.payload ?? basePayload,
      ),
    );
  }

  Future<HttpChatTransportPreparedPayloadRequest> prepareReconnect({
    required String chatId,
    required String resumeToken,
    required HttpChatTransportResumeState state,
  }) async {
    final baseHeaders = buildHttpChatTransportBaseHeaders(headers);
    final basePayload = HttpChatTransportReconnectRequestPayload(
      chatId: chatId,
      resumeToken: resumeToken,
      callOptions: state.callOptionsPayload,
      streamProtocol: streamProtocol,
    );
    final preparedRequest = await prepareReconnectRequest?.call(
      HttpChatTransportReconnectRequestContext(
        chatId: chatId,
        resumeToken: resumeToken,
        endpoint: endpoint,
        headers: Map.unmodifiable(baseHeaders),
        requestTimeout: state.requestTimeout,
        payload: basePayload,
      ),
    );

    return HttpChatTransportPreparedPayloadRequest(
      endpoint: preparedRequest?.endpoint ?? endpoint,
      headers: preparedRequest?.headers ?? baseHeaders,
      requestTimeout: preparedRequest?.overrideRequestTimeout == true
          ? preparedRequest!.requestTimeout
          : state.requestTimeout,
      maxRetries: state.maxRetries,
      cancellation: state.cancellation,
      payload: requestCodec.encodeReconnectRequest(
        preparedRequest?.payload ?? basePayload,
      ),
    );
  }
}
