/// Legacy DeepSeek HTTP utilities.
///
/// These re-export the legacy DeepSeek-specific HTTP strategy and
/// error handler under `lib/legacy/providers/deepseek`. New code
/// should use the `llm_dart_deepseek` package instead.
library;

export 'deepseek/dio_strategy.dart';
export 'deepseek/error_handler.dart';
