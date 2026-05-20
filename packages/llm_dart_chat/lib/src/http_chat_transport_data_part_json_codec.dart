import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'http_chat_transport_json_support.dart';

final class HttpChatTransportDataPartJsonCodec {
  const HttpChatTransportDataPartJsonCodec();

  Map<String, Object?> encodePart(
    DataUiPart<Object?> part, {
    required String path,
  }) {
    return {
      if (part.id != null) 'id': part.id,
      'key': part.key,
      'data': HttpChatTransportJson.ensureValue(
        part.data,
        path: '$path.data',
      ),
    };
  }

  DataUiPart<Object?> decodePart(
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
