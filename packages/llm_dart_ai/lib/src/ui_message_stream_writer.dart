/// A writer for Vercel AI SDK-style UI message stream chunks.
///
/// Upstream reference:
/// `repo-ref/ai/packages/ai/src/ui-message-stream/ui-message-stream-writer.ts`
library;

/// Writes UI message chunks to a stream.
abstract class UIMessageStreamWriter {
  /// Appends a UI message chunk to the stream.
  void write(Map<String, Object?> chunk);

  /// Merges another UI message chunk stream into the output stream.
  void merge(Stream<Map<String, Object?>> stream);

  /// Error-to-text mapper used by the writer when converting stream errors into
  /// `{ "type": "error", "errorText": ... }` chunks.
  ///
  /// This is intended for forwarding when composing/merging nested UI message
  /// streams, to keep error masking consistent and avoid duplicated conversions.
  String Function(Object error)? get onError => null;
}
