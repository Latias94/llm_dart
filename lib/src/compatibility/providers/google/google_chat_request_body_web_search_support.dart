part of 'google_chat_request_builder.dart';

final class _GoogleChatRequestBodyWebSearchSupport {
  const _GoogleChatRequestBodyWebSearchSupport();

  void applyWebSearch(
    Map<String, dynamic> body,
    bool enabled,
  ) {
    if (!enabled) {
      return;
    }

    final tools = body['tools'];
    if (tools is List) {
      tools.add(
        <String, dynamic>{
          'google_search': <String, Object?>{},
        },
      );
    } else {
      body['tools'] = [
        <String, dynamic>{
          'google_search': <String, Object?>{},
        },
      ];
    }
  }
}
