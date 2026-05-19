import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'http_chat_transport_call_options_json_codec.dart';
import 'http_chat_transport_generate_options_json_codec.dart';
import 'http_chat_transport_json_support.dart';
import 'http_chat_transport_request_payload.dart';
import 'http_chat_transport_tool_json_codec.dart';
import 'http_chat_transport_stream_protocol.dart';

final class HttpChatTransportRequestJsonCodec {
  static const envelopeKind = 'http-chat-transport-request';
  static const reconnectEnvelopeKind = 'http-chat-transport-reconnect-request';

  final PromptJsonCodec promptCodec;
  final List<ProviderToolOptionsJsonCodec> providerToolOptionsCodecs;

  const HttpChatTransportRequestJsonCodec({
    this.promptCodec = const PromptJsonCodec(),
    this.providerToolOptionsCodecs = const [],
  });

  Map<String, Object?> encodeRequest(HttpChatTransportRequestPayload request) {
    final toolCodec = HttpChatTransportToolJsonCodec(
      providerToolOptionsCodecs: providerToolOptionsCodecs,
    );
    const generateOptionsCodec = HttpChatTransportGenerateOptionsJsonCodec();
    const callOptionsCodec = HttpChatTransportCallOptionsJsonCodec();

    return {
      'schemaVersion': llmDartJsonSchemaVersion,
      'kind': envelopeKind,
      'data': {
        'chatId': request.chatId,
        'prompt': promptCodec.encodeMessages(request.prompt),
        'generateOptions': generateOptionsCodec.encode(
          request.generateOptions,
        ),
        if (request.tools.isNotEmpty)
          'tools': toolCodec.encodeTools(request.tools),
        if (request.toolChoice != null)
          'toolChoice': toolCodec.encodeToolChoice(request.toolChoice!),
        if (!request.callOptions.isEmpty)
          'callOptions': callOptionsCodec.encode(request.callOptions),
        'streamProtocol': request.streamProtocol.wireValue,
        if (request.metadata.isNotEmpty) 'metadata': request.metadata,
      },
    };
  }

  HttpChatTransportRequestPayload decodeRequest(Object? envelope) {
    final toolCodec = HttpChatTransportToolJsonCodec(
      providerToolOptionsCodecs: providerToolOptionsCodecs,
    );
    const generateOptionsCodec = HttpChatTransportGenerateOptionsJsonCodec();
    const callOptionsCodec = HttpChatTransportCallOptionsJsonCodec();

    final root = HttpChatTransportJson.asMap(envelope, path: r'$');
    final kind = HttpChatTransportJson.asString(root['kind'], path: r'$.kind');
    if (kind != envelopeKind) {
      throw FormatException(
        'Expected envelope kind "$envelopeKind", received "$kind".',
      );
    }

    final data = HttpChatTransportJson.asMap(root['data'], path: r'$.data');
    return HttpChatTransportRequestPayload(
      chatId: HttpChatTransportJson.asString(
        data['chatId'],
        path: r'$.data.chatId',
      ),
      prompt: promptCodec.decodeMessages(data['prompt']),
      generateOptions: generateOptionsCodec.decode(
        data['generateOptions'],
        path: r'$.data.generateOptions',
      ),
      tools: toolCodec.decodeTools(data['tools'], path: r'$.data.tools'),
      toolChoice: toolCodec.decodeToolChoice(
        data['toolChoice'],
        path: r'$.data.toolChoice',
      ),
      callOptions: callOptionsCodec.decode(
        data['callOptions'],
        path: r'$.data.callOptions',
      ),
      streamProtocol: switch (HttpChatTransportJson.asNullableString(
        data['streamProtocol'],
        path: r'$.data.streamProtocol',
      )) {
        final String value => HttpChatTransportStreamProtocol.decode(
            value,
            path: r'$.data.streamProtocol',
          ),
        null => HttpChatTransportStreamProtocol.eventStreamV1,
      },
      metadata: data['metadata'] == null
          ? const {}
          : HttpChatTransportJson.asMap(
              data['metadata'],
              path: r'$.data.metadata',
            ),
    );
  }

  Map<String, Object?> encodeReconnectRequest(
    HttpChatTransportReconnectRequestPayload request,
  ) {
    const callOptionsCodec = HttpChatTransportCallOptionsJsonCodec();

    return {
      'schemaVersion': llmDartJsonSchemaVersion,
      'kind': reconnectEnvelopeKind,
      'data': {
        'chatId': request.chatId,
        'resumeToken': request.resumeToken,
        if (!request.callOptions.isEmpty)
          'callOptions': callOptionsCodec.encode(request.callOptions),
        'streamProtocol': request.streamProtocol.wireValue,
        if (request.metadata.isNotEmpty) 'metadata': request.metadata,
      },
    };
  }

  HttpChatTransportReconnectRequestPayload decodeReconnectRequest(
    Object? envelope,
  ) {
    const callOptionsCodec = HttpChatTransportCallOptionsJsonCodec();

    final root = HttpChatTransportJson.asMap(envelope, path: r'$');
    final kind = HttpChatTransportJson.asString(root['kind'], path: r'$.kind');
    if (kind != reconnectEnvelopeKind) {
      throw FormatException(
        'Expected envelope kind "$reconnectEnvelopeKind", received "$kind".',
      );
    }

    final data = HttpChatTransportJson.asMap(root['data'], path: r'$.data');
    return HttpChatTransportReconnectRequestPayload(
      chatId: HttpChatTransportJson.asString(
        data['chatId'],
        path: r'$.data.chatId',
      ),
      resumeToken: HttpChatTransportJson.asString(
        data['resumeToken'],
        path: r'$.data.resumeToken',
      ),
      callOptions: callOptionsCodec.decode(
        data['callOptions'],
        path: r'$.data.callOptions',
      ),
      streamProtocol: switch (HttpChatTransportJson.asNullableString(
        data['streamProtocol'],
        path: r'$.data.streamProtocol',
      )) {
        final String value => HttpChatTransportStreamProtocol.decode(
            value,
            path: r'$.data.streamProtocol',
          ),
        null => HttpChatTransportStreamProtocol.eventStreamV1,
      },
      metadata: data['metadata'] == null
          ? const {}
          : HttpChatTransportJson.asMap(
              data['metadata'],
              path: r'$.data.metadata',
            ),
    );
  }
}
