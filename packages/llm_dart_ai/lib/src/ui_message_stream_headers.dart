/// Default HTTP response headers for Vercel AI SDK-style UI message streams.
///
/// Upstream reference:
/// `repo-ref/ai/packages/ai/src/ui-message-stream/ui-message-stream-headers.ts`
///
/// Notes:
/// - Header names are lowercase for deterministic access.
/// - This is intended for app/framework integrations (e.g. Shelf/Dart Frog),
///   not for provider HTTP calls.
const Map<String, String> uiMessageStreamHeadersV1 = <String, String>{
  'content-type': 'text/event-stream',
  'cache-control': 'no-cache',
  'connection': 'keep-alive',
  'x-vercel-ai-ui-message-stream': 'v1',
  'x-accel-buffering': 'no', // disable nginx buffering
};
