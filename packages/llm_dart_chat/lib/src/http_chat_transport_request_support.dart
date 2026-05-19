import 'dart:async';

import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'chat_request_options.dart';
import 'chat_transport.dart';
import 'http_chat_transport_request_payload.dart';

typedef PrepareSendMessagesRequest
    = FutureOr<HttpChatTransportPreparedSendMessagesRequest?> Function(
  HttpChatTransportSendMessagesRequestContext context,
);

typedef PrepareReconnectRequest
    = FutureOr<HttpChatTransportPreparedReconnectRequest?> Function(
  HttpChatTransportReconnectRequestContext context,
);

typedef HttpChatTransportProviderOptionsEncoder = Map<String, Object?> Function(
  ProviderInvocationOptions providerOptions,
);

final class HttpChatTransportSendMessagesRequestContext {
  final ChatTransportRequest request;
  final Uri endpoint;
  final Map<String, String> headers;
  final Duration? requestTimeout;
  final HttpChatTransportRequestPayload payload;

  const HttpChatTransportSendMessagesRequestContext({
    required this.request,
    required this.endpoint,
    required this.headers,
    required this.requestTimeout,
    required this.payload,
  });
}

final class HttpChatTransportPreparedSendMessagesRequest {
  final Uri? endpoint;
  final Map<String, String>? headers;
  final Duration? requestTimeout;
  final bool overrideRequestTimeout;
  final HttpChatTransportRequestPayload? payload;

  const HttpChatTransportPreparedSendMessagesRequest({
    this.endpoint,
    this.headers,
    this.requestTimeout,
    this.overrideRequestTimeout = false,
    this.payload,
  });
}

final class HttpChatTransportReconnectRequestContext {
  final String chatId;
  final String resumeToken;
  final Uri endpoint;
  final Map<String, String> headers;
  final Duration? requestTimeout;
  final HttpChatTransportReconnectRequestPayload payload;

  const HttpChatTransportReconnectRequestContext({
    required this.chatId,
    required this.resumeToken,
    required this.endpoint,
    required this.headers,
    required this.requestTimeout,
    required this.payload,
  });
}

final class HttpChatTransportPreparedReconnectRequest {
  final Uri? endpoint;
  final Map<String, String>? headers;
  final Duration? requestTimeout;
  final bool overrideRequestTimeout;
  final HttpChatTransportReconnectRequestPayload? payload;

  const HttpChatTransportPreparedReconnectRequest({
    this.endpoint,
    this.headers,
    this.requestTimeout,
    this.overrideRequestTimeout = false,
    this.payload,
  });
}

void validateSerializableHttpChatRequestOptions(ChatRequestOptions options) {
  if (options.tools.isNotEmpty || options.toolChoice != null) {
    throw UnsupportedError(
      'HttpChatTransport cannot serialize ChatRequestOptions.tools or '
      'toolChoice yet. Declare tools on the server side or add an explicit '
      'HTTP chat tool protocol.',
    );
  }

  if (options.hasLocalRuntimeHooks) {
    throw UnsupportedError(
      'HttpChatTransport cannot serialize local runtime callbacks, '
      'functionToolExecutor, or stopWhen. Use DirectChatTransport for local '
      'runtime tool execution, or implement the tool loop on the server.',
    );
  }

  if (options.maxSteps != 8) {
    throw UnsupportedError(
      'HttpChatTransport cannot serialize ChatRequestOptions.maxSteps yet. '
      'Configure maxSteps on the server side.',
    );
  }
}

HttpChatTransportCallOptionsPayload serializeHttpChatTransportCallOptions(
  CallOptions options, {
  HttpChatTransportProviderOptionsEncoder? providerOptionsEncoder,
}) {
  Map<String, Object?> providerOptions = const {};
  final typedProviderOptions = options.providerOptions;
  if (typedProviderOptions != null) {
    final encoder = providerOptionsEncoder;
    if (encoder == null) {
      throw UnsupportedError(
        'HttpChatTransport needs providerOptionsEncoder to serialize typed providerOptions. Common CallOptions fields are supported without an encoder.',
      );
    }

    providerOptions = encoder(typedProviderOptions);
  }

  return HttpChatTransportCallOptionsPayload(
    timeout: options.timeout,
    headers: options.headers ?? const {},
    maxRetries: options.maxRetries,
    providerOptions: providerOptions,
  );
}

Map<String, String> buildHttpChatTransportBaseHeaders(
  Map<String, String> headers,
) {
  return {
    'content-type': 'application/json',
    'accept': 'text/event-stream',
    ...headers,
  };
}
