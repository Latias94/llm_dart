import '../stream/text_stream_event.dart';
import 'chat_ui_message.dart';
import 'chat_ui_stream_chunk.dart';

/// Projects a shared text event stream into the shared UI chunk layer.
///
/// This keeps message lifecycle metadata and data-part delivery above
/// [TextStreamEvent] while remaining transport-neutral.
Stream<ChatUiStreamChunk> projectTextStreamEventStream(
  Stream<TextStreamEvent> eventStream, {
  String? messageId,
  Map<String, Object?> messageMetadata = const {},
  Iterable<DataUiPart<Object?>> leadingDataParts = const [],
  Map<String, Object?> finalMessageMetadata = const {},
}) async* {
  if (messageId != null || messageMetadata.isNotEmpty) {
    yield ChatUiMessageStartChunk(
      messageId: messageId,
      metadata: messageMetadata,
    );
  }

  for (final part in leadingDataParts) {
    yield ChatUiDataPartChunk<Object?>(part);
  }

  await for (final event in eventStream) {
    yield ChatUiEventChunk(event);
  }

  if (finalMessageMetadata.isNotEmpty) {
    yield ChatUiMessageFinishChunk(
      metadata: finalMessageMetadata,
    );
  }
}
