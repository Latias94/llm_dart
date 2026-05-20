import 'package:llm_dart_ai/llm_dart_ai.dart';

final class ChatToolReplayPayload {
  final String role;
  final String? toolCallId;
  final String? toolName;

  const ChatToolReplayPayload({
    required this.role,
    this.toolCallId,
    this.toolName,
  });

  bool get isToolRole => role == 'tool';
}

ChatToolReplayPayload? parseChatToolReplayPayload(Object? data) {
  final payload = toolReplayPayloadMap(data);
  final role = _nonEmptyString(payload?['replayRole']);
  if (role == null) {
    return null;
  }

  return ChatToolReplayPayload(
    role: role,
    toolCallId: _nonEmptyString(payload?['toolCallId']),
    toolName: _nonEmptyString(payload?['toolName']),
  );
}

Set<String> replayedToolResultIdsFromChatUiParts(
  Iterable<ChatUiPart> parts,
) {
  return {
    for (final part in parts)
      if (part case CustomUiPart(:final data))
        if (parseChatToolReplayPayload(data) case final payload?)
          if (payload.isToolRole && payload.toolCallId != null)
            payload.toolCallId!,
  };
}

String? toolReplayPayloadRole(Object? data) {
  return parseChatToolReplayPayload(data)?.role;
}

String? toolReplayPayloadToolCallId(Object? data) {
  return parseChatToolReplayPayload(data)?.toolCallId;
}

String? toolReplayPayloadToolName(Object? data) {
  return parseChatToolReplayPayload(data)?.toolName;
}

Map<String, Object?>? toolReplayPayloadMap(Object? data) {
  if (data is Map<String, Object?>) {
    return data;
  }

  if (data is Map) {
    final normalized = <String, Object?>{};
    for (final entry in data.entries) {
      if (entry.key is! String) {
        return null;
      }

      normalized[entry.key as String] = entry.value;
    }
    return normalized;
  }

  return null;
}

String? _nonEmptyString(Object? value) {
  return value is String && value.isNotEmpty ? value : null;
}
