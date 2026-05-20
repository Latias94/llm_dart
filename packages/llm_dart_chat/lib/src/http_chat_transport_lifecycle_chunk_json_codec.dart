import 'http_chat_transport_chunk.dart';
import 'http_chat_transport_json_support.dart';

final class HttpChatTransportLifecycleChunkJsonCodec {
  static const Set<String> chunkTypes = {
    'transport-start',
    'start',
    'checkpoint',
    'finish',
    'abort',
    'error',
    'keepalive',
  };

  const HttpChatTransportLifecycleChunkJsonCodec();

  bool canDecode(String type) => chunkTypes.contains(type);

  Map<String, Object?> encode(HttpChatTransportChunk chunk) {
    return switch (chunk) {
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
      HttpChatTransportCheckpointChunk(:final resumeToken, :final cursor) => {
          'type': 'checkpoint',
          'resumeToken': resumeToken,
          if (cursor != null) 'cursor': cursor,
        },
      HttpChatTransportFinishChunk() => {
          'type': 'finish',
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
      _ => throw ArgumentError.value(
          chunk,
          'chunk',
          'Expected an HTTP chat transport lifecycle chunk.',
        ),
    };
  }

  HttpChatTransportChunk decode(
    Map<String, Object?> data, {
    required String type,
  }) {
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
          'Unsupported HTTP chat transport lifecycle chunk type "$type".',
        ),
    };
  }
}
