import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'http_chat_transport_json_support.dart';

sealed class HttpChatTransportChunk {
  const HttpChatTransportChunk();
}

final class HttpChatTransportTransportStartChunk
    extends HttpChatTransportChunk {
  final String? requestId;
  final String? resumeToken;

  const HttpChatTransportTransportStartChunk({
    this.requestId,
    this.resumeToken,
  });
}

final class HttpChatTransportStartChunk extends HttpChatTransportChunk {
  final String? requestId;
  final String? messageId;
  final String? resumeToken;

  const HttpChatTransportStartChunk({
    this.requestId,
    this.messageId,
    this.resumeToken,
  });
}

final class HttpChatTransportMessageStartChunk extends HttpChatTransportChunk {
  final String messageId;
  final Map<String, Object?> metadata;

  HttpChatTransportMessageStartChunk({
    required this.messageId,
    Map<String, Object?> metadata = const {},
  }) : metadata = Map.unmodifiable(
          HttpChatTransportJson.ensureMap(metadata, path: r'$.metadata'),
        );
}

final class HttpChatTransportMessageMetadataChunk
    extends HttpChatTransportChunk {
  final Map<String, Object?> metadata;

  HttpChatTransportMessageMetadataChunk({
    required Map<String, Object?> metadata,
  }) : metadata = Map.unmodifiable(
          HttpChatTransportJson.ensureMap(metadata, path: r'$.metadata'),
        );
}

final class HttpChatTransportEventChunk extends HttpChatTransportChunk {
  final TextStreamEvent event;

  const HttpChatTransportEventChunk(this.event);
}

final class HttpChatTransportDataPartChunk extends HttpChatTransportChunk {
  final DataUiPart<Object?> part;

  const HttpChatTransportDataPartChunk(this.part);
}

final class HttpChatTransportTransientDataPartChunk
    extends HttpChatTransportChunk {
  final DataUiPart<Object?> part;

  const HttpChatTransportTransientDataPartChunk(this.part);
}

final class HttpChatTransportCheckpointChunk extends HttpChatTransportChunk {
  final String resumeToken;
  final String? cursor;

  const HttpChatTransportCheckpointChunk({
    required this.resumeToken,
    this.cursor,
  });
}

final class HttpChatTransportFinishChunk extends HttpChatTransportChunk {
  const HttpChatTransportFinishChunk();
}

final class HttpChatTransportMessageFinishChunk extends HttpChatTransportChunk {
  final Map<String, Object?> metadata;

  HttpChatTransportMessageFinishChunk({
    Map<String, Object?> metadata = const {},
  }) : metadata = Map.unmodifiable(
          HttpChatTransportJson.ensureMap(metadata, path: r'$.metadata'),
        );
}

final class HttpChatTransportAbortChunk extends HttpChatTransportChunk {
  final String? reason;

  const HttpChatTransportAbortChunk({
    this.reason,
  });
}

final class HttpChatTransportErrorChunk extends HttpChatTransportChunk {
  final String message;
  final String? code;
  final Object? details;

  const HttpChatTransportErrorChunk({
    required this.message,
    this.code,
    this.details,
  });
}

final class HttpChatTransportKeepAliveChunk extends HttpChatTransportChunk {
  const HttpChatTransportKeepAliveChunk();
}
