/// Backwards-compatible alias for the DeepSeek Dio strategy.
///
/// The actual implementation now lives in the `llm_dart_deepseek`
/// subpackage. This file is kept so that existing imports from
/// `providers/deepseek/dio_strategy.dart` continue to work.
library;

export 'package:llm_dart_deepseek/llm_dart_deepseek.dart'
    show DeepSeekDioStrategy;
