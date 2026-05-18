import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'http_chat_transport_json_support.dart';
import 'http_chat_transport_stream_protocol.dart';

final class HttpChatTransportCallOptionsPayload {
  static const empty = HttpChatTransportCallOptionsPayload._();

  final Duration? timeout;
  final Map<String, String> headers;
  final int? maxRetries;
  final Map<String, Object?> providerOptions;

  const HttpChatTransportCallOptionsPayload._({
    this.timeout,
    this.headers = const {},
    this.maxRetries,
    this.providerOptions = const {},
  }) : assert(maxRetries == null || maxRetries >= 0);

  factory HttpChatTransportCallOptionsPayload({
    Duration? timeout,
    Map<String, String> headers = const {},
    int? maxRetries,
    Map<String, Object?> providerOptions = const {},
  }) {
    if (timeout != null && timeout.isNegative) {
      throw ArgumentError.value(
        timeout,
        'timeout',
        'Timeout must not be negative.',
      );
    }
    if (maxRetries != null && maxRetries < 0) {
      throw ArgumentError.value(
        maxRetries,
        'maxRetries',
        'maxRetries must not be negative.',
      );
    }

    return HttpChatTransportCallOptionsPayload._(
      timeout: timeout,
      headers: Map.unmodifiable(headers),
      maxRetries: maxRetries,
      providerOptions: Map.unmodifiable(
        HttpChatTransportJson.ensureMap(
          providerOptions,
          path: r'$.callOptions.providerOptions',
        ),
      ),
    );
  }

  bool get isEmpty =>
      timeout == null &&
      headers.isEmpty &&
      maxRetries == null &&
      providerOptions.isEmpty;

  CallOptions toCallOptions({
    ProviderInvocationOptions? providerOptions,
  }) {
    return CallOptions(
      timeout: timeout,
      headers: headers.isEmpty ? null : headers,
      maxRetries: maxRetries,
      providerOptions: providerOptions,
    );
  }
}

final class HttpChatTransportRequestPayload {
  final String chatId;
  final List<PromptMessage> prompt;
  final GenerateTextOptions generateOptions;
  final HttpChatTransportCallOptionsPayload callOptions;
  final HttpChatTransportStreamProtocol streamProtocol;
  final Map<String, Object?> metadata;

  HttpChatTransportRequestPayload({
    required this.chatId,
    required List<PromptMessage> prompt,
    this.generateOptions = const GenerateTextOptions(),
    this.callOptions = HttpChatTransportCallOptionsPayload.empty,
    this.streamProtocol = HttpChatTransportStreamProtocol.uiMessageStreamV2,
    Map<String, Object?> metadata = const {},
  })  : prompt = List.unmodifiable(prompt),
        metadata = Map.unmodifiable(
          HttpChatTransportJson.ensureMap(metadata, path: r'$.metadata'),
        );
}

final class HttpChatTransportReconnectRequestPayload {
  final String chatId;
  final String resumeToken;
  final HttpChatTransportCallOptionsPayload callOptions;
  final HttpChatTransportStreamProtocol streamProtocol;
  final Map<String, Object?> metadata;

  HttpChatTransportReconnectRequestPayload({
    required this.chatId,
    required this.resumeToken,
    this.callOptions = HttpChatTransportCallOptionsPayload.empty,
    this.streamProtocol = HttpChatTransportStreamProtocol.uiMessageStreamV2,
    Map<String, Object?> metadata = const {},
  }) : metadata = Map.unmodifiable(
          HttpChatTransportJson.ensureMap(metadata, path: r'$.metadata'),
        );
}
