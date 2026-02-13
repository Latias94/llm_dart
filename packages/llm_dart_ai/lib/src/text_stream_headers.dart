/// Default headers for AI SDK-style text streams.
///
/// Mirrors Vercel AI SDK `createTextStreamResponse` which sets:
/// - `Content-Type: text/plain; charset=utf-8`
library;

const Map<String, String> textStreamHeadersV1 = <String, String>{
  'content-type': 'text/plain; charset=utf-8',
};

