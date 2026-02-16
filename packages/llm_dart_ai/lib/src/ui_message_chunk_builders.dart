/// Helper builders for Vercel AI SDK-style UI message stream chunks.
///
/// Upstream reference:
/// `repo-ref/ai/packages/ai/src/ui-message-stream/ui-message-chunks.ts`
library;

Map<String, Object?> uiChunkStart({
  String? messageId,
  Object? messageMetadata,
}) =>
    <String, Object?>{
      'type': 'start',
      if (messageId != null && messageId.isNotEmpty) 'messageId': messageId,
      if (messageMetadata != null) 'messageMetadata': messageMetadata,
    };

Map<String, Object?> uiChunkFinish({
  String? finishReason,
  Object? messageMetadata,
}) =>
    <String, Object?>{
      'type': 'finish',
      if (finishReason != null && finishReason.isNotEmpty)
        'finishReason': finishReason,
      if (messageMetadata != null) 'messageMetadata': messageMetadata,
    };

Map<String, Object?> uiChunkAbort({String? reason}) => <String, Object?>{
      'type': 'abort',
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    };

Map<String, Object?> uiChunkMessageMetadata(Object messageMetadata) =>
    <String, Object?>{
      'type': 'message-metadata',
      'messageMetadata': messageMetadata,
    };

Map<String, Object?> uiChunkData(
  String name,
  Object data, {
  String? id,
  bool? transient,
}) {
  final chunkType = name.trim();
  if (chunkType.isEmpty) {
    throw ArgumentError.value(
        name, 'name', 'Data chunk name must be non-empty');
  }

  return <String, Object?>{
    'type': 'data-$chunkType',
    if (id != null && id.isNotEmpty) 'id': id,
    'data': data,
    if (transient == true) 'transient': true,
  };
}
