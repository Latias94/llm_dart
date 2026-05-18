import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'http_chat_transport_chunk.dart';
import 'http_chat_transport_json_support.dart';

final class HttpChatTransportChunkJsonCodec {
  static const envelopeKind = 'http-chat-transport-chunk';

  final TextStreamEventJsonCodec eventCodec;

  const HttpChatTransportChunkJsonCodec({
    this.eventCodec = const TextStreamEventJsonCodec(),
  });

  Map<String, Object?> encodeChunk(HttpChatTransportChunk chunk) {
    final data = switch (chunk) {
      HttpChatTransportTransportStartChunk(
        :final requestId,
        :final resumeToken,
      ) =>
        {
          'type': 'transport-start',
          if (requestId != null) 'requestId': requestId,
          if (resumeToken != null) 'resumeToken': resumeToken,
        },
      HttpChatTransportStartChunk(
        :final requestId,
        :final messageId,
        :final resumeToken,
      ) =>
        {
          'type': 'start',
          if (requestId != null) 'requestId': requestId,
          if (messageId != null) 'messageId': messageId,
          if (resumeToken != null) 'resumeToken': resumeToken,
        },
      HttpChatTransportMessageStartChunk(
        :final messageId,
        :final metadata,
      ) =>
        {
          'type': 'message-start',
          'messageId': messageId,
          if (metadata.isNotEmpty) 'metadata': metadata,
        },
      HttpChatTransportMessageMetadataChunk(:final metadata) => {
          'type': 'message-metadata',
          'metadata': metadata,
        },
      HttpChatTransportEventChunk(:final event) => {
          'type': 'event',
          'event': eventCodec.encodeEvent(event),
        },
      HttpChatTransportDataPartChunk(:final part) => {
          'type': 'data-part',
          'part': {
            if (part.id != null) 'id': part.id,
            'key': part.key,
            'data': HttpChatTransportJson.ensureValue(
              part.data,
              path: r'$.data.part.data',
            ),
          },
        },
      HttpChatTransportTransientDataPartChunk(:final part) => {
          'type': 'transient-data-part',
          'part': {
            if (part.id != null) 'id': part.id,
            'key': part.key,
            'data': HttpChatTransportJson.ensureValue(
              part.data,
              path: r'$.data.part.data',
            ),
          },
        },
      HttpChatTransportCheckpointChunk(
        :final resumeToken,
        :final cursor,
      ) =>
        {
          'type': 'checkpoint',
          'resumeToken': resumeToken,
          if (cursor != null) 'cursor': cursor,
        },
      HttpChatTransportFinishChunk() => {
          'type': 'finish',
        },
      HttpChatTransportMessageFinishChunk(:final metadata) => {
          'type': 'message-finish',
          if (metadata.isNotEmpty) 'metadata': metadata,
        },
      HttpChatTransportAbortChunk(:final reason) => {
          'type': 'abort',
          if (reason != null) 'reason': reason,
        },
      HttpChatTransportErrorChunk(
        :final message,
        :final code,
        :final details,
      ) =>
        {
          'type': 'error',
          'message': message,
          if (code != null) 'code': code,
          if (details != null)
            'details': HttpChatTransportJson.ensureValue(
              details,
              path: r'$.details',
            ),
        },
      HttpChatTransportKeepAliveChunk() => {
          'type': 'keepalive',
        },
    };

    return {
      'schemaVersion': llmDartJsonSchemaVersion,
      'kind': envelopeKind,
      'data': data,
    };
  }

  HttpChatTransportChunk decodeChunk(Object? envelope) {
    final root = HttpChatTransportJson.asMap(envelope, path: r'$');
    final kind = HttpChatTransportJson.asString(root['kind'], path: r'$.kind');
    if (kind != envelopeKind) {
      throw FormatException(
        'Expected envelope kind "$envelopeKind", received "$kind".',
      );
    }

    final data = HttpChatTransportJson.asMap(root['data'], path: r'$.data');
    final type = HttpChatTransportJson.asString(
      data['type'],
      path: r'$.data.type',
    );

    return switch (type) {
      'transport-start' => HttpChatTransportTransportStartChunk(
          requestId: HttpChatTransportJson.asNullableString(
            data['requestId'],
            path: r'$.data.requestId',
          ),
          resumeToken: HttpChatTransportJson.asNullableString(
            data['resumeToken'],
            path: r'$.data.resumeToken',
          ),
        ),
      'start' => HttpChatTransportStartChunk(
          requestId: HttpChatTransportJson.asNullableString(
            data['requestId'],
            path: r'$.data.requestId',
          ),
          messageId: HttpChatTransportJson.asNullableString(
            data['messageId'],
            path: r'$.data.messageId',
          ),
          resumeToken: HttpChatTransportJson.asNullableString(
            data['resumeToken'],
            path: r'$.data.resumeToken',
          ),
        ),
      'message-start' => HttpChatTransportMessageStartChunk(
          messageId: HttpChatTransportJson.asString(
            data['messageId'],
            path: r'$.data.messageId',
          ),
          metadata: data['metadata'] == null
              ? const {}
              : HttpChatTransportJson.asMap(
                  data['metadata'],
                  path: r'$.data.metadata',
                ),
        ),
      'message-metadata' => HttpChatTransportMessageMetadataChunk(
          metadata: HttpChatTransportJson.asMap(
            data['metadata'],
            path: r'$.data.metadata',
          ),
        ),
      'event' => HttpChatTransportEventChunk(
          eventCodec.decodeEvent(data['event'], path: r'$.data.event'),
        ),
      'data-part' => HttpChatTransportDataPartChunk(
          _decodeDataPart(data['part'], path: r'$.data.part'),
        ),
      'transient-data-part' => HttpChatTransportTransientDataPartChunk(
          _decodeDataPart(data['part'], path: r'$.data.part'),
        ),
      'checkpoint' => HttpChatTransportCheckpointChunk(
          resumeToken: HttpChatTransportJson.asString(
            data['resumeToken'],
            path: r'$.data.resumeToken',
          ),
          cursor: HttpChatTransportJson.asNullableString(
            data['cursor'],
            path: r'$.data.cursor',
          ),
        ),
      'finish' => const HttpChatTransportFinishChunk(),
      'message-finish' => HttpChatTransportMessageFinishChunk(
          metadata: data['metadata'] == null
              ? const {}
              : HttpChatTransportJson.asMap(
                  data['metadata'],
                  path: r'$.data.metadata',
                ),
        ),
      'abort' => HttpChatTransportAbortChunk(
          reason: HttpChatTransportJson.asNullableString(
            data['reason'],
            path: r'$.data.reason',
          ),
        ),
      'error' => HttpChatTransportErrorChunk(
          message: HttpChatTransportJson.asString(
            data['message'],
            path: r'$.data.message',
          ),
          code: HttpChatTransportJson.asNullableString(
            data['code'],
            path: r'$.data.code',
          ),
          details: data['details'],
        ),
      'keepalive' => const HttpChatTransportKeepAliveChunk(),
      _ => throw FormatException(
          'Unsupported HTTP chat transport chunk type "$type".',
        ),
    };
  }

  DataUiPart<Object?> _decodeDataPart(
    Object? value, {
    required String path,
  }) {
    final map = HttpChatTransportJson.asMap(value, path: path);
    return DataUiPart<Object?>(
      id: HttpChatTransportJson.asNullableString(
        map['id'],
        path: '$path.id',
      ),
      key: HttpChatTransportJson.asString(map['key'], path: '$path.key'),
      data: map['data'],
    );
  }
}
