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
}

