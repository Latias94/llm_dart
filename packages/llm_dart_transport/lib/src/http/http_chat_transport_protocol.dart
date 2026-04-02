import 'package:llm_dart_core/llm_dart_core.dart';

typedef _JsonMap = Map<String, Object?>;
typedef _JsonList = List<Object?>;

enum HttpChatTransportStreamProtocol {
  eventStreamV1('event-stream-v1'),
  uiMessageStreamV2('ui-message-stream-v2');

  final String wireValue;

  const HttpChatTransportStreamProtocol(this.wireValue);

  static HttpChatTransportStreamProtocol decode(
    String value, {
    required String path,
  }) {
    for (final protocol in values) {
      if (protocol.wireValue == value) {
        return protocol;
      }
    }

    throw FormatException(
      'Unsupported HTTP chat transport stream protocol "$value" at $path.',
    );
  }
}

final class HttpChatTransportRequestPayload {
  final String chatId;
  final List<PromptMessage> prompt;
  final GenerateTextOptions generateOptions;
  final HttpChatTransportStreamProtocol streamProtocol;
  final Map<String, Object?> metadata;

  HttpChatTransportRequestPayload({
    required this.chatId,
    required List<PromptMessage> prompt,
    this.generateOptions = const GenerateTextOptions(),
    this.streamProtocol = HttpChatTransportStreamProtocol.uiMessageStreamV2,
    Map<String, Object?> metadata = const {},
  })  : prompt = List.unmodifiable(prompt),
        metadata = Map.unmodifiable(
          _ensureJsonMap(metadata, path: r'$.metadata'),
        );
}

final class HttpChatTransportReconnectRequestPayload {
  final String chatId;
  final String resumeToken;
  final HttpChatTransportStreamProtocol streamProtocol;
  final Map<String, Object?> metadata;

  HttpChatTransportReconnectRequestPayload({
    required this.chatId,
    required this.resumeToken,
    this.streamProtocol = HttpChatTransportStreamProtocol.uiMessageStreamV2,
    Map<String, Object?> metadata = const {},
  }) : metadata = Map.unmodifiable(
          _ensureJsonMap(metadata, path: r'$.metadata'),
        );
}

final class HttpChatTransportRequestJsonCodec {
  static const envelopeKind = 'http-chat-transport-request';
  static const reconnectEnvelopeKind = 'http-chat-transport-reconnect-request';

  final PromptJsonCodec promptCodec;

  const HttpChatTransportRequestJsonCodec({
    this.promptCodec = const PromptJsonCodec(),
  });

  Map<String, Object?> encodeRequest(HttpChatTransportRequestPayload request) {
    return {
      'schemaVersion': llmDartJsonSchemaVersion,
      'kind': envelopeKind,
      'data': {
        'chatId': request.chatId,
        'prompt': promptCodec.encodeMessages(request.prompt),
        'generateOptions': _encodeGenerateTextOptions(request.generateOptions),
        'streamProtocol': request.streamProtocol.wireValue,
        if (request.metadata.isNotEmpty) 'metadata': request.metadata,
      },
    };
  }

  HttpChatTransportRequestPayload decodeRequest(Object? envelope) {
    final root = _asJsonMap(envelope, path: r'$');
    final kind = _asJsonString(root['kind'], path: r'$.kind');
    if (kind != envelopeKind) {
      throw FormatException(
        'Expected envelope kind "$envelopeKind", received "$kind".',
      );
    }

    final data = _asJsonMap(root['data'], path: r'$.data');
    return HttpChatTransportRequestPayload(
      chatId: _asJsonString(data['chatId'], path: r'$.data.chatId'),
      prompt: promptCodec.decodeMessages(data['prompt']),
      generateOptions: _decodeGenerateTextOptions(
        data['generateOptions'],
        path: r'$.data.generateOptions',
      ),
      streamProtocol: switch (_asNullableJsonString(
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
          : _asJsonMap(data['metadata'], path: r'$.data.metadata'),
    );
  }

  Map<String, Object?> encodeReconnectRequest(
    HttpChatTransportReconnectRequestPayload request,
  ) {
    return {
      'schemaVersion': llmDartJsonSchemaVersion,
      'kind': reconnectEnvelopeKind,
      'data': {
        'chatId': request.chatId,
        'resumeToken': request.resumeToken,
        'streamProtocol': request.streamProtocol.wireValue,
        if (request.metadata.isNotEmpty) 'metadata': request.metadata,
      },
    };
  }

  HttpChatTransportReconnectRequestPayload decodeReconnectRequest(
    Object? envelope,
  ) {
    final root = _asJsonMap(envelope, path: r'$');
    final kind = _asJsonString(root['kind'], path: r'$.kind');
    if (kind != reconnectEnvelopeKind) {
      throw FormatException(
        'Expected envelope kind "$reconnectEnvelopeKind", received "$kind".',
      );
    }

    final data = _asJsonMap(root['data'], path: r'$.data');
    return HttpChatTransportReconnectRequestPayload(
      chatId: _asJsonString(data['chatId'], path: r'$.data.chatId'),
      resumeToken:
          _asJsonString(data['resumeToken'], path: r'$.data.resumeToken'),
      streamProtocol: switch (_asNullableJsonString(
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
          : _asJsonMap(data['metadata'], path: r'$.data.metadata'),
    );
  }

  _JsonMap _encodeGenerateTextOptions(GenerateTextOptions options) {
    return {
      if (options.maxOutputTokens != null)
        'maxOutputTokens': options.maxOutputTokens,
      if (options.temperature != null) 'temperature': options.temperature,
      if (options.stopSequences != null) 'stopSequences': options.stopSequences,
      if (options.topP != null) 'topP': options.topP,
      if (options.topK != null) 'topK': options.topK,
    };
  }

  GenerateTextOptions _decodeGenerateTextOptions(
    Object? value, {
    required String path,
  }) {
    if (value == null) {
      return const GenerateTextOptions();
    }

    final map = _asJsonMap(value, path: path);
    return GenerateTextOptions(
      maxOutputTokens: _asNullableJsonInt(
        map['maxOutputTokens'],
        path: '$path.maxOutputTokens',
      ),
      temperature:
          _asNullableJsonDouble(map['temperature'], path: '$path.temperature'),
      stopSequences: map['stopSequences'] == null
          ? null
          : _asJsonList(map['stopSequences'], path: '$path.stopSequences')
              .asMap()
              .entries
              .map(
                (entry) => _asJsonString(
                  entry.value,
                  path: '$path.stopSequences[${entry.key}]',
                ),
              )
              .toList(growable: false),
      topP: _asNullableJsonDouble(map['topP'], path: '$path.topP'),
      topK: _asNullableJsonInt(map['topK'], path: '$path.topK'),
    );
  }
}

sealed class HttpChatTransportChunk {
  const HttpChatTransportChunk();
}

final class HttpChatTransportTransportStartChunk extends HttpChatTransportChunk {
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
          _ensureJsonMap(metadata, path: r'$.metadata'),
        );
}

final class HttpChatTransportMessageMetadataChunk
    extends HttpChatTransportChunk {
  final Map<String, Object?> metadata;

  HttpChatTransportMessageMetadataChunk({
    required Map<String, Object?> metadata,
  }) : metadata = Map.unmodifiable(
          _ensureJsonMap(metadata, path: r'$.metadata'),
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
          _ensureJsonMap(metadata, path: r'$.metadata'),
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
            'data': _ensureJsonValue(part.data, path: r'$.data.part.data'),
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
            'details': _ensureJsonValue(details, path: r'$.details'),
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
    final root = _asJsonMap(envelope, path: r'$');
    final kind = _asJsonString(root['kind'], path: r'$.kind');
    if (kind != envelopeKind) {
      throw FormatException(
        'Expected envelope kind "$envelopeKind", received "$kind".',
      );
    }

    final data = _asJsonMap(root['data'], path: r'$.data');
    final type = _asJsonString(data['type'], path: r'$.data.type');

    return switch (type) {
      'transport-start' => HttpChatTransportTransportStartChunk(
          requestId: _asNullableJsonString(
            data['requestId'],
            path: r'$.data.requestId',
          ),
          resumeToken: _asNullableJsonString(
            data['resumeToken'],
            path: r'$.data.resumeToken',
          ),
        ),
      'start' => HttpChatTransportStartChunk(
          requestId: _asNullableJsonString(
            data['requestId'],
            path: r'$.data.requestId',
          ),
          messageId: _asNullableJsonString(
            data['messageId'],
            path: r'$.data.messageId',
          ),
          resumeToken: _asNullableJsonString(
            data['resumeToken'],
            path: r'$.data.resumeToken',
          ),
        ),
      'message-start' => HttpChatTransportMessageStartChunk(
          messageId: _asJsonString(data['messageId'], path: r'$.data.messageId'),
          metadata: data['metadata'] == null
              ? const {}
              : _asJsonMap(data['metadata'], path: r'$.data.metadata'),
        ),
      'message-metadata' => HttpChatTransportMessageMetadataChunk(
          metadata: _asJsonMap(data['metadata'], path: r'$.data.metadata'),
        ),
      'event' => HttpChatTransportEventChunk(
          eventCodec.decodeEvent(data['event'], path: r'$.data.event'),
        ),
      'data-part' => HttpChatTransportDataPartChunk(
          _decodeDataPart(data['part'], path: r'$.data.part'),
        ),
      'checkpoint' => HttpChatTransportCheckpointChunk(
          resumeToken:
              _asJsonString(data['resumeToken'], path: r'$.data.resumeToken'),
          cursor: _asNullableJsonString(data['cursor'], path: r'$.data.cursor'),
        ),
      'finish' => const HttpChatTransportFinishChunk(),
      'message-finish' => HttpChatTransportMessageFinishChunk(
          metadata: data['metadata'] == null
              ? const {}
              : _asJsonMap(data['metadata'], path: r'$.data.metadata'),
        ),
      'abort' => HttpChatTransportAbortChunk(
          reason: _asNullableJsonString(data['reason'], path: r'$.data.reason'),
        ),
      'error' => HttpChatTransportErrorChunk(
          message: _asJsonString(data['message'], path: r'$.data.message'),
          code: _asNullableJsonString(data['code'], path: r'$.data.code'),
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
    final map = _asJsonMap(value, path: path);
    return DataUiPart<Object?>(
      id: _asNullableJsonString(map['id'], path: '$path.id'),
      key: _asJsonString(map['key'], path: '$path.key'),
      data: map['data'],
    );
  }
}

Object? _ensureJsonValue(
  Object? value, {
  required String path,
}) {
  return switch (value) {
    null || bool() || num() || String() => value,
    List() => value
        .asMap()
        .entries
        .map(
          (entry) => _ensureJsonValue(
            entry.value,
            path: '$path[${entry.key}]',
          ),
        )
        .toList(growable: false),
    Map() => _ensureJsonMap(value, path: path),
    _ => throw FormatException(
        'Unsupported non-JSON value at $path: ${value.runtimeType}',
      ),
  };
}

_JsonMap _ensureJsonMap(
  Map value, {
  required String path,
}) {
  final result = <String, Object?>{};

  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw FormatException('Expected string key at $path.');
    }

    result[entry.key as String] = _ensureJsonValue(
      entry.value,
      path: '$path.${entry.key}',
    );
  }

  return result;
}

_JsonMap _asJsonMap(
  Object? value, {
  required String path,
}) {
  if (value is! Map) {
    throw FormatException('Expected JSON object at $path.');
  }

  return value.map((key, nestedValue) {
    if (key is! String) {
      throw FormatException('Expected string key at $path.');
    }

    return MapEntry(key, nestedValue);
  });
}

_JsonList _asJsonList(
  Object? value, {
  required String path,
}) {
  if (value is! List) {
    throw FormatException('Expected JSON array at $path.');
  }

  return value.cast<Object?>();
}

String _asJsonString(
  Object? value, {
  required String path,
}) {
  if (value is! String) {
    throw FormatException('Expected string at $path.');
  }

  return value;
}

String? _asNullableJsonString(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }

  return _asJsonString(value, path: path);
}

int? _asNullableJsonInt(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  throw FormatException('Expected int at $path.');
}

double? _asNullableJsonDouble(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toDouble();
  }

  throw FormatException('Expected number at $path.');
}
