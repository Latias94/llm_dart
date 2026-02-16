import 'dart:convert';

/// Encodes a text stream into UTF-8 bytes, one chunk at a time.
///
/// This mirrors the Vercel AI SDK behavior of piping a `ReadableStream<string>`
/// through a `TextEncoderStream()` for HTTP responses.
Stream<List<int>> utf8BytesFromTextStream(Stream<String> textStream) async* {
  await for (final chunk in textStream) {
    yield utf8.encode(chunk);
  }
}
