part of 'google_chat_stream_support.dart';

final class _GoogleChatStreamPayloadDecoder {
  const _GoogleChatStreamPayloadDecoder();

  List<Map<String, dynamic>> decode(Object? decoded) {
    if (decoded is Map<String, dynamic>) {
      return [decoded];
    }

    if (decoded is Map) {
      return [Map<String, dynamic>.from(decoded)];
    }

    if (decoded is List) {
      final payloads = <Map<String, dynamic>>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          payloads.add(item);
        } else if (item is Map) {
          payloads.add(Map<String, dynamic>.from(item));
        }
      }
      return payloads;
    }

    return const [];
  }
}
