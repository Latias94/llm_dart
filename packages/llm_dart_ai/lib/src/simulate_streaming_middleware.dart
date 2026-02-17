import 'middleware.dart';

/// Enables best-effort streaming simulation for non-streaming models.
///
/// This is inspired by Vercel AI SDK's `simulateStreamingMiddleware`.
///
/// When this middleware is present in [wrapLanguageModelWithMiddleware], stream
/// calls will fall back to a non-streaming chat call and emit a simulated
/// `LLMStreamPart` sequence (stream-start, response-metadata, text/reasoning,
/// tool inputs, finish).
class SimulateStreamingMiddleware extends LanguageModelMiddleware {
  const SimulateStreamingMiddleware();
}
