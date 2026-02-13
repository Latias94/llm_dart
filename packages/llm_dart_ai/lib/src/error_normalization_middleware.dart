import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';

import 'middleware.dart';

/// Normalizes unexpected exceptions into [LLMError]s.
///
/// This is useful when a provider implementation throws non-LLM errors
/// (e.g. `StateError`, `FormatException`). It keeps downstream middlewares like
/// [RetryMiddleware] and [TelemetryMiddleware] working with consistent error
/// types.
///
/// Behavior:
/// - Non-streaming: rethrows [LLMError] as-is; wraps unknown errors as
///   [GenericError].
/// - Streaming: converts thrown errors into a terminal [LLMErrorPart] and
///   closes the stream.
class ErrorNormalizationMiddleware extends LanguageModelMiddleware {
  const ErrorNormalizationMiddleware();

  @override
  Future<ChatResponse> chat(
    ChatMiddlewareContext context,
    ChatMiddlewareNext next,
  ) async {
    try {
      return await next(context);
    } catch (e) {
      if (e is LLMError) rethrow;
      throw GenericError('Unexpected error: $e');
    }
  }

  @override
  Stream<LLMStreamPart> stream(
    ChatStreamMiddlewareContext context,
    ChatStreamMiddlewareNext next,
  ) async* {
    try {
      await for (final part in next(context)) {
        yield part;
      }
    } catch (e) {
      if (e is LLMError) {
        yield LLMErrorPart(e);
        return;
      }
      yield LLMErrorPart(GenericError('Unexpected error: $e'));
    }
  }
}
